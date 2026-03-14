//InitialSetupView.swift
import SwiftUI

struct InitialSetupView: View {
    @ObservedObject var lockManager: AppLockManager
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var errorMessage = ""
    @FocusState private var isPasswordFieldFocused: Bool
    @FocusState private var isConfirmFieldFocused: Bool
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 25) {
                Spacer()
                
                // Logo
                Image(systemName: "lock.shield.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 100)
                    .foregroundColor(.blue)
                    .shadow(radius: 10)
                
                Text("Welcome to PASSi+")
                    .font(.system(size: 28, weight: .bold))
                
                Text("Create a master password")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                // Password fields
                VStack(alignment: .leading, spacing: 8) {
                    Text("New Password")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    SecureField("Enter password", text: $newPassword)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(.title3)
                        .focused($isPasswordFieldFocused)
                        .textContentType(.newPassword)
                        .onChange(of: newPassword) { oldValue, newValue in
                            if !errorMessage.isEmpty {
                                errorMessage = ""
                            }
                            print("Password field changed, length: \(newValue.count)")
                        }
                    
                    Text("Confirm Password")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 8)
                    
                    SecureField("Re-enter password", text: $confirmPassword)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(.title3)
                        .focused($isConfirmFieldFocused)
                        .textContentType(.newPassword)
                        .onChange(of: confirmPassword) { oldValue, newValue in
                            if !errorMessage.isEmpty {
                                errorMessage = ""
                            }
                            print("Confirm field changed, length: \(newValue.count)")
                        }
                        .submitLabel(.go)
                        .onSubmit {
                            print("Return key pressed")
                            setupPassword()
                        }
                    
                    // Live password match indicator
                    if !newPassword.isEmpty && !confirmPassword.isEmpty {
                        HStack {
                            Image(systemName: newPassword == confirmPassword ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundColor(newPassword == confirmPassword ? .green : .red)
                            Text(newPassword == confirmPassword ? "Passwords match" : "Passwords don't match")
                                .font(.caption)
                                .foregroundColor(newPassword == confirmPassword ? .green : .red)
                        }
                        .padding(.top, 4)
                    }
                    
                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding(.top, 4)
                    }
                }
                .padding(.horizontal, 40)
                
                // Set Password Button
                Button(action: {
                    print("🔵 Set Password button tapped!")
                    setupPassword()
                }) {
                    Text("Set Password")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(canSetPassword ? Color.blue : Color.gray)
                        .cornerRadius(10)
                }
                .disabled(!canSetPassword)
                .padding(.horizontal, 40)
                .padding(.top, 10)
                
                Spacer()
                
                Text("This password will be required to open PASSi+")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .padding(.bottom, 20)
            }
        }
        .onAppear {
            print("📱 InitialSetupView appeared")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isPasswordFieldFocused = true
            }
        }
    }
    
    var canSetPassword: Bool {
        let result = !newPassword.isEmpty && !confirmPassword.isEmpty && newPassword == confirmPassword
        print("canSetPassword: \(result) (new: \(newPassword.count), confirm: \(confirmPassword.count), match: \(newPassword == confirmPassword))")
        return result
    }
    
    private func setupPassword() {
        print("🔧 setupPassword() called")
        print("   newPassword: '\(newPassword)' (length: \(newPassword.count))")
        print("   confirmPassword: '\(confirmPassword)' (length: \(confirmPassword.count))")
        print("   passwords match: \(newPassword == confirmPassword)")
        
        // Check if passwords match
        guard newPassword == confirmPassword else {
            errorMessage = "Passwords don't match"
            print("❌ Error: Passwords don't match")
            return
        }
        
        // Check if password is not empty
        guard !newPassword.isEmpty else {
            errorMessage = "Password cannot be empty"
            print("❌ Error: Password empty")
            return
        }
        
        // Check minimum length
        guard newPassword.count >= 4 else {
            errorMessage = "Password must be at least 4 characters"
            print("❌ Error: Password too short")
            return
        }
        
        // Save the password
        print("✅ All validations passed, saving password...")
        lockManager.setMasterPassword(newPassword)
        print("✅ setMasterPassword called")
        
        // Clear fields
        newPassword = ""
        confirmPassword = ""
        errorMessage = ""
        print("✅ Setup complete")
    }
}

#Preview {
    InitialSetupView(lockManager: AppLockManager())
}
