//
//  LedgerMath.swift
//  Money
//
//  Created by 王建朝 on 2026/11/6.
//

import Foundation
import SwiftData

struct MonthSummary: Equatable {
    var incomeCents: Int = 0
    var expenseCents: Int = 0
    var netCents: Int { incomeCents - expenseCents }
}

struct CategorySlice: Identifiable, Equatable {
    var id: String
    var name: String
    var totalCents: Int
}

/// 记账领域内的纯计算逻辑。所有函数无副作用，输入 `[Entry]`，输出数值/数组。
enum LedgerMath {
    /// 账户余额 = 期初余额 + 收入 − 支出 + 转入 − 转出。
    static func balance(of account: Account, in entries: [Entry]) -> Int {
        var total = account.openingBalanceCents
        for entry in entries {
            let isSource = entry.account?.persistentModelID == account.persistentModelID
            let isTarget = entry.toAccount?.persistentModelID == account.persistentModelID
            switch entry.kind {
            case .income:
                if isSource { total += entry.amountCents }
            case .expense:
                if isSource { total -= entry.amountCents }
            case .transfer:
                if isSource { total -= entry.amountCents }
                if isTarget { total += entry.amountCents }
            }
        }
        return total
    }

    /// 净资产 = 全部账户余额之和（信用卡余额可为负）。
    static func netWorth(_ accounts: [Account], entries: [Entry]) -> Int {
        accounts.reduce(0) { $0 + balance(of: $1, in: entries) }
    }

    /// 月度收入/支出汇总。转账不计入收支。
    static func monthSummary(_ entries: [Entry], in interval: DateInterval) -> MonthSummary {
        var summary = MonthSummary()
        for entry in entries where interval.contains(entry.date) {
            switch entry.kind {
            case .income: summary.incomeCents += entry.amountCents
            case .expense: summary.expenseCents += entry.amountCents
            case .transfer: break
            }
        }
        return summary
    }

    /// 按分类汇总支出，金额从大到小。
    static func expenseBreakdownByCategory(_ entries: [Entry], in interval: DateInterval) -> [CategorySlice] {
        var totals: [String: Int] = [:]
        for entry in entries where interval.contains(entry.date) && entry.kind == .expense {
            totals[entry.category?.name ?? "未分类", default: 0] += entry.amountCents
        }
        return totals
            .map { CategorySlice(id: $0.key, name: $0.key, totalCents: $0.value) }
            .sorted { $0.totalCents > $1.totalCents }
    }

    /// 分 → 展示用货币字符串，如 `¥1,234.56`。
    static func currency(_ cents: Int) -> String {
        (Double(cents) / 100).formatted(.currency(code: "CNY").precision(.fractionLength(2)))
    }

    /// 分 → 元的纯数字字符串，如 `1234.56`（导出 CSV 用）。
    static func yuanString(_ cents: Int) -> String {
        String(format: "%.2f", Double(cents) / 100)
    }

    /// 用户输入的「元」文本 → 分（四舍五入）。
    static func cents(fromYuanText text: String) -> Int? {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, var value = Decimal(string: trimmed) else { return nil }
        value *= 100
        var rounded = Decimal()
        NSDecimalRound(&rounded, &value, 0, .plain)
        return NSDecimalNumber(decimal: rounded).intValue
    }
}
