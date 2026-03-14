//HelpView.swift
import SwiftUI

struct HelpView: View {
    var body: some View {
        List {
            Section("About PASSi") {
                Text("PASSi is a personal password manager that stores all data locally on your iPhone. No cloud sync, no servers - just your passwords on your device.")
                    .padding(.vertical, 4)
            }
            
            Section("Color Coding") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Passwords are color-coded for easy analysis:")
                        .font(.headline)
                    
                    HStack {
                        Circle().fill(.purple).frame(width: 12, height: 12)
                        Text("Uppercase letters").foregroundColor(.primary)
                    }
                    HStack {
                        Circle().fill(.primary).frame(width: 12, height: 12)
                        Text("Lowercase letters").foregroundColor(.primary)
                    }
                    HStack {
                        Circle().fill(.blue).frame(width: 12, height: 12)
                        Text("Numbers").foregroundColor(.primary)
                    }
                    HStack {
                        Circle().fill(.red).frame(width: 12, height: 12)
                        Text("Symbols & special characters").foregroundColor(.primary)
                    }
                    
                    Text("The statistics badges show you exactly how many of each character type your password contains.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }
                .padding(.vertical, 4)
            }
            
            Section("Using the App") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("• **Add Password**: Tap + in Passwords tab")
                    Text("• **Edit**: Tap any entry, then tap Edit")
                    Text("• **Delete**: Swipe left on any entry")
                    Text("• **Search**: Pull down on list to show search")
                    Text("• **Copy**: Tap the 📋 button or long-press any text")
                    Text("• **Show/Hide Password**: Use the 👁️ button")
                }
                .padding(.vertical, 4)
            }
            
            Section("Importing Data") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("To import your passwords:")
                        .font(.headline)
                    
                    Text("1. Export a CSV file from your Mac app")
                    Text("2. Transfer it to your iPhone (AirDrop, Files, etc.)")
                    Text("3. Go to the Import tab and select the file")
                    Text("4. The CSV format should be:")
                        .padding(.top, 4)
                    
                    Text("Name,Username,Password,URL,Notes")
                        .font(.system(.body, design: .monospaced))
                        .padding(.leading)
                    
                    Text("Notes can span multiple lines if wrapped in quotes!")
                        .font(.caption)
                        .foregroundColor(.blue)
                        .padding(.top, 2)
                }
                .padding(.vertical, 4)
            }
            
            Section("Security") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("• All data is stored locally on your device")
                    Text("• Files are encrypted with iOS data protection")
                    Text("• No network access required")
                    Text("• No accounts or subscriptions")
                    Text("• Color coding is visual only - your actual password is never transmitted")
                }
                .padding(.vertical, 4)
            }
            
            Section("Data Location") {
                Text("Your passwords are stored in the app's Documents folder. If you delete the app, all data is lost - always keep a backup CSV!")
                    .padding(.vertical, 4)
            }
            
            Section("Version") {
                HStack {
                    Text("PASSi")
                    Spacer()
                    Text("1.1")
                        .foregroundColor(.secondary)
                }
                HStack {
                    Text("Features")
                    Spacer()
                    Text("Colored Passwords")
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

#Preview {
    HelpView()
}
