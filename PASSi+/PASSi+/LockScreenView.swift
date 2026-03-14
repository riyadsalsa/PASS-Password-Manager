//LockScreenView.swift
import SwiftUI
import Combine

struct LockScreenView: View {
    @ObservedObject var lockManager: AppLockManager
    @EnvironmentObject var storage: PasswordStorage
    @State private var currentCode = "------"
    @State private var showCode = false
    @FocusState private var isPasswordFieldFocused: Bool
    @State private var showingRecovery = false
    
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
                    .frame(width: 80, height: 80)
                    .foregroundColor(.blue)
                    .shadow(radius: 8)
                
                Text("PASSi+")
                    .font(.title)
                    .fontWeight(.bold)
                
                if storage.is2FAEnabled && !storage.twoFASecret.isEmpty {
                    // 2FA is enabled - show code only when toggled
                    VStack(spacing: 8) {
                        HStack {
                            Text("2FA Status")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Button(action: { showCode.toggle() }) {
                                HStack(spacing: 4) {
                                    Text(showCode ? "Hide" : "Show")
                                        .font(.caption)
                                    Image(systemName: showCode ? "eye.slash" : "eye")
                                        .font(.caption)
                                }
                                .foregroundColor(.blue)
                            }
                        }
                        .padding(.horizontal, 40)
                        
                        if showCode {
                            Text(currentCode)
                                .font(.system(size: 24, weight: .medium, design: .monospaced))
                                .foregroundColor(.blue)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(8)
                                .transition(.opacity)
                        } else {
                            Text("••••••")
                                .font(.system(size: 24, weight: .medium, design: .monospaced))
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.secondary.opacity(0.1))
                                .cornerRadius(8)
                                .transition(.opacity)
                        }
                    }
                    .animation(.easeInOut(duration: 0.2), value: showCode)
                }
                
                VStack(spacing: 15) {
                    SecureField("Master Password", text: $lockManager.passwordAttempt)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .focused($isPasswordFieldFocused)
                        .padding(.horizontal)
                        .frame(maxWidth: 300)
                    
                    if !lockManager.errorMessage.isEmpty {
                        Text(lockManager.errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                    
                    Button(action: unlock) {
                        Text("Unlock")
                            .frame(width: 200, height: 44)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .disabled(lockManager.passwordAttempt.isEmpty)
                    
                    if storage.is2FAEnabled {
                        Button("Use Recovery Code") {
                            showingRecovery = true
                        }
                        .font(.caption)
                        .foregroundColor(.orange)
                        .padding(.top, 5)
                    }
                }
                .padding()
                
                Spacer()
                
                Text("Your data is encrypted")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 20)
            }
            .padding()
        }
        .onAppear {
            print("🟢 Lock screen appeared")
            isPasswordFieldFocused = true
            if storage.is2FAEnabled && !storage.twoFASecret.isEmpty {
                currentCode = storage.getCurrentSessionCode()
            }
        }
        .sheet(isPresented: $showingRecovery) {
            RecoveryCodeView(storage: storage, lockManager: lockManager)
        }
    }
    
    private func unlock() {
        lockManager.unlock(
            with: lockManager.passwordAttempt,
            code: currentCode,
            storage: storage
        )
    }
}

// MARK: - Recovery Code View
struct RecoveryCodeView: View {
    @ObservedObject var storage: PasswordStorage
    @ObservedObject var lockManager: AppLockManager
    @State private var recoveryCode = ""
    @State private var errorMessage = ""
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Enter a recovery code")
                    .font(.headline)
                
                Text("These were given to you when you enabled 2FA. Each code works only once.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                TextField("Recovery Code", text: $recoveryCode)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.asciiCapable)
                    .autocapitalization(.none)
                    .padding(.horizontal)
                    .frame(maxWidth: 250)
                
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }
                
                Button("Use Recovery Code") {
                    useRecoveryCode()
                }
                .frame(width: 200, height: 44)
                .background(Color.orange)
                .foregroundColor(.white)
                .cornerRadius(8)
                .disabled(recoveryCode.isEmpty)
                
                Spacer()
            }
            .padding(.top, 50)
            .navigationTitle("Recovery")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func useRecoveryCode() {
        if storage.useRecoveryCode(recoveryCode) {
            let newSecret = TOTPHelper.generateMasterSecret()
            storage.save2FASettings(secret: newSecret, enabled: true)
            let newCodes = TOTPHelper.generateRecoveryCodes()
            storage.saveRecoveryCodes(newCodes)
            dismiss()
        } else {
            errorMessage = "Invalid recovery code"
        }
    }
}
