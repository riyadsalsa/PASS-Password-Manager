import SwiftUI
import Combine

class AppLockManager: ObservableObject {
    @Published var isUnlocked = false
    @Published var showLockScreen = true
    @Published var errorMessage = ""
    @Published var passwordAttempt = ""
    
    private var masterPassword = ""
    
    var hasPassword: Bool {
        return !masterPassword.isEmpty
    }
    
    init() {
        loadPassword()
        // If no password exists, we need to show setup
        // This is handled in PASSiApp.swift with !hasPassword check
    }
    
    func setMasterPassword(_ password: String) {
        masterPassword = password
        UserDefaults.standard.set(password, forKey: "masterPassword")
    }
    
    func loadPassword() {
        masterPassword = UserDefaults.standard.string(forKey: "masterPassword") ?? ""
    }
    
    func unlock(with password: String) {
        print("🔵 unlock() called")
        print("   - password entered: \(password)")
        print("   - masterPassword: \(masterPassword)")
        print("   - passwords match: \(password == masterPassword)")
        
        if password == masterPassword {
            print("✅ Password correct, unlocking...")
            isUnlocked = true
            showLockScreen = false
            errorMessage = ""
            passwordAttempt = ""
        } else {
            print("❌ Password incorrect")
            errorMessage = "Incorrect password"
            passwordAttempt = ""
        }
    }
    
    func lock() {
        print("🔒 Manually locking app")
        isUnlocked = false
        showLockScreen = true
        passwordAttempt = ""
        errorMessage = ""
    }
}
