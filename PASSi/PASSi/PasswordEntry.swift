//
//  //
//  //
//  PasswordEntry.swift
//  PASS25
//
//  Created on 2025-02-13
//

import Foundation

struct PasswordEntry: Codable, Identifiable, Hashable {
    let id: UUID
    var name: String
    var username: String
    var password: String
    var url: String
    var notes: String
    var createdDate: Date
    var modifiedDate: Date
    var lastUsedDate: Date?
    
    init(
        id: UUID = UUID(),
        name: String = "",
        username: String = "",
        password: String = "",
        url: String = "",
        notes: String = "",
        createdDate: Date = Date(),
        modifiedDate: Date = Date(),
        lastUsedDate: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.username = username
        self.password = password
        self.url = url
        self.notes = notes
        self.createdDate = createdDate
        self.modifiedDate = modifiedDate
        self.lastUsedDate = lastUsedDate
    }
    
    mutating func updateModifiedDate() {
        self.modifiedDate = Date()
    }
    
    mutating func updateLastUsedDate() {
        self.lastUsedDate = Date()
    }
    
    var domain: String {
        guard let url = URL(string: url),
              let host = url.host else {
            return url
        }
        return host
    }
}
