//
//  SkillItem.swift
//  Prism
//
//  Created by 王建朝 on 2026/10/27.
//

import Foundation

struct SkillItem: Identifiable {
    let path: String
    let name: String
    let description: String
    let contents: String
    let tool: String
    var id: String { path }
}
