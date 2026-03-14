//PasswordStorage.swift
import Foundation
import SwiftUI
import Combine
import UniformTypeIdentifiers

class PasswordStorage: ObservableObject {
    @Published var entries: [PasswordEntry] = []
    
    // 2FA properties
    @Published var twoFASecret = ""
    @Published var is2FAEnabled = false
    @Published var recoveryCodes: [String] = []
    
    private var documentsURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    private var dataFileURL: URL {
        documentsURL.appendingPathComponent("passwords.json")
    }
    
    // 2FA settings file
    private var twoFASettingsURL: URL {
        documentsURL.appendingPathComponent("2fa_settings.csv")
    }
    
    // Recovery codes file
    private var recoveryCodesURL: URL {
        documentsURL.appendingPathComponent("recovery_codes.csv")
    }
    
    // Journal file for crash recovery
    private var journalURL: URL {
        documentsURL.appendingPathComponent("2fa_journal.log")
    }
    
    init() {
        loadEntries()
        load2FASettings()
        loadRecoveryCodes()
        checkJournal()
    }
    
    // MARK: - Password Methods
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
        
        let csvString = try String(contentsOf: url, encoding: .utf8)
        let rows = csvString.components(separatedBy: .newlines)
        
        var newEntries: [PasswordEntry] = []
        var isFirstRow = true
        
        for row in rows {
            let trimmedRow = row.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedRow.isEmpty else { continue }
            
            let columns = parseCSVRow(trimmedRow)
            
            if isFirstRow {
                isFirstRow = false
                if columns.count >= 3 &&
                   columns[0].lowercased() == "name" &&
                   columns[1].lowercased() == "username" {
                    continue
                }
            }
            
            guard columns.count >= 3 else { continue }
            
            let entry = PasswordEntry(
                name: columns[0],
                username: columns[1],
                password: columns[2],
                url: columns.count > 3 ? columns[3] : "",
                notes: columns.count > 4 ? columns[4] : ""
            )
            newEntries.append(entry)
        }
        
        DispatchQueue.main.async {
            self.entries.append(contentsOf: newEntries)
            self.saveEntries()
        }
    }
    
    private func parseCSVRow(_ row: String) -> [String] {
        var result: [String] = []
        var currentValue = ""
        var insideQuotes = false
        
        for character in row {
            if character == "\"" {
                insideQuotes.toggle()
            } else if character == "," && !insideQuotes {
                result.append(currentValue)
                currentValue = ""
            } else {
                currentValue.append(character)
            }
        }
        
        result.append(currentValue)
        return result
    }
    
    // MARK: - 2FA Methods
    
    func load2FASettings() {
        guard FileManager.default.fileExists(atPath: twoFASettingsURL.path) else {
            print("⚠️ No 2FA settings file found - this is normal for first launch")
            twoFASecret = ""
            is2FAEnabled = false
            return
        }
        
        do {
            let csvString = try String(contentsOf: twoFASettingsURL, encoding: .utf8)
            let rows = csvString.components(separatedBy: .newlines)
            
            if rows.count > 1 {
                let columns = rows[1].components(separatedBy: ",")
                if columns.count >= 2 {
                    twoFASecret = columns[0]
                    is2FAEnabled = columns[1] == "true"
                    print("✅ Loaded 2FA settings - Enabled: \(is2FAEnabled)")
                }
            }
        } catch {
            print("Failed to load 2FA settings: \(error)")
            twoFASecret = ""
            is2FAEnabled = false
        }
    }
    
    func save2FASettings(secret: String, enabled: Bool) {
        // Write to journal first (crash protection)
        try? "START_SAVE".write(to: journalURL, atomically: true, encoding: .utf8)
        
        let csvString = "secret,enabled\n\(secret),\(enabled)"
        
        do {
            try csvString.write(to: twoFASettingsURL, atomically: true, encoding: .utf8)
            twoFASecret = secret
            is2FAEnabled = enabled
            
            // Write success to journal
            try? "SAVE_COMPLETE".write(to: journalURL, atomically: true, encoding: .utf8)
            
            print("✅ Saved 2FA settings - Enabled: \(enabled)")
        } catch {
            print("Failed to save 2FA settings: \(error)")
        }
    }
    
    func saveRecoveryCodes(_ codes: [String]) {
        var csvString = "code,used\n"
        for code in codes {
            csvString += "\(code),false\n"
        }
        
        do {
            try csvString.write(to: recoveryCodesURL, atomically: true, encoding: .utf8)
            recoveryCodes = codes
            print("✅ Saved recovery codes")
        } catch {
            print("Failed to save recovery codes: \(error)")
        }
    }
    
    func loadRecoveryCodes() {
        guard FileManager.default.fileExists(atPath: recoveryCodesURL.path) else {
            recoveryCodes = []
            return
        }
        
        do {
            let csvString = try String(contentsOf: recoveryCodesURL, encoding: .utf8)
            let rows = csvString.components(separatedBy: .newlines)
            var codes: [String] = []
            
            for row in rows.dropFirst() { // Skip header
                let columns = row.components(separatedBy: ",")
                if columns.count >= 2 && columns[1] == "false" {
                    codes.append(columns[0])
                }
            }
            
            recoveryCodes = codes
        } catch {
            print("Failed to load recovery codes: \(error)")
            recoveryCodes = []
        }
    }
    
    func useRecoveryCode(_ code: String) -> Bool {
        guard var codes = try? String(contentsOf: recoveryCodesURL, encoding: .utf8) else {
            return false
        }
        
        var rows = codes.components(separatedBy: .newlines)
        var found = false
        
        for i in 1..<rows.count {
            if rows[i].hasPrefix(code) {
                rows[i] = "\(code),true"
                found = true
                break
            }
        }
        
        if found {
            let newContent = rows.joined(separator: "\n")
            try? newContent.write(to: recoveryCodesURL, atomically: true, encoding: .utf8)
            loadRecoveryCodes()
            return true
        }
        
        return false
    }
    
    func checkJournal() {
        guard let journal = try? String(contentsOf: journalURL, encoding: .utf8) else { return }
        
        if journal.contains("START_SAVE") && !journal.contains("SAVE_COMPLETE") {
            print("⚠️ Detected incomplete save - rolling back")
            // Crash occurred during save, reload from file
            load2FASettings()
        }
        
        // Clear journal
        try? "".write(to: journalURL, atomically: true, encoding: .utf8)
    }
    
    func enable2FA() -> String {
        let masterSecret = TOTPHelper.generateMasterSecret()
        save2FASettings(secret: masterSecret, enabled: true)
        return masterSecret
    }
    
    func disable2FA() {
        save2FASettings(secret: "", enabled: false)
        // Delete recovery codes
        try? FileManager.default.removeItem(at: recoveryCodesURL)
        recoveryCodes = []
    }
    
    // SAFE VERSION: Only returns code if 2FA is properly enabled
    func getCurrentSessionCode() -> String {
        guard is2FAEnabled && !twoFASecret.isEmpty else {
            print("⚠️ getCurrentSessionCode called but 2FA not enabled or secret empty")
            return "------"
        }
        
        do {
            let sessionKey = TOTPHelper.generateSessionKey(from: twoFASecret)
            return TOTPHelper.generateCode(from: sessionKey)
        } catch {
            print("❌ Failed to generate session code: \(error)")
            return "------"
        }
    }
}
