//AppLockManager.swift
import SwiftUI
import Combine

class AppLockManager: ObservableObject {
    @Published var isUnlocked = false
    @Published var showLockScreen = true
    @Published var showSetup = false
    @Published var errorMessage = ""
    @Published var passwordAttempt = ""
    @Published var codeAttempt = ""
    
    private var masterPassword = ""
    
    var hasPassword: Bool {
        return !masterPassword.isEmpty
    }
    
    init() {
        loadPassword()
        if !hasPassword {
            showSetup = true
            showLockScreen = false
        }
    }
    
    func setMasterPassword(_ password: String) {
        masterPassword = password
        UserDefaults.standard.set(password, forKey: "masterPassword")
        showSetup = false
        showLockScreen = true
    }
    
    func loadPassword() {
        masterPassword = UserDefaults.standard.string(forKey: "masterPassword") ?? ""
    }
    
    func unlock(with password: String, code: String = "", storage: PasswordStorage? = nil) {
        print("🔵 unlock() called")
        print("   - password entered: \(password)")
        print("   - masterPassword: \(masterPassword)")
        print("   - passwords match: \(password == masterPassword)")
        
        guard password == masterPassword else {
            print("❌ Password incorrect")
            errorMessage = "Incorrect password"
            passwordAttempt = ""
            return
        }
        
        print("✅ Password correct")
        
        isUnlocked = true
        showLockScreen = false
        errorMessage = ""
        passwordAttempt = ""
        codeAttempt = ""
        
        print("✅ isUnlocked set to: \(isUnlocked)")
        print("✅ showLockScreen set to: \(showLockScreen)")
    }
    
    func lock() {
        isUnlocked = false
        showLockScreen = true
        passwordAttempt = ""
        codeAttempt = ""
        errorMessage = ""
    }
}
