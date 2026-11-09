//
//  Account.swift
//  Money
//
//  Created by 王建朝 on 2026/11/6.
//

import Foundation
import SwiftData

enum AccountKind: String, Codable, CaseIterable, Identifiable {
    case cash
    case bankCard
    case alipay
    case wechat
    case creditCard

    var id: String { rawValue }

    var title: String {
        switch self {
        case .cash: "现金"
        case .bankCard: "银行卡"
        case .alipay: "支付宝"
        case .wechat: "微信"
        case .creditCard: "信用卡"
        }
    }

    var symbol: String {
        switch self {
        case .cash: "banknote"
        case .bankCard: "creditcard"
        case .alipay: "a.circle"
        case .wechat: "message"
        case .creditCard: "creditcard.fill"
        }
    }
}

@Model
final class Account {
    var name: String
    var kindRaw: String
    var openingBalanceCents: Int
    var sortOrder: Int

    init(name: String, kind: AccountKind, openingBalanceCents: Int = 0, sortOrder: Int = 0) {
        self.name = name
        self.kindRaw = kind.rawValue
        self.openingBalanceCents = openingBalanceCents
        self.sortOrder = sortOrder
    }

    var kind: AccountKind {
        get { AccountKind(rawValue: kindRaw) ?? .cash }
        set { kindRaw = newValue.rawValue }
    }
}
