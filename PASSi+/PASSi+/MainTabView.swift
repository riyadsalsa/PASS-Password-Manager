//MainTabView.swift
import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var storage: PasswordStorage
    @EnvironmentObject var lockManager: AppLockManager
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Passwords List Tab
            NavigationStack {
                MainListView(entries: storage.entries, storage: storage)
                    .navigationTitle("PASSi+")
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button(action: { lockManager.lock() }) {
                                Image(systemName: "lock")
                            }
                        }
                        ToolbarItem(placement: .topBarTrailing) {
                            NavigationLink(destination: ChangePasswordView(storage: storage)) {
                                Image(systemName: "plus")
                            }
                        }
                    }
            }
            .tabItem {
                Label("Passwords", systemImage: "lock.fill")
            }
            .tag(0)
            
            // Import/Export Tab
            NavigationStack {
                ImportExportView(storage: storage)
                    .navigationTitle("Data Management")
            }
            .tabItem {
                Label("Import", systemImage: "square.and.arrow.down")
            }
            .tag(1)
            
            // Settings Tab (NEW - replaces Help tab)
            NavigationStack {
                SettingsView(storage: storage, lockManager: lockManager)
                    .navigationTitle("Settings")
            }
            .tabItem {
                Label("Settings", systemImage: "gear")
            }
            .tag(2)
        }
        .onAppear {
            storage.loadEntries()
        }
    }
}

// NEW: Settings View
struct SettingsView: View {
    @ObservedObject var storage: PasswordStorage
    @ObservedObject var lockManager: AppLockManager
    @State private var showing2FA = false
    
    var body: some View {
        List {
            // Security Section
            Section("Security") {
                // 2FA Option
                NavigationLink(destination: TwoFASetupView(storage: storage)) {
                    HStack {
                        Image(systemName: storage.is2FAEnabled ? "lock.shield.fill" : "shield")
                            .foregroundColor(storage.is2FAEnabled ? .green : .gray)
                        VStack(alignment: .leading) {
                            Text("Two-Factor Authentication")
                            if storage.is2FAEnabled {
                                Text("Enabled")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                        }
                    }
                }
                
                // Lock App Button
                Button(action: { lockManager.lock() }) {
                    HStack {
                        Image(systemName: "lock")
                            .foregroundColor(.blue)
                        Text("Lock App Now")
                    }
                }
            }
            
            // About Section
            Section("About") {
                NavigationLink(destination: HelpView()) {
                    Label("Help & Instructions", systemImage: "questionmark.circle")
                }
                
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.1")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("2FA Status")
                    Spacer()
                    Text(storage.is2FAEnabled ? "Enabled" : "Disabled")
                        .foregroundColor(storage.is2FAEnabled ? .green : .secondary)
                }
            }
            
            // Data Section
            Section("Data") {
                HStack {
                    Text("Total Passwords")
                    Spacer()
                    Text("\(storage.entries.count)")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Storage Location")
                    Spacer()
                    Text("On Device")
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(PasswordStorage())
        .environmentObject(AppLockManager())
}
