//
//  SkillsView.swift
//  Prism
//
//  Created by 王建朝 on 2026/10/27.
//

import SwiftUI
import AppKit

struct SkillsView: View {
    @Binding var searchText: String
    let store: SkillStore

    @State private var selectedSkill: SkillItem?

    var body: some View {
        ScrollView {
            content
        }
        .navigationTitle("技能")
        .searchable(text: $searchText, prompt: "搜索技能")
        .toolbar {
            ToolbarItemGroup {
                Text("\(filteredSkills.count) skills")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Button {
                    store.isLoaded = false
                    store.scan()
                } label: {
                    Label("Rescan", systemImage: "arrow.clockwise")
                }
                .help("Rescan skill folders")
            }
        }
        .sheet(item: $selectedSkill) { skill in
            SkillDetailView(skill: skill)
                .frame(minWidth: 520, minHeight: 420)
        }
        .task { store.scanIfNeeded() }
    }

    private var filteredSkills: [SkillItem] {
        guard !searchText.isEmpty else { return store.skills }
        return store.skills.filter { "\($0.name) \($0.description) \($0.tool)".localizedCaseInsensitiveContains(searchText) }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("A collection of tools and workflows available in your workspace.")
                .font(.body)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 20).padding(.top, 16)

            if store.isScanning {
                ProgressView("Scanning skill folders…")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 200)
            } else if filteredSkills.isEmpty {
                VStack(spacing: 12) {
                    ContentUnavailableView(
                        searchText.isEmpty ? (store.message ?? "No skills found.") : "No skills match your search.",
                        systemImage: "sparkles"
                    )
                    if searchText.isEmpty {
                        Button("Scan Again") { store.scan() }
                            .disabled(store.isScanning)
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 200)
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 245), spacing: 12)], alignment: .leading, spacing: 12) {
                    ForEach(filteredSkills) { skill in
                        card(skill)
                    }
                }
                .padding(.horizontal, 20).padding(.top, 16).padding(.bottom, 24)
            }
        }
    }

    private func card(_ skill: SkillItem) -> some View {
        let accent = AppTheme.accent(forTool: skill.tool)
        return HStack(alignment: .top, spacing: 12) {
            Text(String(skill.name.prefix(1)).uppercased())
                .font(.title3.weight(.semibold))
                .foregroundStyle(accent)
                .frame(width: 36, height: 36)
                .background(accent.opacity(0.15), in: RoundedRectangle(cornerRadius: 10))
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline) {
                    Text(skill.name)
                        .font(.headline)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    Spacer(minLength: 5)
                    Text(skill.tool)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(accent)
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(accent.opacity(0.15), in: Capsule())
                }
                Text(skill.description)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .truncationMode(.tail)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 112, maxHeight: 112, alignment: .topLeading)
        .clipped()
        .background(AppTheme.controlBackground, in: RoundedRectangle(cornerRadius: 12))
        .contentShape(RoundedRectangle(cornerRadius: 12))
        .onTapGesture { selectedSkill = skill }
        .overlay(alignment: .bottomTrailing) {
            Button {
                NSWorkspace.shared.open(URL(fileURLWithPath: skill.path).deletingLastPathComponent())
            } label: {
                Image(systemName: "folder")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                    .frame(width: 24, height: 24)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help("Show in Finder")
            .padding(6)
        }
    }
}
