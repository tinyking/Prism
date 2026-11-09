//
//  ContentView.swift
//  Prism
//
//  Created by 王建朝 on 2026/10/27.
//

import SwiftUI

enum NavSection: String, CaseIterable, Identifiable {
    case inbox, deals, skills

    var id: String { rawValue }

    var title: String {
        switch self {
        case .inbox: "Inbox"
        case .deals: "Deals"
        case .skills: "Skills"
        }
    }

    var symbol: String {
        switch self {
        case .inbox: "bubble.left.and.bubble.right.fill"
        case .deals: "chart.bar.xaxis"
        case .skills: "sparkles.rectangle.stack"
        }
    }
}

struct ContentView: View {
    @State private var section: NavSection? = .inbox
    @State private var selectedTab = "All deals"
    @State private var searchText = ""
    @State private var selectedDeals: Set<UUID> = []
    @State private var selectedConversationID: InboxConversation.ID?
    @State private var hoveredSection: NavSection?
    @State private var skillStore = SkillStore()

    private var filteredDeals: [Deal] {
        Deal.samples.filter { deal in
            let tabMatch = selectedTab == "All deals" || (selectedTab == "Closing this quarter" && deal.closing) || (selectedTab == "Needs you" && deal.needsYou) || (selectedTab == "Won" && deal.stage == "Won")
            let queryMatch = searchText.isEmpty || "\(deal.company) \(deal.detail) \(deal.ownerName)".localizedCaseInsensitiveContains(searchText)
            return tabMatch && queryMatch
        }
    }

    private var filteredConversations: [InboxConversation] {
        guard !searchText.isEmpty else { return InboxConversation.samples }
        return InboxConversation.samples.filter { "\($0.title) \($0.preview)".localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            detail
        }
        .navigationSplitViewStyle(.balanced)
        .task { skillStore.scanIfNeeded() }
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 3) {
            ForEach(NavSection.allCases) { item in
                Button {
                    section = item
                } label: {
                    HStack(spacing: 6) {
                        Label(item.title, systemImage: item.symbol)
                        Spacer(minLength: 4)
                        if let count = countText(for: item) {
                            Text(count).foregroundStyle(.secondary)
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(rowFill(for: item), in: RoundedRectangle(cornerRadius: 6))
                    .contentShape(Rectangle())
                }
                .buttonStyle(SidebarRowButtonStyle())
                .onHover { hovering in
                    if hovering {
                        hoveredSection = item
                    } else if hoveredSection == item {
                        hoveredSection = nil
                    }
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 8)
        .padding(.top, 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .navigationSplitViewColumnWidth(min: 170, ideal: 180, max: 240)
        .safeAreaInset(edge: .bottom) { accountFooter }
    }

    private func rowFill(for item: NavSection) -> Color {
        if section == item { return Color.accentColor.opacity(0.16) }
        if hoveredSection == item { return Color.primary.opacity(0.06) }
        return .clear
    }

    @ViewBuilder
    private var detail: some View {
        switch section ?? .inbox {
        case .inbox:
            NavigationSplitView {
                InboxListView(
                    selection: $selectedConversationID,
                    searchText: $searchText,
                    conversations: filteredConversations
                )
                .navigationSplitViewColumnWidth(min: 240, ideal: 280, max: 360)
            } detail: {
                InboxDetailView(conversation: InboxConversation.samples.first { $0.id == selectedConversationID })
            }
        case .deals:
            DealsView(
                selectedTab: $selectedTab,
                selectedDeals: $selectedDeals,
                searchText: $searchText,
                deals: filteredDeals
            )
        case .skills:
            SkillsView(searchText: $searchText, store: skillStore)
        }
    }

    private func countText(for item: NavSection) -> String? {
        switch item {
        case .inbox: return "7"
        case .deals: return "22"
        case .skills: return skillStore.isLoaded ? "\(skillStore.skills.count)" : nil
        }
    }

    private var accountFooter: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: 8) {
                AvatarView(initials: "LW", size: 27)
                VStack(alignment: .leading, spacing: 1) {
                    Text("Leon Wang").font(.body.weight(.medium))
                    Text("Head of sales").font(.caption).foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
                Image(systemName: "slider.horizontal.3").foregroundStyle(.secondary)
            }
            .padding(10)
        }
    }
}

#Preview {
    ContentView()
}

private struct SidebarRowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.6 : 1)
            .animation(.easeOut(duration: 0.08), value: configuration.isPressed)
    }
}
