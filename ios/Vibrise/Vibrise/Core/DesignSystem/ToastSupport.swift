import SwiftUI

struct VibriseTopToastOverlay: View {
    let message: String

    var body: some View {
        VStack {
            GlassToastView(message: message)
            Spacer()
        }
        .padding(.horizontal, DesignTokens.Spacing.pageHorizontal)
    }
}

enum TransientToastScheduler {
    @MainActor
    static func reschedule(
        existingTask: Task<Void, Never>?,
        message: String?,
        isBlocked: Bool,
        onClear: @escaping @MainActor () -> Void
    ) -> Task<Void, Never>? {
        existingTask?.cancel()

        guard message != nil, !isBlocked else {
            return nil
        }

        return Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(DesignTokens.Motion.toastDurationMs))
            onClear()
        }
    }
}
