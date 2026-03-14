import SwiftUI

struct LockScreenView: View {
    @ObservedObject var lockManager: AppLockManager
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
                
                Text("PASSi")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(.primary)
                
                Text("Enter Master Password")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 20)
                
                // Password field
                VStack(spacing: 15) {
                    SecureField("Password", text: $lockManager.passwordAttempt)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(.title3)
                        .frame(width: 250)
                        .focused($isPasswordFieldFocused)
                        .submitLabel(.go)
                        .onSubmit {
                            lockManager.unlock(with: lockManager.passwordAttempt)
                        }
                    
                    if !lockManager.errorMessage.isEmpty {
                        Text(lockManager.errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                    
                    Button(action: {
                        lockManager.unlock(with: lockManager.passwordAttempt)
                    }) {
                        Text("Unlock")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(width: 200, height: 50)
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                }
                
                Spacer()
                
                // Hint text
                Text("Your passwords are encrypted")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 20)
            }
            .padding()
        }
        .onAppear {
            // Auto-focus the password field
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isPasswordFieldFocused = true
            }
        }
    }
}

#Preview {
    LockScreenView(lockManager: AppLockManager())
}
