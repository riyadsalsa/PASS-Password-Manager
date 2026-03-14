import SwiftUI

struct MainListView: View {
    let entries: [PasswordEntry]
    let storage: PasswordStorage
    @State private var searchText = ""
    
    var filteredEntries: [PasswordEntry] {
        storage.searchEntries(query: searchText)
    }
    
    var body: some View {
        List(filteredEntries) { entry in
            NavigationLink(destination: EntryDetailView(entry: entry, storage: storage)) {
                VStack(alignment: .leading) {
                    Text(entry.name)
                        .font(.headline)
                    Text(entry.username)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
        .searchable(text: $searchText, prompt: "Search passwords")
        .overlay {
            if entries.isEmpty {
                ContentUnavailableView(
                    "No Passwords",
                    systemImage: "lock.slash",
                    description: Text("Import a CSV file to get started")
                )
            } else if filteredEntries.isEmpty && !searchText.isEmpty {
                ContentUnavailableView.search
            }
        }
    }
}
