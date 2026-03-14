//TwoFASetupView.swift
import SwiftUI

struct TwoFASetupView: View {
    @ObservedObject var storage: PasswordStorage
    @State private var masterSecret = ""
    @State private var recoveryCodes: [String] = []
    @State private var step = 1
    @State private var copiedToClipboard = false
    @State private var codesSaved = false
    
    var body: some View {
        List {
            if storage.is2FAEnabled {
                // 2FA IS ENABLED - Show status
                Section {
                    HStack {
                        Image(systemName: "checkmark.shield.fill")
                            .foregroundColor(.green)
                            .font(.largeTitle)
                        VStack(alignment: .leading) {
                            Text("2FA is enabled")
                                .font(.headline)
                                .foregroundColor(.green)
                            Text("Your account is protected with session-based 2FA")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section("Danger Zone") {
                    Button(role: .destructive, action: disable2FA) {
                        HStack {
                            Spacer()
                            Text("Disable Two-Factor Authentication")
                            Spacer()
                        }
                    }
                }
                
            } else {
                // 2FA IS DISABLED - Show setup steps
                
                if step == 1 {
                    // STEP 1: Generate Master Secret
                    Section("Step 1: Generate Master Secret") {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("This is your **permanent master secret**. It will be used to generate new session keys every time you open the app.")
                                .font(.callout)
                            
                            Button(action: generateMasterSecret) {
                                Text("Generate Master Secret")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                if step == 2 {
                    // STEP 2: Show Master Secret
                    Section("Step 2: Your Master Secret") {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(masterSecret)
                                .font(.system(.body, design: .monospaced))
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(8)
                                .textSelection(.enabled)
                            
                            Button(action: copyMasterSecret) {
                                HStack {
                                    Image(systemName: copiedToClipboard ? "checkmark" : "doc.on.doc")
                                    Text(copiedToClipboard ? "Copied!" : "Copy to Clipboard")
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(6)
                            }
                            .buttonStyle(.borderless)
                            
                            Text("⚠️ **Save this somewhere safe!** You will need it if you ever lose your phone.")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                        .padding(.vertical, 4)
                    }
                    
                    Section("Step 3: Continue") {
                        Button(action: { step = 3 }) {
                            Text("Next: Generate Recovery Codes")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                }
                
                if step == 3 {
                    // STEP 3: Show Recovery Codes
                    Section("⚠️ CRITICAL: Your Recovery Codes") {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("These 10 codes can be used **ONCE each** to recover your account if you lose your phone.")
                                .font(.callout)
                                .foregroundColor(.red)
                            
                            // Display recovery codes
                            ForEach(recoveryCodes, id: \.self) { code in
                                Text(code)
                                    .font(.system(.body, design: .monospaced))
                                    .padding(.vertical, 4)
                                    .frame(maxWidth: .infinity)
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(4)
                            }
                            
                            Text("📝 **WRITE THESE DOWN ON PAPER** and store them safely.")
                                .font(.caption)
                                .foregroundColor(.orange)
                            
                            Toggle("I have saved my recovery codes", isOn: $codesSaved)
                                .padding(.top, 8)
                        }
                        .padding(.vertical, 4)
                    }
                    
                    Section("Step 4: Enable 2FA") {
                        Button(action: enable2FA) {
                            Text("Enable Two-Factor Authentication")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(codesSaved ? Color.green : Color.gray)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        .disabled(!codesSaved)
                    }
                }
            }
        }
        .navigationTitle("Two-Factor Authentication")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func generateMasterSecret() {
        masterSecret = TOTPHelper.generateMasterSecret()
        // Generate recovery codes right away
        recoveryCodes = TOTPHelper.generateRecoveryCodes()
        step = 2
    }
    
    private func copyMasterSecret() {
        UIPasteboard.general.string = masterSecret
        copiedToClipboard = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            copiedToClipboard = false
        }
    }
    
    private func enable2FA() {
        // Generate recovery codes FIRST
        recoveryCodes = TOTPHelper.generateRecoveryCodes()
        print("🔐 Generated recovery codes: \(recoveryCodes)")
        
        // Save master secret and enable 2FA
        storage.save2FASettings(secret: masterSecret, enabled: true)
        
        // Save recovery codes
        storage.saveRecoveryCodes(recoveryCodes)
        
        // Refresh view
        storage.load2FASettings()
    }
    
    private func disable2FA() {
        storage.disable2FA()
    }
}

#Preview {
    NavigationStack {
        TwoFASetupView(storage: PasswordStorage())
    }
}
