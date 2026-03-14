import SwiftUI
import UniformTypeIdentifiers

struct ImportExportView: View {
    @ObservedObject var storage: PasswordStorage
    @State private var showingFileImporter = false
    @State private var showingExporter = false
    @State private var importError: Error?
    @State private var showingError = false
    @State private var exportData: CSVFile?
    
    struct CSVFile: FileDocument {
        static var readableContentTypes: [UTType] = [.commaSeparatedText]
        
        var text: String
        
        init(text: String) {
            self.text = text
        }
        
        init(configuration: ReadConfiguration) throws {
            guard let data = configuration.file.regularFileContents,
                  let string = String(data: data, encoding: .utf8)
            else {
                throw CocoaError(.fileReadCorruptFile)
            }
            text = string
        }
        
        func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
            let data = text.data(using: .utf8)!
            return FileWrapper(regularFileWithContents: data)
        }
    }
    
    var body: some View {
        List {
            Section("Import") {
                Button(action: { showingFileImporter = true }) {
                    Label("Import from CSV", systemImage: "square.and.arrow.down")
                }
            }
            
            Section("Export") {
                Button(action: exportCSV) {
                    Label("Export to CSV", systemImage: "square.and.arrow.up")
                }
                .disabled(storage.entries.isEmpty)
                
                if !storage.entries.isEmpty {
                    Text("Export all \(storage.entries.count) entries")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Section("Statistics") {
                HStack {
                    Text("Total Entries")
                    Spacer()
                    Text("\(storage.entries.count)")
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("Data Management")
        .fileImporter(
            isPresented: $showingFileImporter,
            allowedContentTypes: [.commaSeparatedText],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                do {
                    try storage.importFromCSV(url: url)
                } catch {
                    importError = error
                    showingError = true
                }
            case .failure(let error):
                importError = error
                showingError = true
            }
        }
        .fileExporter(
            isPresented: $showingExporter,
            document: exportData,
            contentType: .commaSeparatedText,
            defaultFilename: "PASSi_export.csv"
        ) { result in
            switch result {
            case .success(let url):
                print("Exported to: \(url)")
            case .failure(let error):
                print("Export error: \(error)")
                importError = error
                showingError = true
            }
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(importError?.localizedDescription ?? "Unknown error")
        }
    }
    
    private func exportCSV() {
        var csvString = "Name,Username,Password,URL,Notes\n"
        
        for entry in storage.entries {
            let name = escapeCSVField(entry.name)
            let username = escapeCSVField(entry.username)
            let password = escapeCSVField(entry.password)
            let url = escapeCSVField(entry.url)
            let notes = escapeCSVField(entry.notes)
            
            csvString += "\(name),\(username),\(password),\(url),\(notes)\n"
        }
        
        exportData = CSVFile(text: csvString)
        showingExporter = true
    }
    
    private func escapeCSVField(_ field: String) -> String {
        if field.contains(",") || field.contains("\"") || field.contains("\n") {
            let escaped = field.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escaped)\""
        }
        return field
    }
}

#Preview {
    ImportExportView(storage: PasswordStorage())
}
