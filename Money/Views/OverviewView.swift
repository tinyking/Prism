//
//  OverviewView.swift
//  Money
//
//  Created by 王建朝 on 2026/11/6.
//

import SwiftUI
import SwiftData

struct OverviewView: View {
    @Query(sort: \Account.sortOrder) private var accounts: [Account]
    @Query private var entries: [Entry]

    private var currentInterval: DateInterval {
        Calendar.current.dateInterval(of: .month, for: Date())
            ?? DateInterval(start: Date(), duration: 0)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                netWorthCard
                monthCard
                accountsCard
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle("概览")
    }

    private var netWorthCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("净资产").font(.subheadline).foregroundStyle(.secondary)
            Text(LedgerMath.currency(LedgerMath.netWorth(accounts, entries: entries)))
                .font(.system(size: 40, weight: .semibold, design: .rounded))
                .monospacedDigit()
            Text("共 \(accounts.count) 个账户").font(.caption).foregroundStyle(.secondary)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.gray.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
    }

    private var monthCard: some View {
        let summary = LedgerMath.monthSummary(entries, in: currentInterval)
        return VStack(alignment: .leading, spacing: 12) {
            Text("本月").font(.headline)
            HStack(spacing: 28) {
                statItem("收入", LedgerMath.currency(summary.incomeCents), .green)
                statItem("支出", LedgerMath.currency(summary.expenseCents), .red)
                statItem("结余", LedgerMath.currency(summary.netCents), summary.netCents >= 0 ? .green : .red)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.gray.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
    }

    private func statItem(_ title: String, _ value: String, _ color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.system(size: 18, weight: .medium)).foregroundStyle(color).monospacedDigit()
        }
    }

    private var accountsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("账户").font(.headline)
            if accounts.isEmpty {
                Text("还没有账户。").foregroundStyle(.secondary)
            } else {
                ForEach(accounts) { account in
                    HStack(spacing: 12) {
                        Image(systemName: account.kind.symbol)
                            .frame(width: 24)
                            .foregroundStyle(.secondary)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(account.name)
                            Text(account.kind.title).font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(LedgerMath.currency(LedgerMath.balance(of: account, in: entries)))
                            .monospacedDigit()
                    }
                    if account.id != accounts.last?.id {
                        Divider()
                    }
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.gray.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
    }
}
