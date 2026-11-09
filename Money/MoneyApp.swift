//
//  MoneyApp.swift
//  Money
//
//  Created by 王建朝 on 2026/11/6.
//

import SwiftUI
import SwiftData

@main
struct MoneyApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Account.self,
            Category.self,
            Entry.self,
        ])

        // 独立存储文件，避免与非沙盒的其它 SwiftData 应用共用 default.store。
        let directory = URL.applicationSupportDirectory.appending(path: "Money", directoryHint: .isDirectory)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let modelConfiguration = ModelConfiguration(schema: schema, url: directory.appending(path: "Money.store"))

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(sharedModelContainer)
    }
}
