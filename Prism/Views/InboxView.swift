//
//  InboxView.swift
//  Prism
//
//  Created by 王建朝 on 2026/10/27.
//

import SwiftUI

struct InboxListView: View {
    @Binding var selection: InboxConversation.ID?
    @Binding var searchText: String
    let conversations: [InboxConversation]

    var body: some View {
        List(conversations, selection: $selection) { conversation in
            row(conversation)
                .badge(conversation.unread)
                .tag(conversation.id)
        }
        .safeAreaInset(edge: .top) { askPill }
        .navigationTitle("Inbox")
        .searchable(text: $searchText, prompt: "搜索")
        .toolbar {
            ToolbarItem {
                Button { } label: {
                    Label("新建会话", systemImage: "plus")
                }
                .help("新建会话")
            }
        }
    }

    private func row(_ conversation: InboxConversation) -> some View {
        HStack(spacing: 10) {
            Image(systemName: conversation.symbol)
                .font(.title3)
                .foregroundStyle(conversation.tint)
                .frame(width: 26)
            VStack(alignment: .leading, spacing: 2) {
                Text(conversation.title).font(.body.weight(.medium)).lineLimit(1)
                Text(conversation.preview).font(.caption).foregroundStyle(.secondary).lineLimit(1)
            }
            Spacer(minLength: 6)
            Text(conversation.time).font(.caption).foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }

    private var askPill: some View {
        HStack(spacing: 8) {
            Circle().stroke(Color.accentColor, lineWidth: 2).frame(width: 12, height: 12)
            Text("问大圆：总结未读消息").font(.subheadline).lineLimit(1)
            Spacer(minLength: 0)
            Image(systemName: "chevron.right").font(.caption2.weight(.semibold)).foregroundStyle(.secondary)
        }
        .padding(.horizontal, 11).frame(height: 30)
        .background(Color.gray.opacity(0.12), in: Capsule())
        .padding(.horizontal, 12).padding(.vertical, 6)
    }
}

struct InboxDetailView: View {
    let conversation: InboxConversation?

    var body: some View {
        Group {
            if let conversation {
                VStack(spacing: 0) {
                    ScrollView {
                        VStack(spacing: 10) {
                            Text(conversation.preview)
                                .padding(12)
                                .background(AppTheme.controlBackground, in: RoundedRectangle(cornerRadius: 12))
                            Text("会话内容将在这里显示")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(20)
                    }
                    Divider()
                    HStack(spacing: 16) {
                        Image(systemName: "face.smiling")
                        Image(systemName: "paperclip")
                        Spacer()
                        Image(systemName: "mic")
                    }
                    .foregroundStyle(.secondary)
                    .padding(14)
                }
                .navigationTitle(conversation.title)
                .navigationSubtitle("群聊 · Northwind Sales")
                .toolbar {
                    ToolbarItemGroup {
                        Button { } label: { Image(systemName: "magnifyingglass") }
                        Button { } label: { Image(systemName: "phone") }
                        Button { } label: { Image(systemName: "ellipsis") }
                    }
                }
            } else {
                ContentUnavailableView("选择会话", systemImage: "bubble.left.and.bubble.right")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
