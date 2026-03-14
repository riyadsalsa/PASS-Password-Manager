import SwiftUI

struct EntryDetailView: View {
    let entry: PasswordEntry
    let storage: PasswordStorage
    @State private var showPassword = false
    @State private var showCopyAlert = false
    @State private var copiedField = ""
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        List {
            // MARK: - Name Section
            Section("Name") {
                HStack {
                    Text(entry.name)
                        .textSelection(.enabled)
                    Spacer()
                    Button(action: { copyToClipboard(entry.name, field: "Name") }) {
                        Image(systemName: "doc.on.doc")
                    }
                    .buttonStyle(.borderless)
                }
            }
            
            // MARK: - Username Section
            Section("Username") {
                HStack {
                    Text(entry.username)
                        .textSelection(.enabled)
                    Spacer()
                    Button(action: { copyToClipboard(entry.username, field: "Username") }) {
                        Image(systemName: "doc.on.doc")
                    }
                    .buttonStyle(.borderless)
                }
            }
            
            // MARK: - Password Section (with colors!)
            Section("Password") {
                VStack(alignment: .leading, spacing: 12) {
                    // Password stats
                    PasswordStatsView(password: entry.password)
                    
                    // Colored password display
                    ColoredPasswordText(password: entry.password, showPassword: $showPassword)
                    
                    // Copy button
                    HStack {
                        Spacer()
                        Button(action: { copyToClipboard(entry.password, field: "Password") }) {
                            Label("Copy Password", systemImage: "doc.on.doc")
                        }
                        .buttonStyle(.borderless)
                    }
                }
                .padding(.vertical, 4)
            }
            
            // MARK: - URL Section
            if !entry.url.isEmpty {
                Section("URL") {
                    HStack {
                        Text(entry.url)
                            .textSelection(.enabled)
                            .foregroundColor(.blue)
                            .underline()
                        Spacer()
                        Button(action: { copyToClipboard(entry.url, field: "URL") }) {
                            Image(systemName: "doc.on.doc")
                        }
                        .buttonStyle(.borderless)
                    }
                }
            }
            
            // MARK: - Notes Section
            if !entry.notes.isEmpty {
                Section("Notes") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(entry.notes)
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        HStack {
                            Spacer()
                            Button(action: { copyToClipboard(entry.notes, field: "Notes") }) {
                                Label("Copy Notes", systemImage: "doc.on.doc")
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            
            // MARK: - Metadata Section
            Section {
                LabeledContent("Created", value: entry.createdDate.formatted(date: .abbreviated, time: .shortened))
                LabeledContent("Modified", value: entry.modifiedDate.formatted(date: .abbreviated, time: .shortened))
                if let lastUsed = entry.lastUsedDate {
                    LabeledContent("Last Used", value: lastUsed.formatted(date: .abbreviated, time: .shortened))
                }
            }
        }
        .navigationTitle(entry.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink(destination: ChangePasswordView(storage: storage, editingEntry: entry)) {
                    Text("Edit")
                }
            }
        }
        .alert("Copied!", isPresented: $showCopyAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("\(copiedField) copied to clipboard")
        }
    }
    
    private func copyToClipboard(_ text: String, field: String) {
        UIPasteboard.general.string = text
        copiedField = field
        showCopyAlert = true
        
        // Update last used date
        var updatedEntry = entry
        updatedEntry.updateLastUsedDate()
        storage.updateEntry(updatedEntry)
    }
}

// MARK: - Colored Password View
struct ColoredPasswordText: View {
    let password: String
    @Binding var showPassword: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if showPassword {
                // Colored password display
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 0) {
                        ForEach(Array(password.enumerated()), id: \.offset) { index, character in
                            Text(String(character))
                                .foregroundColor(colorForCharacter(character))
                                .font(.custom("Menlo", size: 18))
                        }
                    }
                }
                .frame(minHeight: 30)
            } else {
                // Hidden password
                Text(String(repeating: "•", count: min(password.count, 30)))
                    .font(.custom("Menlo", size: 18))
                    .foregroundColor(.gray)
            }
            
            // Show/Hide toggle
            HStack {
                Spacer()
                Button(action: { showPassword.toggle() }) {
                    Label(showPassword ? "Hide" : "Show",
                          systemImage: showPassword ? "eye.slash" : "eye")
                        .font(.caption)
                }
                .buttonStyle(.borderless)
            }
        }
    }
    
    func colorForCharacter(_ char: Character) -> Color {
        if char.isUppercase {
            return .purple
        } else if char.isLowercase {
            return .primary // Black in light mode, white in dark mode
        } else if char.isNumber {
            return .blue
        } else {
            return .red // Symbols and special characters
        }
    }
}

// MARK: - Password Statistics
struct PasswordStatsView: View {
    let password: String
    
    var uppercaseCount: Int { password.filter { $0.isUppercase }.count }
    var lowercaseCount: Int { password.filter { $0.isLowercase }.count }
    var numberCount: Int { password.filter { $0.isNumber }.count }
    var symbolCount: Int { password.filter { !$0.isLetter && !$0.isNumber }.count }
    
    var body: some View {
        HStack(spacing: 16) {
            StatBadge(count: uppercaseCount, color: .purple, icon: "A", label: "Uppercase")
            StatBadge(count: lowercaseCount, color: .primary, icon: "a", label: "Lowercase")
            StatBadge(count: numberCount, color: .blue, icon: "#", label: "Numbers")
            StatBadge(count: symbolCount, color: .red, icon: "!@", label: "Symbols")
        }
        .padding(.vertical, 4)
    }
}

struct StatBadge: View {
    let count: Int
    let color: Color
    let icon: String
    let label: String
    
    var body: some View {
        VStack(spacing: 2) {
            Text(icon)
                .font(.caption)
                .foregroundColor(color)
                .fontWeight(.bold)
            
            Text("\(count)")
                .font(.caption2)
                .foregroundColor(.secondary)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(minWidth: 40)
        .padding(.horizontal, 4)
        .padding(.vertical, 4)
        .background(color.opacity(0.1))
        .cornerRadius(6)
    }
}

