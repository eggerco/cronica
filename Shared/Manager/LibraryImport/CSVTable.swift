//
//  CSVTable.swift
//  Cronica
//

import Foundation

/// Minimal RFC-4180-ish CSV parser for third-party library exports.
enum CSVTable {
    struct Table: Equatable {
        var headers: [String]
        var rows: [[String: String]]
    }

    static func parse(_ data: Data) throws -> Table {
        let string: String
        if data.starts(with: [0xEF, 0xBB, 0xBF]), let utf8 = String(data: data.dropFirst(3), encoding: .utf8) {
            string = utf8
        } else if let utf8 = String(data: data, encoding: .utf8) {
            string = utf8
        } else if let utf16 = String(data: data, encoding: .utf16) {
            string = utf16
        } else {
            throw LibraryImportError.emptyFile
        }
        return try parse(string)
    }

    static func parse(_ string: String) throws -> Table {
        let lines = splitRecords(string)
        guard let headerLine = lines.first else { throw LibraryImportError.emptyFile }
        let headers = parseRecord(headerLine).map { normalizeHeader($0) }
        guard !headers.isEmpty else { throw LibraryImportError.emptyFile }

        var rows: [[String: String]] = []
        for line in lines.dropFirst() {
            if line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { continue }
            let values = parseRecord(line)
            var row: [String: String] = [:]
            for (index, header) in headers.enumerated() {
                guard !header.isEmpty else { continue }
                let value = index < values.count ? values[index].trimmingCharacters(in: .whitespacesAndNewlines) : ""
                row[header] = value
            }
            if row.values.contains(where: { !$0.isEmpty }) {
                rows.append(row)
            }
        }
        return Table(headers: headers, rows: rows)
    }

    static func value(_ row: [String: String], keys: String...) -> String? {
        for key in keys {
            if let value = row[normalizeHeader(key)], !value.isEmpty {
                return value
            }
        }
        return nil
    }

    static func normalizeHeader(_ raw: String) -> String {
        raw
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
    }

    // MARK: - Internals

    private static func splitRecords(_ string: String) -> [String] {
        var records: [String] = []
        var current = ""
        var inQuotes = false
        let chars = Array(string)
        var index = 0
        while index < chars.count {
            let char = chars[index]
            if char == "\"" {
                inQuotes.toggle()
                current.append(char)
            } else if (char == "\n" || char == "\r") && !inQuotes {
                if char == "\r", index + 1 < chars.count, chars[index + 1] == "\n" {
                    index += 1
                }
                records.append(current)
                current = ""
            } else {
                current.append(char)
            }
            index += 1
        }
        if !current.isEmpty || string.hasSuffix("\n") || string.hasSuffix("\r") {
            records.append(current)
        }
        return records
    }

    private static func parseRecord(_ line: String) -> [String] {
        var fields: [String] = []
        var current = ""
        var inQuotes = false
        let chars = Array(line)
        var index = 0
        while index < chars.count {
            let char = chars[index]
            if inQuotes {
                if char == "\"" {
                    if index + 1 < chars.count, chars[index + 1] == "\"" {
                        current.append("\"")
                        index += 1
                    } else {
                        inQuotes = false
                    }
                } else {
                    current.append(char)
                }
            } else if char == "\"" {
                inQuotes = true
            } else if char == "," {
                fields.append(current)
                current = ""
            } else {
                current.append(char)
            }
            index += 1
        }
        fields.append(current)
        return fields
    }
}
