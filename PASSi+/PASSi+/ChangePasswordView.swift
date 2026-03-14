// ChangePasswordView.swift
import SwiftUI

struct ChangePasswordView: View {
    @ObservedObject var storage: PasswordStorage
    var editingEntry: PasswordEntry?
    
    @State private var name = ""
    @State private var username = ""
    @State private var password = ""
    @State private var url = ""
    @State private var notes = ""
    @State private var showPassword = false
    @Environment(\.dismiss) private var dismiss
    
    init(storage: PasswordStorage, editingEntry: PasswordEntry? = nil) {
        self.storage = storage
        self.editingEntry = editingEntry
        
        _name = State(initialValue: editingEntry?.name ?? "")
        _username = State(initialValue: editingEntry?.username ?? "")
        _password = State(initialValue: editingEntry?.password ?? "")
        _url = State(initialValue: editingEntry?.url ?? "")
        _notes = State(initialValue: editingEntry?.notes ?? "")
    }
    
    var body: some View {
        Form {
            Section("Entry Details") {
                TextField("Name", text: $name)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                
                TextField("Username (optional)", text: $username)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.emailAddress)
                
                // Password field with visibility toggle
                HStack {
                    if showPassword {
                        TextField("Password (optional)", text: $password)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    } else {
                        SecureField("Password (optional)", text: $password)
                    }
                    
                    Button(action: { showPassword.toggle() }) {
                        Image(systemName: showPassword ? "eye.slash" : "eye")
                            .foregroundColor(.gray)
                    }
                    .buttonStyle(.borderless)
                }
                
                TextField("URL (optional)", text: $url)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.URL)
                
                TextField("Notes (optional)", text: $notes, axis: .vertical)
                    .lineLimit(3...6)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }
            
            // MARK: - SAVE BUTTON SECTION
            Section {
                Button(action: saveEntry) {
                    HStack {
                        Spacer()
                        Text(editingEntry == nil ? "Add Password" : "Save Changes")
                            .fontWeight(.semibold)
                        Spacer()
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(name.isEmpty ? Color.gray : Color.blue) // Gray when disabled
                .foregroundColor(.white)
                .cornerRadius(10)
                .listRowBackground(Color.clear)
                .disabled(name.isEmpty) // Only name is required now!
            }
            
            // MARK: - DELETE BUTTON (only for editing)
            if editingEntry != nil {
                Section {
                    Button(role: .destructive, action: deleteEntry) {
                        HStack {
                            Spacer()
                            Text("Delete Entry")
                            Spacer()
                        }
                    }
                }
            }
        }
        .navigationTitle(editingEntry == nil ? "New Password" : "Edit Password")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func saveEntry() {
        if let existing = editingEntry {
            let updated = PasswordEntry(
                id: existing.id,
                name: name,
                username: username,
                password: password,
                url: url,
                notes: notes,
                createdDate: existing.createdDate,
                modifiedDate: Date(),
                lastUsedDate: existing.lastUsedDate
            )
            storage.updateEntry(updated)
        } else {
            let new = PasswordEntry(
                name: name,
                username: username,
                password: password,
                url: url,
                notes: notes
            )
            storage.addEntry(new)
        }
        dismiss()
    }
    
    private func deleteEntry() {
        if let entry = editingEntry {
            storage.deleteEntry(entry)
        }
        dismiss()
    }
}
