//
//  SeedData.swift
//  Money
//
//  Created by 王建朝 on 2026/11/6.
//

import Foundation
import SwiftData

/// 首次启动（库为空时）预置常用账户与分类。
enum SeedData {
    @MainActor
    static func seedIfNeeded(context: ModelContext) {
        let accountCount = (try? context.fetchCount(FetchDescriptor<Account>())) ?? 0
        if accountCount == 0 {
            let accounts: [Account] = [
                Account(name: "现金", kind: .cash, sortOrder: 0),
                Account(name: "微信", kind: .wechat, sortOrder: 1),
                Account(name: "支付宝", kind: .alipay, sortOrder: 2),
            ]
            for account in accounts { context.insert(account) }
        }

        let categoryCount = (try? context.fetchCount(FetchDescriptor<Category>())) ?? 0
        if categoryCount == 0 {
            let expense: [(String, String)] = [
                ("餐饮", "fork.knife"),
                ("交通", "car"),
                ("购物", "bag"),
                ("居住", "house"),
                ("娱乐", "gamecontroller"),
                ("医疗", "cross.case"),
                ("其他", "ellipsis.circle"),
            ]
            for (index, item) in expense.enumerated() {
                context.insert(Category(name: item.0, kind: .expense, symbol: item.1, sortOrder: index))
            }

            let income: [(String, String)] = [
                ("工资", "banknote"),
                ("奖金", "gift"),
                ("理财", "chart.line.uptrend.xyaxis"),
                ("其他", "ellipsis.circle"),
            ]
            for (index, item) in income.enumerated() {
                context.insert(Category(name: item.0, kind: .income, symbol: item.1, sortOrder: index))
            }
        }

        try? context.save()
    }
}
