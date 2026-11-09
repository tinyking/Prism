//
//  RootView.swift
//  Money
//
//  Created by 王建朝 on 2026/11/6.
//

import SwiftUI
import SwiftData

enum NavItem: String, CaseIterable, Identifiable {
    case overview
    case newEntry
    case entries
    case report
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .overview: "概览"
        case .newEntry: "记一笔"
        case .entries: "账单"
        case .report: "统计"
        case .settings: "设置"
        }
    }

    var symbol: String {
        switch self {
        case .overview: "wallet.pass"
        case .newEntry: "plus.circle"
        case .entries: "list.bullet"
        case .report: "chart.pie"
        case .settings: "gearshape"
        }
    }
}

struct RootView: View {
    @Environment(\.modelContext) private var context
    @State private var selection: NavItem? = .overview

    var body: some View {
        NavigationSplitView {
            List(NavItem.allCases, selection: $selection) { item in
                Label(item.title, systemImage: item.symbol)
                    .tag(item)
            }
            .navigationSplitViewColumnWidth(min: 168, ideal: 180, max: 240)
        } detail: {
            detail
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .task {
            SeedData.seedIfNeeded(context: context)
        }
    }

    @ViewBuilder
    private var detail: some View {
        switch selection ?? .overview {
        case .overview: OverviewView()
        case .newEntry: NewEntryView()
        case .entries: EntryListView()
        case .report: ReportView()
        case .settings: SettingsView()
        }
    }
}

#Preview {
    RootView()
        .modelContainer(for: [Account.self, Category.self, Entry.self], inMemory: true)
}
