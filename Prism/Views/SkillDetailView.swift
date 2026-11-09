//
//  SkillDetailView.swift
//  Prism
//
//  Created by 王建朝 on 2026/10/27.
//

import SwiftUI

struct SkillDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let skill: SkillItem

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(skill.name).font(.title3.weight(.semibold))
                    Text(skill.description).font(.callout).foregroundStyle(.secondary)
                }
                Spacer()
                HStack(spacing: 9) {
                    Text(skill.tool)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(AppTheme.accent(forTool: skill.tool))
                        .padding(.horizontal, 9).padding(.vertical, 5)
                        .background(AppTheme.accent(forTool: skill.tool).opacity(0.15), in: Capsule())
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .frame(width: 28, height: 28)
                            .background(AppTheme.controlBackground, in: Circle())
                    }
                    .buttonStyle(.plain)
                    .keyboardShortcut(.cancelAction)
                    .help("Close skill details")
                }
            }
            .padding(20)
            Divider()
            ScrollView {
                Text(skill.contents)
                    .font(.system(.body, design: .monospaced))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(20)
            }
        }
    }
}
