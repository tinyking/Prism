//
//  EntryListView.swift
//  Money
//
//  Created by 王建朝 on 2026/11/6.
//

import SwiftUI
import SwiftData

struct EntryListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Entry.date, order: .reverse) private var entries: [Entry]
    @Query(sort: \Account.sortOrder) private var accounts: [Account]
    @Query(sort: \Category.sortOrder) private var categories: [Category]

    @State private var searchText = ""
    @State private var accountFilter: Account?
    @State private var categoryFilter: Category?
    @State private var editingEntry: Entry?

    private var filtered: [Entry] {
        entries.filter { entry in
            if let accountFilter,
               entry.account?.id != accountFilter.id,
               entry.toAccount?.id != accountFilter.id {
                return false
            }
            if let categoryFilter, entry.category?.id != categoryFilter.id {
                return false
            }
            if !searchText.isEmpty {
                let haystack = "\(entry.note) \(entry.account?.name ?? "") \(entry.toAccount?.name ?? "") \(entry.category?.name ?? "")"
                if !haystack.localizedCaseInsensitiveContains(searchText) { return false }
            }
            return true
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            filterBar
            Divider()
            if filtered.isEmpty {
                ContentUnavailableView(
                    "没有账单",
                    systemImage: "tray",
                    description: Text("试试调整筛选条件，或到「记一笔」添加。")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(filtered) { entry in
                        EntryRow(entry: entry)
                            .contentShape(Rectangle())
                            .onTapGesture(count: 2) { editingEntry = entry }
                            .contextMenu {
                                Button("编辑") { editingEntry = entry }
                                Button("删除", role: .destructive) { delete(entry) }
                            }
                    }
                    .onDelete(perform: delete)
                }
            }
        }
        .navigationTitle("账单")
        .sheet(item: $editingEntry) { entry in
            EditEntrySheet(entry: entry, accounts: accounts, categories: categories)
        }
    }

    private var filterBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
            TextField("搜索备注 / 账户 / 分类", text: $searchText)
                .textFieldStyle(.plain)

            Spacer(minLength: 12)

            Picker("", selection: $accountFilter) {
                Text("全部账户").tag(Account?.none)
                ForEach(accounts) { item in
                    Text(item.name).tag(Optional(item))
                }
            }
            .labelsHidden()
            .frame(width: 140)

            Picker("", selection: $categoryFilter) {
                Text("全部分类").tag(Category?.none)
                ForEach(categories) { item in
                    Text(item.name).tag(Optional(item))
                }
            }
            .labelsHidden()
            .frame(width: 140)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private func delete(_ entry: Entry) {
        context.delete(entry)
        try? context.save()
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            context.delete(filtered[index])
        }
        try? context.save()
    }
}

private struct EntryRow: View {
    let entry: Entry

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: entry.kind.symbol)
                .frame(width: 22)
                .foregroundStyle(tint)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }

            Spacer()

            Text(amountText)
                .monospacedDigit()
                .foregroundStyle(tint)
        }
        .padding(.vertical, 4)
    }

    private var title: String {
        switch entry.kind {
        case .expense, .income: entry.category?.name ?? "未分类"
        case .transfer: "转账"
        }
    }

    private var subtitle: String {
        var parts = [Self.dateFormatter.string(from: entry.date)]
        if entry.kind == .transfer {
            parts.append("\(entry.account?.name ?? "?") → \(entry.toAccount?.name ?? "?")")
        } else if let name = entry.account?.name {
            parts.append(name)
        }
        if !entry.note.isEmpty { parts.append(entry.note) }
        return parts.joined(separator: " · ")
    }

    private var amountText: String {
        let value = LedgerMath.currency(entry.amountCents)
        switch entry.kind {
        case .expense: return "−\(value)"
        case .income: return "+\(value)"
        case .transfer: return value
        }
    }

    private var tint: Color {
        switch entry.kind {
        case .expense: .red
        case .income: .green
        case .transfer: .blue
        }
    }
}

private struct EditEntrySheet: View {
    @Environment(\.dismiss) private var dismiss

    let entry: Entry
    let accounts: [Account]
    let categories: [Category]

    @State private var amountText: String
    @State private var date: Date
    @State private var note: String
    @State private var account: Account?
    @State private var category: Category?

    init(entry: Entry, accounts: [Account], categories: [Category]) {
        self.entry = entry
        self.accounts = accounts
        self.categories = categories
        _amountText = State(initialValue: LedgerMath.yuanString(entry.amountCents))
        _date = State(initialValue: entry.date)
        _note = State(initialValue: entry.note)
        _account = State(initialValue: entry.account)
        _category = State(initialValue: entry.category)
    }

    private var availableCategories: [Category] {
        let wanted: CategoryKind = entry.kind == .income ? .income : .expense
        return categories.filter { $0.kind == wanted }
    }

    private var parsedCents: Int? {
        LedgerMath.cents(fromYuanText: amountText)
    }

    var body: some View {
        VStack(spacing: 0) {
            Form {
                TextField("金额（元）", text: $amountText)
                DatePicker("日期", selection: $date, displayedComponents: .date)
                Picker("账户", selection: $account) {
                    Text("请选择").tag(Account?.none)
                    ForEach(accounts) { item in
                        Text(item.name).tag(Optional(item))
                    }
                }
                if entry.kind != .transfer {
                    Picker("分类", selection: $category) {
                        Text("未分类").tag(Category?.none)
                        ForEach(availableCategories) { item in
                            Text(item.name).tag(Optional(item))
                        }
                    }
                }
                TextField("备注", text: $note)
            }
            .formStyle(.grouped)

            Divider()

            HStack {
                Spacer()
                Button("取消") { dismiss() }
                Button("保存", action: save)
                    .keyboardShortcut(.defaultAction)
                    .disabled(parsedCents == nil)
            }
            .padding(16)
        }
        .frame(width: 420, height: 440)
    }

    private func save() {
        guard let cents = parsedCents, cents > 0 else { return }
        entry.amountCents = cents
        entry.date = date
        entry.note = note.trimmingCharacters(in: .whitespacesAndNewlines)
        entry.account = account
        if entry.kind != .transfer {
            entry.category = category
        }
        try? entry.modelContext?.save()
        dismiss()
    }
}
