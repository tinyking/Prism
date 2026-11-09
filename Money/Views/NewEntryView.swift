//
//  NewEntryView.swift
//  Money
//
//  Created by 王建朝 on 2026/11/6.
//

import SwiftUI
import SwiftData

struct NewEntryView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Account.sortOrder) private var accounts: [Account]
    @Query(sort: \Category.sortOrder) private var categories: [Category]

    @State private var kind: EntryKind = .expense
    @State private var amountText = ""
    @State private var date = Date()
    @State private var note = ""
    @State private var account: Account?
    @State private var toAccount: Account?
    @State private var category: Category?
    @State private var message: String?

    private var availableCategories: [Category] {
        let wanted: CategoryKind = kind == .income ? .income : .expense
        return categories.filter { $0.kind == wanted }
    }

    private var parsedCents: Int? {
        LedgerMath.cents(fromYuanText: amountText)
    }

    private var canSave: Bool {
        guard let cents = parsedCents, cents > 0, account != nil else { return false }
        if kind == .transfer {
            return toAccount != nil && toAccount != account
        }
        return true
    }

    var body: some View {
        Form {
            Section {
                Picker("类型", selection: $kind) {
                    ForEach(EntryKind.allCases) { item in
                        Text(item.title).tag(item)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section {
                TextField("金额（元）", text: $amountText)
                DatePicker("日期", selection: $date, displayedComponents: .date)
            }

            Section {
                Picker("账户", selection: $account) {
                    Text("请选择").tag(Account?.none)
                    ForEach(accounts) { item in
                        Text(item.name).tag(Optional(item))
                    }
                }

                if kind == .transfer {
                    Picker("转入账户", selection: $toAccount) {
                        Text("请选择").tag(Account?.none)
                        ForEach(accounts) { item in
                            Text(item.name).tag(Optional(item))
                        }
                    }
                } else {
                    Picker("分类", selection: $category) {
                        Text("未分类").tag(Category?.none)
                        ForEach(availableCategories) { item in
                            Text(item.name).tag(Optional(item))
                        }
                    }
                }

                TextField("备注", text: $note)
            }

            Section {
                HStack(spacing: 12) {
                    Button("保存", action: save)
                        .keyboardShortcut(.defaultAction)
                        .disabled(!canSave)
                    if let message {
                        Text(message).font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("记一笔")
        .onAppear(perform: applyDefaults)
        .onChange(of: accounts) { _, _ in applyDefaults() }
        .onChange(of: kind) { _, _ in
            if kind == .transfer { category = nil } else { toAccount = nil }
            applyDefaults()
        }
    }

    private func applyDefaults() {
        if account == nil { account = accounts.first }
        if kind == .transfer {
            if toAccount == nil {
                toAccount = accounts.first { $0.id != account?.id }
            }
        } else if category == nil {
            category = availableCategories.first
        }
    }

    private func save() {
        guard let cents = parsedCents, cents > 0, let account else { return }
        if kind == .transfer {
            guard let toAccount, toAccount != account else {
                message = "请选择不同的转入账户"
                return
            }
        }

        let entry = Entry(
            amountCents: cents,
            kind: kind,
            date: date,
            note: note.trimmingCharacters(in: .whitespacesAndNewlines),
            account: account,
            toAccount: kind == .transfer ? toAccount : nil,
            category: kind == .transfer ? nil : category
        )
        context.insert(entry)
        do {
            try context.save()
        } catch {
            message = "保存失败：\(error.localizedDescription)"
            return
        }
        message = "已记录 \(LedgerMath.currency(cents))"
        amountText = ""
        note = ""
    }
}
