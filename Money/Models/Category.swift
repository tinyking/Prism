//
//  Category.swift
//  Money
//
//  Created by 王建朝 on 2026/11/6.
//

import Foundation
import SwiftData

enum CategoryKind: String, Codable, CaseIterable, Identifiable {
    case expense
    case income

    var id: String { rawValue }

    var title: String {
        switch self {
        case .expense: "支出"
        case .income: "收入"
        }
    }
}

@Model
final class Category {
    var name: String
    var kindRaw: String
    var symbol: String
    var sortOrder: Int

    init(name: String, kind: CategoryKind, symbol: String, sortOrder: Int = 0) {
        self.name = name
        self.kindRaw = kind.rawValue
        self.symbol = symbol
        self.sortOrder = sortOrder
    }

    var kind: CategoryKind {
        get { CategoryKind(rawValue: kindRaw) ?? .expense }
        set { kindRaw = newValue.rawValue }
    }
}
