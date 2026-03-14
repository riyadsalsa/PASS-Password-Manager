import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var storage: PasswordStorage
    
    var body: some View {
        TabView {
            NavigationStack {
                MainListView(entries: storage.entries, storage: storage)
                    .navigationTitle("PASSi")
                    .toolbar {
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
            
            NavigationStack {
                ImportExportView(storage: storage)
                    .navigationTitle("Data Management")
            }
            .tabItem {
                Label("Import", systemImage: "square.and.arrow.down")
            }
            
            NavigationStack {
                HelpView()
                    .navigationTitle("Help")
            }
            .tabItem {
                Label("Help", systemImage: "questionmark.circle")
            }
        }
        .onAppear {
            storage.loadEntries()
        }
    }
}
