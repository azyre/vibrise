import SwiftUI

@main
struct VibriseApp: App {
    @UIApplicationDelegateAdaptor(AlarmAppDelegate.self) private var appDelegate

    init() {
        #if DEBUG
        let families = ["Maven Pro", "Satoshi Variable"]
        for family in families {
            let names = UIFont.fontNames(forFamilyName: family)
            if names.isEmpty {
                print("[Vibrise] \(family) NOT found")
            } else {
                print("[Vibrise] \(family) registered: \(names)")
            }
        }
        #endif
    }

    var body: some Scene {
        WindowGroup {
            HomeView()
        }
    }
}
