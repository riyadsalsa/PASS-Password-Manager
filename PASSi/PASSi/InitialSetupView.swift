import SwiftUI

struct InitialSetupView: View {
    @ObservedObject var lockManager: AppLockManager
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var errorMessage = ""
    @FocusState private var isPasswordFieldFocused: Bool
    
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
                    .frame(width: 120, height: 120)
                    .foregroundColor(.blue)
                    .shadow(radius: 10)
                
                Text("Welcome to PASSi")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundColor(.primary)
                
                Text("Create a master password")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 20)
                
                // Password fields
                VStack(spacing: 15) {
                    SecureField("Master Password", text: $newPassword)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(.title3)
                        .frame(width: 250)
                        .focused($isPasswordFieldFocused)
                    
                    SecureField("Confirm Password", text: $confirmPassword)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(.title3)
                        .frame(width: 250)
                        .submitLabel(.go)
                        .onSubmit {
                            setupPassword()
                        }
                    
                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                    
                    Button(action: setupPassword) {
                        Text("Set Password")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(width: 200, height: 50)
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                    .disabled(newPassword.isEmpty || confirmPassword.isEmpty)
                }
                
                Spacer()
                
                Text("This password will be required to open PASSi")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .padding(.bottom, 20)
            }
            .padding()
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isPasswordFieldFocused = true
            }
        }
    }
    
    private func setupPassword() {
        // Check if passwords match
        guard newPassword == confirmPassword else {
            errorMessage = "Passwords don't match"
            return
        }
        
        // Check if password is not empty
        guard !newPassword.isEmpty else {
            errorMessage = "Password cannot be empty"
            return
        }
        
        // Save the password and unlock
        lockManager.setMasterPassword(newPassword)
        lockManager.unlock(with: newPassword)
    }
}

#Preview {
    InitialSetupView(lockManager: AppLockManager())
}
