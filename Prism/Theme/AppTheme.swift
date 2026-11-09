//
//  AppTheme.swift
//  Prism
//
//  Created by 王建朝 on 2026/10/27.
//

import SwiftUI
import AppKit

/// Prism 的唯一颜色映射处：把原先硬编码的 sRGB 色板收敛为系统语义色，
/// 以便自动适配深浅色并与 Money 的原生风格保持一致。
enum AppTheme {
    /// 多色区分用调色板（交易、会话、工具等需要「一眼区分」的场景）。
    enum Accent {
        static let ink = Color.primary
        static let blue = Color.blue
        static let purple = Color.purple
        static let amber = Color.orange
        static let red = Color.red
        static let green = Color.green
    }

    /// 语义底色。
    static let separator = Color(nsColor: .separatorColor)
    static let controlBackground = Color(nsColor: .controlBackgroundColor)
    static let textBackground = Color(nsColor: .textBackgroundColor)

    /// 工具名 → 稳定的强调色。
    static func accent(forTool tool: String) -> Color {
        switch tool {
        case "Claude Code": .orange
        case "Codex": .mint
        case "Cursor": .gray
        case "WorkBuddy": .indigo
        case "CodeBuddy": .blue
        case "Trae", "Trae 国际版": .teal
        case "Trae CN": .cyan
        case "Kimi": .purple
        case "Comate": .red
        case "Qoder": .brown
        case "AutoClaw": .indigo
        default: .gray
        }
    }

    /// 交易阶段 → 强调色。
    static func stage(_ stage: String) -> Color {
        switch stage {
        case "Lead": .secondary
        case "Qualified": .blue
        case "Demo": .purple
        case "Proposal": .orange
        case "Negotiation": .red
        default: .green
        }
    }
}
