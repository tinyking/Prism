//
//  Entry.swift
//  Money
//
//  Created by 王建朝 on 2026/11/6.
//

import Foundation
import SwiftData

enum EntryKind: String, Codable, CaseIterable, Identifiable {
    case expense
    case income
    case transfer

    var id: String { rawValue }

    var title: String {
        switch self {
        case .expense: "支出"
        case .income: "收入"
        case .transfer: "转账"
        }
    }

    var symbol: String {
        switch self {
        case .expense: "minus.circle"
        case .income: "plus.circle"
        case .transfer: "arrow.left.arrow.right"
        }
    }
}

@Model
final class Entry {
    /// 金额，恒为正数，单位「分」。
    var amountCents: Int
    var kindRaw: String
    var date: Date
    var note: String
    var createdAt: Date

    /// 支出/收入账户；转账时为转出账户。
    var account: Account?
    /// 仅转账时非空，表示转入账户。
    var toAccount: Account?
    /// 转账时为空。
    var category: Category?

    init(
        amountCents: Int,
        kind: EntryKind,
        date: Date = .now,
        note: String = "",
        account: Account? = nil,
        toAccount: Account? = nil,
        category: Category? = nil
    ) {
        self.amountCents = amountCents
        self.kindRaw = kind.rawValue
        self.date = date
        self.note = note
        self.createdAt = .now
        self.account = account
        self.toAccount = toAccount
        self.category = category
    }

    var kind: EntryKind {
        get { EntryKind(rawValue: kindRaw) ?? .expense }
        set { kindRaw = newValue.rawValue }
    }
}
