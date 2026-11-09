//
//  CSVExport.swift
//  Money
//
//  Created by 王建朝 on 2026/11/6.
//

import Foundation
import AppKit
import UniformTypeIdentifiers

/// 把账单导出为 CSV，经 `NSSavePanel` 落盘。
enum CSVExport {
    static let header = "日期,类型,金额,账户,目标账户,分类,备注"

    static func csvString(from entries: [Entry]) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"

        var lines = [header]
        for entry in entries.sorted(by: { $0.date < $1.date }) {
            let fields = [
                formatter.string(from: entry.date),
                entry.kind.title,
                LedgerMath.yuanString(entry.amountCents),
                entry.account?.name ?? "",
                entry.toAccount?.name ?? "",
                entry.category?.name ?? "",
                entry.note,
            ]
            lines.append(fields.map(escape).joined(separator: ","))
        }
        return lines.joined(separator: "\n")
    }

    @MainActor
    static func presentSavePanel(entries: [Entry]) {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.commaSeparatedText]
        panel.canCreateDirectories = true
        panel.nameFieldStringValue = "Money账单.csv"

        guard panel.runModal() == .OK, let url = panel.url else { return }

        do {
            try csvString(from: entries).write(to: url, atomically: true, encoding: .utf8)
        } catch {
            NSAlert(error: error).runModal()
        }
    }

    private static func escape(_ field: String) -> String {
        guard field.contains(",") || field.contains("\"") || field.contains("\n") || field.contains("\r") else {
            return field
        }
        return "\"" + field.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }
}
