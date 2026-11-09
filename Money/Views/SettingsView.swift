//
//  SettingsView.swift
//  Money
//
//  Created by 王建朝 on 2026/11/6.
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Query private var entries: [Entry]
    @Query private var accounts: [Account]
    @Query private var categories: [Category]

    @State private var exportMessage: String?

    var body: some View {
        Form {
            Section("数据备份") {
                LabeledContent("账单数量") { Text("\(entries.count)") }
                LabeledContent("账户数量") { Text("\(accounts.count)") }
                LabeledContent("分类数量") { Text("\(categories.count)") }

                Button("导出 CSV") {
                    CSVExport.presentSavePanel(entries: entries)
                    exportMessage = "已生成导出文件"
                }
                if let exportMessage {
                    Text(exportMessage).font(.caption).foregroundStyle(.secondary)
                }
            }

            Section("关于") {
                LabeledContent("应用", value: "Money")
                LabeledContent("版本", value: "1.0")
            }
        }
        .formStyle(.grouped)
        .navigationTitle("设置")
    }
}
