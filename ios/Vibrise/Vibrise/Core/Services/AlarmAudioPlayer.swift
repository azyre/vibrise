import Foundation
import AVFoundation

enum AlarmAudioPlaybackEvent: Equatable {
    case started
    case resumed
    case paused
    case stopped
    case failed(String)
}

protocol AlarmAudioPlaying: AnyObject {
    var onPlaybackEvent: ((AlarmAudioPlaybackEvent) -> Void)? { get set }
    func startPlayback(for song: Song) throws
    func stopPlayback()
}

@MainActor
final class AlarmAudioPlayer: AlarmAudioPlaying {
    var onPlaybackEvent: ((AlarmAudioPlaybackEvent) -> Void)?

    private var player: AVPlayer?
    private var engine: AVAudioEngine?
    private var playerNode: AVAudioPlayerNode?
    private var loopObserver: NSObjectProtocol?
    private var interruptionObserver: NSObjectProtocol?
    private var routeChangeObserver: NSObjectProtocol?
    private var currentSong: Song?
    private var shouldResumeAfterInterruption = false

    func startPlayback(for song: Song) throws {
        try configureAudioSession()
        cleanupCurrentPlayback()
        registerAudioSessionObserversIfNeeded()
        currentSong = song

        if let audioURL = song.audioURL {
            try startRemotePlayback(audioURL: audioURL)
        } else {
            try startGeneratedTonePlayback()
        }

        onPlaybackEvent?(.started)
    }

    func stopPlayback() {
        currentSong = nil
        shouldResumeAfterInterruption = false
        player?.pause()
        playerNode?.stop()
        engine?.stop()
        cleanupCurrentPlayback()
        #if os(iOS)
        try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
        #endif
        onPlaybackEvent?(.stopped)
    }

    private func startRemotePlayback(audioURL: URL) throws {
        let item = AVPlayerItem(url: audioURL)
        loopObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.player?.seek(to: .zero)
                self?.player?.play()
            }
        }

        let player = AVPlayer(playerItem: item)
        player.actionAtItemEnd = .none
        player.play()
        self.player = player
    }

    private func startGeneratedTonePlayback() throws {
        let engine = AVAudioEngine()
        let playerNode = AVAudioPlayerNode()
        let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)

        guard let format else {
            throw AlarmAudioPlayerError.couldNotCreateTone
        }

        engine.attach(playerNode)
        engine.connect(playerNode, to: engine.mainMixerNode, format: format)

        let buffer = try makeAlarmToneBuffer(format: format)
        playerNode.scheduleBuffer(buffer, at: nil, options: .loops)

        try engine.start()
        playerNode.play()

        self.engine = engine
        self.playerNode = playerNode
    }

    private func configureAudioSession() throws {
        #if os(iOS)
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.playback, mode: .default)
        try audioSession.setActive(true)
        #endif
    }

    private func registerAudioSessionObserversIfNeeded() {
        #if os(iOS)
        if interruptionObserver == nil {
            interruptionObserver = NotificationCenter.default.addObserver(
                forName: AVAudioSession.interruptionNotification,
                object: AVAudioSession.sharedInstance(),
                queue: .main
            ) { [weak self] notification in
                let userInfo = notification.userInfo
                let typeValue = userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt
                let optionsValue = userInfo?[AVAudioSessionInterruptionOptionKey] as? UInt ?? 0
                Task { @MainActor [weak self] in
                    self?.handleAudioInterruption(typeValue: typeValue, optionsValue: optionsValue)
                }
            }
        }

        if routeChangeObserver == nil {
            routeChangeObserver = NotificationCenter.default.addObserver(
                forName: AVAudioSession.routeChangeNotification,
                object: AVAudioSession.sharedInstance(),
                queue: .main
            ) { [weak self] notification in
                let userInfo = notification.userInfo
                let reasonValue = userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt
                Task { @MainActor [weak self] in
                    self?.handleRouteChange(reasonValue: reasonValue)
                }
            }
        }
        #endif
    }

    private func handleAudioInterruption(typeValue: UInt?, optionsValue: UInt) {
        #if os(iOS)
        guard let typeValue,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }

        switch type {
        case .began:
            shouldResumeAfterInterruption = currentSong != nil
            pauseActivePlayback()
            onPlaybackEvent?(.paused)
        case .ended:
            guard shouldResumeAfterInterruption else { return }
            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
            if options.contains(.shouldResume) {
                resumePlaybackAfterSystemEvent()
            }
        @unknown default:
            break
        }
        #endif
    }

    private func handleRouteChange(reasonValue: UInt?) {
        #if os(iOS)
        guard let reasonValue,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else {
            return
        }

        if reason == .oldDeviceUnavailable, currentSong != nil {
            resumePlaybackAfterSystemEvent()
        }
        #endif
    }

    private func pauseActivePlayback() {
        player?.pause()
        playerNode?.pause()
        engine?.pause()
    }

    private func resumePlaybackAfterSystemEvent() {
        guard let currentSong else { return }

        do {
            try startPlayback(for: currentSong)
            onPlaybackEvent?(.resumed)
            shouldResumeAfterInterruption = false
        } catch {
            onPlaybackEvent?(.failed(error.localizedDescription))
        }
    }

    private func makeAlarmToneBuffer(format: AVAudioFormat) throws -> AVAudioPCMBuffer {
        let sampleRate = format.sampleRate
        let duration: Double = 1.6
        let frameCount = AVAudioFrameCount(sampleRate * duration)

        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount),
              let channelData = buffer.floatChannelData?[0] else {
            throw AlarmAudioPlayerError.couldNotCreateTone
        }

        buffer.frameLength = frameCount

        let attackFrames = Int(sampleRate * 0.03)
        let sustainFrames = Int(sampleRate * 0.22)
        let decayFrames = Int(sampleRate * 0.10)
        let secondBeepOffset = Int(sampleRate * 0.42)
        let frequency = 880.0
        let amplitude: Float = 0.22

        for frame in 0 ..< Int(frameCount) {
            let envelope = envelopeValue(
                frame: frame,
                attackFrames: attackFrames,
                sustainFrames: sustainFrames,
                decayFrames: decayFrames,
                secondBeepOffset: secondBeepOffset
            )

            if envelope == 0 {
                channelData[frame] = 0
                continue
            }

            let phase = 2 * Double.pi * frequency * Double(frame) / sampleRate
            channelData[frame] = sin(Float(phase)) * amplitude * envelope
        }

        return buffer
    }

    private func envelopeValue(
        frame: Int,
        attackFrames: Int,
        sustainFrames: Int,
        decayFrames: Int,
        secondBeepOffset: Int
    ) -> Float {
        let beepLength = attackFrames + sustainFrames + decayFrames

        if let envelope = singleBeepEnvelope(
            frame: frame,
            attackFrames: attackFrames,
            sustainFrames: sustainFrames,
            decayFrames: decayFrames,
            beepLength: beepLength
        ) {
            return envelope
        }

        let shiftedFrame = frame - secondBeepOffset
        if let envelope = singleBeepEnvelope(
            frame: shiftedFrame,
            attackFrames: attackFrames,
            sustainFrames: sustainFrames,
            decayFrames: decayFrames,
            beepLength: beepLength
        ) {
            return envelope * 0.9
        }

        return 0
    }

    private func singleBeepEnvelope(
        frame: Int,
        attackFrames: Int,
        sustainFrames: Int,
        decayFrames: Int,
        beepLength: Int
    ) -> Float? {
        guard frame >= 0, frame < beepLength else {
            return nil
        }

        if frame < attackFrames {
            return Float(frame) / Float(max(attackFrames, 1))
        }

        if frame < attackFrames + sustainFrames {
            return 1
        }

        let decayFrame = frame - attackFrames - sustainFrames
        return 1 - Float(decayFrame) / Float(max(decayFrames, 1))
    }

    private func cleanupCurrentPlayback() {
        if let loopObserver {
            NotificationCenter.default.removeObserver(loopObserver)
            self.loopObserver = nil
        }
        player?.pause()
        player?.replaceCurrentItem(with: nil)
        player = nil
        playerNode?.stop()
        playerNode = nil
        engine?.stop()
        engine = nil
    }

    deinit {
        if let interruptionObserver {
            NotificationCenter.default.removeObserver(interruptionObserver)
        }
        if let routeChangeObserver {
            NotificationCenter.default.removeObserver(routeChangeObserver)
        }
        if let loopObserver {
            NotificationCenter.default.removeObserver(loopObserver)
        }
    }
}

enum AlarmAudioPlayerError: LocalizedError {
    case couldNotCreateTone

    var errorDescription: String? {
        switch self {
        case .couldNotCreateTone:
            return "Couldn't prepare alarm audio"
        }
    }
}
