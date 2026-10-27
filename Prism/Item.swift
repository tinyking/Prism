//
//  Item.swift
//  Prism
//
//  Created by 王建朝 on 2026/10/27.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
