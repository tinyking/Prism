//
//  SkillStore.swift
//  Prism
//
//  Created by 王建朝 on 2026/10/27.
//

import Foundation
import Observation

@Observable
final class SkillStore {
    var skills: [SkillItem] = []
    var isLoaded = false
    var isScanning = false
    var message: String?

    func scanIfNeeded() {
        guard !isLoaded else { return }
        scan()
    }

    func scan() {
        guard !isScanning else { return }
        isScanning = true
        defer { isScanning = false; isLoaded = true }
        let homeURL = FileManager.default.homeDirectoryForCurrentUser
        skills = SkillScanner.scan(home: homeURL, project: SkillScanner.projectRoot)
        message = skills.isEmpty ? "No SKILL.md files were found in the supported skill folders." : nil
    }
}
