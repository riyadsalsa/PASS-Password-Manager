
import SwiftUI

@main
struct PASSiApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject var lockManager = AppLockManager()
    @StateObject private var storage = PasswordStorage()
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if lockManager.showSetup {
                    InitialSetupView(lockManager: lockManager)
                } else if lockManager.isUnlocked {
                    MainTabView()
                        .environmentObject(lockManager)
                        .environmentObject(storage)
                } else {
                    LockScreenView(lockManager: lockManager)
                        .environmentObject(storage)
                }
            }
            .tint(.blue)
        }
    }
}
