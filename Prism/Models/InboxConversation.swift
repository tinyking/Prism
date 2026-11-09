//
//  InboxConversation.swift
//  Prism
//
//  Created by 王建朝 on 2026/10/27.
//

import SwiftUI

struct InboxConversation: Identifiable {
    let id: Int
    let title: String
    let preview: String
    let time: String
    let symbol: String
    let tint: Color
    let unread: Int

    static let samples: [InboxConversation] = [
        .init(id: 1, title: "活动计算核心团队", preview: "李强：@Leon，会议纪要已更新", time: "星期五", symbol: "person.3.fill", tint: AppTheme.Accent.blue, unread: 2),
        .init(id: 2, title: "数字科技中心 · 创造星营", preview: "刘振源：下周安排同步一下", time: "星期五", symbol: "person.3.fill", tint: AppTheme.Accent.purple, unread: 0),
        .init(id: 3, title: "工程技术-渠道组", preview: "张建利：收到，我来跟进", time: "星期五", symbol: "person.3.fill", tint: AppTheme.Accent.amber, unread: 0),
        .init(id: 4, title: "技术服务专项沟通", preview: "贾云飞：会议纪要同步完成", time: "星期四", symbol: "person.3.fill", tint: AppTheme.Accent.green, unread: 0),
        .init(id: 5, title: "专题 5：技术管理 Agent", preview: "刘阳：@所有人 请查看方案", time: "星期四", symbol: "person.3.fill", tint: AppTheme.Accent.red, unread: 5),
        .init(id: 6, title: "文件传输助手", preview: "[文件] 销售团队周报.xlsx", time: "星期三", symbol: "folder.fill", tint: AppTheme.Accent.green, unread: 0),
        .init(id: 7, title: "福利社产品、卡券技术对接", preview: "刘晓娜：接口文档在群里", time: "10/21", symbol: "person.3.fill", tint: AppTheme.Accent.blue, unread: 0),
        .init(id: 8, title: "码激活预警群", preview: "[9035条] 码激活预警提醒", time: "1分钟前", symbol: "person.3.fill", tint: AppTheme.Accent.red, unread: 1),
        .init(id: 9, title: "主数据监控预警", preview: "[466条] 主数据服务异常", time: "13分钟前", symbol: "person.3.fill", tint: AppTheme.Accent.amber, unread: 1),
        .init(id: 10, title: "折叠的聊天", preview: "SIP-I-智能线上问题：…", time: "17分钟前", symbol: "bubble.left.and.bubble.right.fill", tint: AppTheme.Accent.blue, unread: 0),
        .init(id: 11, title: "前沿技术探索交流群", preview: "IT科技前沿日报已发布", time: "21分钟前", symbol: "person.3.fill", tint: AppTheme.Accent.purple, unread: 6),
        .init(id: 12, title: "行业资讯", preview: "同事们在看《专访》…", time: "27分钟前", symbol: "newspaper.fill", tint: AppTheme.Accent.amber, unread: 4)
    ]
}
