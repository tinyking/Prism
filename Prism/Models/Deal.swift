//
//  Deal.swift
//  Prism
//
//  Created by 王建朝 on 2026/10/27.
//

import SwiftUI

struct Deal: Identifiable {
    let id = UUID()
    let company, detail, stage, owner, ownerName: String
    let value, probability: Int
    let color: Color
    let nextStep, due, lastTouch: String
    let overdue: Bool
    let closing, needsYou: Bool

    static let samples: [Deal] = [
        .init(company: "Kestrel Logistics", detail: "Logistics · 240 seats", stage: "Negotiation", owner: "JF", ownerName: "Jamie Fox", value: 186000, probability: 82, color: AppTheme.Accent.ink, nextStep: "Redlines back from legal", due: "Today", lastTouch: "Today", overdue: false, closing: true, needsYou: true),
        .init(company: "Mirabel Health", detail: "Healthcare · 420 seats", stage: "Proposal", owner: "SN", ownerName: "Sarah Nguyen", value: 164500, probability: 58, color: AppTheme.Accent.purple, nextStep: "Security review", due: "Wed", lastTouch: "2d ago", overdue: false, closing: true, needsYou: true),
        .init(company: "Tidewell Energy", detail: "Energy · 180 seats", stage: "Demo", owner: "AS", ownerName: "Alex Santos", value: 142000, probability: 41, color: AppTheme.Accent.amber, nextStep: "Technical demo", due: "Thu 14:00", lastTouch: "4d ago", overdue: false, closing: true, needsYou: false),
        .init(company: "Arcfield Robotics", detail: "Manufacturing · 95 seats", stage: "Negotiation", owner: "GM", ownerName: "Grace Miller", value: 128000, probability: 76, color: AppTheme.Accent.red, nextStep: "Pricing call with CFO", due: "Tomorrow", lastTouch: "1d ago", overdue: false, closing: true, needsYou: false),
        .init(company: "Granite Peak Capital", detail: "Finance · 60 seats", stage: "Won", owner: "SN", ownerName: "Sarah Nguyen", value: 118000, probability: 100, color: AppTheme.Accent.green, nextStep: "Kickoff invite sent", due: "Done", lastTouch: "6d ago", overdue: false, closing: true, needsYou: false),
        .init(company: "Bluehaven Insurance", detail: "Insurance · 310 seats", stage: "Proposal", owner: "JF", ownerName: "Jamie Fox", value: 112400, probability: 62, color: AppTheme.Accent.blue, nextStep: "Send revised proposal", due: "2 days late", lastTouch: "9d ago", overdue: false, closing: true, needsYou: true),
        .init(company: "Driftwood Hotels", detail: "Hospitality · 140 seats", stage: "Qualified", owner: "NL", ownerName: "Noah Lee", value: 96000, probability: 24, color: AppTheme.Accent.amber, nextStep: "Discovery call", due: "Fri", lastTouch: "3d ago", overdue: false, closing: false, needsYou: false),
        .init(company: "Lumos Pay", detail: "Fintech · 75 seats", stage: "Demo", owner: "AS", ownerName: "Alex Santos", value: 88500, probability: 44, color: AppTheme.Accent.green, nextStep: "Demo for the risk team", due: "Today 16:30", lastTouch: "1d ago", overdue: false, closing: true, needsYou: true),
        .init(company: "Foxglove Bio", detail: "Biotech · 55 seats", stage: "Negotiation", owner: "GM", ownerName: "Grace Miller", value: 84000, probability: 71, color: AppTheme.Accent.green, nextStep: "Chase signed order form", due: "6 days late", lastTouch: "14d ago", overdue: true, closing: true, needsYou: true),
        .init(company: "Saltmarsh Coffee", detail: "Retail · 48 seats", stage: "Won", owner: "NL", ownerName: "Noah Lee", value: 72000, probability: 100, color: AppTheme.Accent.blue, nextStep: "Onboarding week 2", due: "Thu", lastTouch: "2d ago", overdue: false, closing: false, needsYou: false),
        .init(company: "Juniper Schools", detail: "Education · 600 seats", stage: "Lead", owner: "AS", ownerName: "Alex Santos", value: 68000, probability: 10, color: AppTheme.Accent.blue, nextStep: "Intro from Granite Peak", due: "Today", lastTouch: "5d ago", overdue: false, closing: false, needsYou: false),
        .init(company: "Ironleaf Security", detail: "Security · 130 seats", stage: "Proposal", owner: "SN", ownerName: "Sarah Nguyen", value: 66800, probability: 55, color: AppTheme.Accent.ink, nextStep: "Procurement sync", due: "Mon", lastTouch: "3d ago", overdue: false, closing: true, needsYou: false),
        .init(company: "Oakline Studio", detail: "Agency · 32 seats", stage: "Qualified", owner: "JF", ownerName: "Jamie Fox", value: 54000, probability: 27, color: AppTheme.Accent.purple, nextStep: "Book the demo", due: "This week", lastTouch: "6d ago", overdue: false, closing: false, needsYou: false),
        .init(company: "Marlow Air", detail: "Aviation · 210 seats", stage: "Lead", owner: "GM", ownerName: "Grace Miller", value: 52500, probability: 10, color: AppTheme.Accent.amber, nextStep: "First call", due: "Wed", lastTouch: "11d ago", overdue: true, closing: false, needsYou: true),
        .init(company: "Parallax Systems", detail: "Software · 85 seats", stage: "Demo", owner: "NL", ownerName: "Noah Lee", value: 48000, probability: 38, color: AppTheme.Accent.red, nextStep: "Follow up on demo", due: "4 days late", lastTouch: "12d ago", overdue: true, closing: false, needsYou: true),
        .init(company: "Pinecrest Dental", detail: "Healthcare · 30 seats", stage: "Won", owner: "GM", ownerName: "Grace Miller", value: 46000, probability: 100, color: AppTheme.Accent.green, nextStep: "Welcome pack sent", due: "Done", lastTouch: "3d ago", overdue: false, closing: false, needsYou: false),
        .init(company: "Northgate Utilities", detail: "Energy · 120 seats", stage: "Qualified", owner: "AS", ownerName: "Alex Santos", value: 41000, probability: 30, color: AppTheme.Accent.amber, nextStep: "Discovery call", due: "Mon", lastTouch: "4d ago", overdue: false, closing: false, needsYou: false),
        .init(company: "Quillfeather Media", detail: "Media · 70 seats", stage: "Proposal", owner: "JF", ownerName: "Jamie Fox", value: 39100, probability: 52, color: AppTheme.Accent.purple, nextStep: "Send pricing", due: "Today", lastTouch: "2d ago", overdue: false, closing: true, needsYou: false),
        .init(company: "Orchard & Pine", detail: "Retail · 64 seats", stage: "Lead", owner: "NL", ownerName: "Noah Lee", value: 34000, probability: 12, color: AppTheme.Accent.green, nextStep: "Qualify inbound", due: "Wed", lastTouch: "8d ago", overdue: false, closing: false, needsYou: false),
        .init(company: "Westbrook Clinic", detail: "Healthcare · 45 seats", stage: "Demo", owner: "SN", ownerName: "Sarah Nguyen", value: 31500, probability: 35, color: AppTheme.Accent.blue, nextStep: "Clinical demo", due: "Fri", lastTouch: "2d ago", overdue: false, closing: true, needsYou: false),
        .init(company: "Brightwater Labs", detail: "Biotech · 40 seats", stage: "Qualified", owner: "GM", ownerName: "Grace Miller", value: 29000, probability: 25, color: AppTheme.Accent.ink, nextStep: "Scope call", due: "Thu", lastTouch: "5d ago", overdue: false, closing: false, needsYou: false),
        .init(company: "Copperline Rail", detail: "Logistics · 38 seats", stage: "Lead", owner: "AS", ownerName: "Alex Santos", value: 26500, probability: 10, color: AppTheme.Accent.ink, nextStep: "Intro email", due: "This week", lastTouch: "7d ago", overdue: false, closing: false, needsYou: false)
    ]
}
