//
//  ReportView.swift
//  Money
//
//  Created by 王建朝 on 2026/11/6.
//

import SwiftUI
import SwiftData
import Charts

struct ReportView: View {
    @Query private var entries: [Entry]
    @State private var selectedMonth: Date = Date()

    private let calendar = Calendar.current

    private var months: [Date] {
        guard let start = calendar.dateInterval(of: .month, for: Date())?.start else { return [] }
        return (0..<12).reversed().compactMap {
            calendar.date(byAdding: .month, value: -$0, to: start)
        }
    }

    private var interval: DateInterval {
        calendar.dateInterval(of: .month, for: selectedMonth)
            ?? DateInterval(start: selectedMonth, duration: 0)
    }

    private var summary: MonthSummary {
        LedgerMath.monthSummary(entries, in: interval)
    }

    private var slices: [CategorySlice] {
        LedgerMath.expenseBreakdownByCategory(entries, in: interval)
    }

    private var trend: [MonthStat] {
        months.suffix(6).map { month in
            let monthInterval = calendar.dateInterval(of: .month, for: month)
                ?? DateInterval(start: month, duration: 0)
            let value = LedgerMath.monthSummary(entries, in: monthInterval)
            return MonthStat(
                id: month,
                label: Self.shortFormatter.string(from: month),
                incomeCents: value.incomeCents,
                expenseCents: value.expenseCents
            )
        }
    }

    private static let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月"
        return formatter
    }()

    private static let shortFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "M月"
        return formatter
    }()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Picker("月份", selection: $selectedMonth) {
                    ForEach(months, id: \.self) { month in
                        Text(Self.monthFormatter.string(from: month)).tag(month)
                    }
                }
                .frame(maxWidth: 220)

                summaryRow
                expenseSection
                trendSection
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle("统计")
        .onAppear {
            if let last = months.last { selectedMonth = last }
        }
    }

    private var summaryRow: some View {
        HStack(spacing: 28) {
            statItem("收入", LedgerMath.currency(summary.incomeCents), .green)
            statItem("支出", LedgerMath.currency(summary.expenseCents), .red)
            statItem("结余", LedgerMath.currency(summary.netCents), summary.netCents >= 0 ? .green : .red)
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

    private var expenseSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("支出构成").font(.headline)
            if slices.isEmpty {
                Text("本月还没有支出记录。").foregroundStyle(.secondary)
            } else {
                Chart(slices) { slice in
                    SectorMark(
                        angle: .value("金额", slice.totalCents),
                        innerRadius: .ratio(0.55),
                        angularInset: 1.5
                    )
                    .cornerRadius(4)
                    .foregroundStyle(by: .value("分类", slice.name))
                }
                .frame(height: 220)

                VStack(alignment: .leading, spacing: 6) {
                    ForEach(slices) { slice in
                        HStack {
                            Text(slice.name)
                            Spacer()
                            Text(LedgerMath.currency(slice.totalCents)).monospacedDigit()
                        }
                        .font(.callout)
                    }
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.gray.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
    }

    private var trendSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("近 6 个月").font(.headline)
            Chart {
                ForEach(trend) { stat in
                    BarMark(
                        x: .value("月份", stat.label),
                        y: .value("金额", Double(stat.incomeCents) / 100)
                    )
                    .foregroundStyle(by: .value("类型", "收入"))
                    .position(by: .value("类型", "收入"))

                    BarMark(
                        x: .value("月份", stat.label),
                        y: .value("金额", Double(stat.expenseCents) / 100)
                    )
                    .foregroundStyle(by: .value("类型", "支出"))
                    .position(by: .value("类型", "支出"))
                }
            }
            .frame(height: 220)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.gray.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
    }
}

private struct MonthStat: Identifiable {
    let id: Date
    let label: String
    let incomeCents: Int
    let expenseCents: Int
}
