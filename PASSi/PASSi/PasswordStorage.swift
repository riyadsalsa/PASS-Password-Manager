import Foundation
import Combine
import UniformTypeIdentifiers

class PasswordStorage: ObservableObject {
    @Published var entries: [PasswordEntry] = []
    
    private let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    
    private var dataFileURL: URL {
        documentsURL.appendingPathComponent("passwords.json")
    }
    
    init() {
        loadEntries()
    }
    
    func loadEntries() {
        guard FileManager.default.fileExists(atPath: dataFileURL.path) else {
            entries = []
            return
        }
        
        do {
            let data = try Data(contentsOf: dataFileURL)
            entries = try JSONDecoder().decode([PasswordEntry].self, from: data)
        } catch {
            print("Load error: \(error)")
            entries = []
        }
    }
    
    func saveEntries() {
        do {
            let data = try JSONEncoder().encode(entries)
            try data.write(to: dataFileURL, options: .completeFileProtection)
        } catch {
            print("Save error: \(error)")
        }
    }
    
    func addEntry(_ entry: PasswordEntry) {
        var newEntry = entry
        newEntry.createdDate = Date()
        newEntry.modifiedDate = Date()
        entries.append(newEntry)
        saveEntries()
    }
    
    func updateEntry(_ entry: PasswordEntry) {
        if let index = entries.firstIndex(where: { $0.id == entry.id }) {
            var updated = entry
            updated.modifiedDate = Date()
            entries[index] = updated
            saveEntries()
        }
    }
    
    func deleteEntry(_ entry: PasswordEntry) {
        entries.removeAll { $0.id == entry.id }
        saveEntries()
    }
    
    func searchEntries(query: String) -> [PasswordEntry] {
        guard !query.isEmpty else { return entries }
        
        return entries.filter { entry in
            entry.name.localizedCaseInsensitiveContains(query) ||
            entry.username.localizedCaseInsensitiveContains(query) ||
            entry.url.localizedCaseInsensitiveContains(query) ||
            entry.notes.localizedCaseInsensitiveContains(query)
        }
    }
    
    // MARK: - CSV Import
    func importFromCSV(url: URL) throws {
        guard url.startAccessingSecurityScopedResource() else {
            throw NSError(domain: "PASSi", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "Cannot access file"])
        }
        defer { url.stopAccessingSecurityScopedResource() }
        
        // Read the entire file
        let csvString = try String(contentsOf: url, encoding: .utf8)
        print("📄 CSV Content Length: \(csvString.count) characters")
        
        // Parse CSV properly handling quotes and line breaks
        let parsedRows = parseCSV(content: csvString)
        print("📊 Found \(parsedRows.count) entries after parsing")
        
        var newEntries: [PasswordEntry] = []
        var isFirstRow = true
        
        for (index, columns) in parsedRows.enumerated() {
            // Skip empty rows
            if columns.isEmpty || (columns.count == 1 && columns[0].isEmpty) {
                continue
            }
            
            // Skip header row
            if isFirstRow {
                isFirstRow = false
                if columns.count >= 1 && columns[0].lowercased() == "name" {
                    print("📌 Skipping header row")
                    continue
                }
            }
            
            // Ensure we have at least 3 columns
            guard columns.count >= 3 else {
                print("⚠️ Row \(index) has only \(columns.count) columns, skipping")
                continue
            }
            
            let entry = PasswordEntry(
                name: columns[0],
                username: columns[1],
                password: columns[2],
                url: columns.count > 3 ? columns[3] : "",
                notes: columns.count > 4 ? columns[4] : ""
            )
            newEntries.append(entry)
            print("✅ Imported: \(entry.name)")
        }
        
        print("📥 Total imported: \(newEntries.count) entries")
        
        DispatchQueue.main.async {
            self.entries.append(contentsOf: newEntries)
            self.saveEntries()
        }
    }
    
    // MARK: - Proper CSV Parser
    private func parseCSV(content: String) -> [[String]] {
        var result: [[String]] = []
        var currentRow: [String] = []
        var currentField = ""
        var insideQuotes = false
        
        // Process each character
        for character in content {
            switch character {
            case "\"":
                // Toggle quote state
                insideQuotes.toggle()
                
            case ",":
                if insideQuotes {
                    // Comma inside quotes is part of the field
                    currentField.append(character)
                } else {
                    // Comma outside quotes ends the field
                    currentRow.append(currentField)
                    currentField = ""
                }
                
            case "\n", "\r\n":
                if insideQuotes {
                    // Line break inside quotes is part of the field
                    currentField.append(character)
                } else {
                    // Line break outside quotes ends the row
                    currentRow.append(currentField)
                    if !currentRow.isEmpty && !(currentRow.count == 1 && currentRow[0].isEmpty) {
                        result.append(currentRow)
                    }
                    currentRow = []
                    currentField = ""
                }
                
            default:
                currentField.append(character)
            }
        }
        
        // Don't forget the last field/row
        if !currentField.isEmpty || !currentRow.isEmpty {
            currentRow.append(currentField)
            if !currentRow.isEmpty && !(currentRow.count == 1 && currentRow[0].isEmpty) {
                result.append(currentRow)
            }
        }
        
        return result
    }
}
