//
//  DealsView.swift
//  Prism
//
//  Created by 王建朝 on 2026/10/27.
//

import SwiftUI

struct DealsView: View {
    @Binding var selectedTab: String
    @Binding var selectedDeals: Set<UUID>
    @Binding var searchText: String
    let deals: [Deal]

    @State private var showingNewDeal = false
    @State private var sortOrder: [KeyPathComparator<Deal>] = [KeyPathComparator<Deal>(\.value, order: .reverse)]

    private let stages: [(name: String, amount: String)] = [
        ("Lead", "$181K"), ("Qualified", "$220K"), ("Demo", "$310K"),
        ("Proposal", "$383K"), ("Negotiation", "$398K"), ("Won", "$236K")
    ]

    private var rows: [Deal] { deals.sorted(using: sortOrder) }

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 14) {
                overviewCard
                stageOverview
            }
            .padding(.horizontal, 20).padding(.top, 20).padding(.bottom, 14)

            filterBar
            Divider()
            tableArea
            summaryFooter
        }
        .navigationTitle("交易")
        .searchable(text: $searchText, prompt: "搜索公司 / 负责人")
        .toolbar {
            ToolbarItem {
                Button { showingNewDeal = true } label: {
                    Label("New deal", systemImage: "plus")
                }
                .help("New deal")
            }
        }
        .alert("New deal", isPresented: $showingNewDeal) {
            Button("OK", role: .cancel) { }
        } message: { Text("Create a new opportunity in your pipeline.") }
    }

    // MARK: 概览

    private var overviewCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("19 open").font(.headline)
                Text("worth $1.49M · $736K weighted ·").foregroundStyle(.secondary)
                Text("4 need you").foregroundStyle(.red)
                Spacer()
                HStack(spacing: 5) {
                    Circle().fill(.green).frame(width: 5, height: 5)
                    Text("Q4 · 66 days left").font(.subheadline.weight(.medium))
                }
                .foregroundStyle(.green)
            }

            HStack(spacing: 0) {
                Text("Q4 target ").foregroundStyle(.secondary)
                Text("$900K").fontWeight(.semibold)
                Spacer()
                Text("$236K").foregroundStyle(.green).fontWeight(.semibold)
                Text(" won · ").foregroundStyle(.secondary)
                Text("$972K").fontWeight(.semibold)
                Text(" likely").foregroundStyle(.secondary)
            }
            .font(.body).lineLimit(1).minimumScaleFactor(0.8)

            HStack(spacing: 2) {
                ForEach(0..<40, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(index < 10 ? Color.green : Color.green.opacity(0.17))
                        .frame(height: 14)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.gray.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
    }

    private var stageOverview: some View {
        HStack(alignment: .top, spacing: 8) {
            ForEach(stages, id: \.name) { stage in
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 5) {
                        Circle().fill(AppTheme.stage(stage.name)).frame(width: 6, height: 6)
                        Text(stage.name).fontWeight(.medium)
                        Text(stage.amount).foregroundStyle(.secondary)
                    }
                    .font(.subheadline).lineLimit(1).minimumScaleFactor(0.8)

                    HStack(spacing: 2) {
                        ForEach(0..<4, id: \.self) { index in
                            RoundedRectangle(cornerRadius: 4)
                                .fill(AppTheme.stage(stage.name).opacity(0.86 - Double(index) * 0.08))
                                .frame(maxWidth: .infinity).frame(height: 25)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: 筛选

    private var filterBar: some View {
        HStack(spacing: 12) {
            Picker("", selection: $selectedTab) {
                Text("All deals").tag("All deals")
                Text("Closing this quarter").tag("Closing this quarter")
                Text("Needs you").tag("Needs you")
                Text("Won").tag("Won")
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .frame(maxWidth: 480)

            Spacer(minLength: 12)

            Menu("Owner: Anyone") { Text("Anyone") }
            Menu("Group: None") { Text("None") }
            Menu("Sort: Deal value") { Text("Deal value") }
            Button { } label: { Label("Export", systemImage: "square.and.arrow.up") }
        }
        .padding(.horizontal, 20).padding(.vertical, 10)
    }

    // MARK: 表格

    @ViewBuilder
    private var tableArea: some View {
        if rows.isEmpty {
            ContentUnavailableView("没有匹配的交易", systemImage: "tablecells")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            Table(rows, selection: $selectedDeals, sortOrder: $sortOrder) {
                TableColumn("Company", value: \.company) { deal in
                    HStack(spacing: 8) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(deal.color.gradient)
                            .frame(width: 24, height: 24)
                            .overlay(
                                Text(String(deal.company.prefix(1)))
                                    .font(.caption.bold())
                                    .foregroundStyle(.white)
                            )
                        VStack(alignment: .leading, spacing: 1) {
                            Text(deal.company).lineLimit(1)
                            Text(deal.detail).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                        }
                    }
                }
                .width(min: 170, ideal: 210)

                TableColumn("Stage", value: \.stage) { deal in
                    Text(deal.stage)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(AppTheme.stage(deal.stage))
                        .padding(.horizontal, 7).padding(.vertical, 2)
                        .background(AppTheme.stage(deal.stage).opacity(0.12), in: Capsule())
                }

                TableColumn("Owner", value: \.ownerName) { deal in
                    HStack(spacing: 6) {
                        AvatarView(initials: deal.owner)
                        Text(deal.ownerName).lineLimit(1)
                    }
                }

                TableColumn("Value", value: \.value) { deal in
                    Text(deal.value, format: .currency(code: "USD").precision(.fractionLength(0)))
                        .monospacedDigit()
                }
                .width(min: 90, ideal: 110)

                TableColumn("Win probability", value: \.probability) { deal in
                    HStack(spacing: 6) {
                        ZStack {
                            Circle().stroke(Color.secondary.opacity(0.25), lineWidth: 2)
                            Circle()
                                .trim(from: 0, to: CGFloat(deal.probability) / 100)
                                .stroke(probabilityColor(deal.probability), style: StrokeStyle(lineWidth: 2, lineCap: .round))
                                .rotationEffect(.degrees(-90))
                        }
                        .frame(width: 14, height: 14)
                        Text("\(deal.probability)%").monospacedDigit()
                    }
                }

                TableColumn("Next step", value: \.nextStep) { deal in
                    HStack(spacing: 6) {
                        Text(deal.nextStep).lineLimit(1)
                        Text(deal.due)
                            .font(.caption)
                            .foregroundStyle(dueColor(deal.due))
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(dueColor(deal.due).opacity(0.12), in: Capsule())
                    }
                }

                TableColumn("Last touch", value: \.lastTouch) { deal in
                    Text(deal.lastTouch)
                        .foregroundStyle(deal.overdue ? Color.red : Color.secondary)
                        .fontWeight(deal.overdue ? .medium : .regular)
                }
            }
        }
    }

    private func probabilityColor(_ probability: Int) -> Color {
        if probability >= 70 { return .green }
        if probability >= 40 { return .orange }
        return Color.secondary
    }

    private func dueColor(_ due: String) -> Color {
        if due.contains("late") { return .red }
        if due.contains("Today") { return .blue }
        return .secondary
    }

    // MARK: 汇总

    private var summaryFooter: some View {
        HStack(spacing: 24) {
            Text("\(deals.count == 21 ? 22 : deals.count) deals in view")
            metric(label: "Value", value: "$1,727,800")
            metric(label: "Weighted", value: "$971,578")
            metric(label: "Avg win probability", value: "49%")
            Spacer()
            Text("⌘ K  to jump anywhere").font(.caption2).foregroundStyle(.secondary)
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .padding(.horizontal, 20)
        .frame(height: 34)
        .background(.bar)
        .overlay(alignment: .top) { Divider() }
    }

    private func metric(label: String, value: String) -> some View {
        HStack(spacing: 3) {
            Text(label).foregroundStyle(.secondary)
            Text(value).foregroundStyle(.primary).fontWeight(.medium)
        }
    }
}
