//
//  SkillScanner.swift
//  Prism
//
//  Created by 王建朝 on 2026/10/27.
//

import Foundation

enum SkillScanner {
    private struct Source {
        let tool: String
        let globalPaths: [String]
        let projectPaths: [String]
    }

    private static let sources: [Source] = [
        .init(tool: "Claude Code", globalPaths: [".claude/skills"], projectPaths: [".claude/skills"]),
        .init(tool: "Codex", globalPaths: [".codex/skills", ".agents/skills"], projectPaths: [".codex/skills", ".agents/skills"]),
        .init(tool: "Cursor", globalPaths: [".cursor/skills"], projectPaths: [".cursor/skills", ".agents/skills"]),
        .init(tool: "WorkBuddy", globalPaths: [".workbuddy/skills"], projectPaths: [".workbuddy/skills"]),
        .init(tool: "Trae 国际版", globalPaths: [".trae/skills"], projectPaths: [".trae/skills"]),
        .init(tool: "Trae CN", globalPaths: [".trae-cn/skills"], projectPaths: []),
        .init(tool: "Kimi", globalPaths: [".config/agents/skills"], projectPaths: []),
        .init(tool: "CodeBuddy", globalPaths: [".codebuddy/skills"], projectPaths: [".codebuddy/skills"]),
        .init(tool: "Comate", globalPaths: [".comate/skills"], projectPaths: []),
        .init(tool: "Qoder", globalPaths: [".qoderwork/skills", ".qoder-cn/skills"], projectPaths: []),
        .init(tool: "AutoClaw", globalPaths: [".openclaw/skills"], projectPaths: [])
    ]

    static var projectRoot: URL {
        var url = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
        while url.path != "/" {
            if FileManager.default.fileExists(atPath: url.appendingPathComponent("Prism.xcodeproj").path) { return url }
            url.deleteLastPathComponent()
        }
        return URL(fileURLWithPath: #filePath).deletingLastPathComponent()
    }

    static func scan(home: URL, project: URL) -> [SkillItem] {
        let fileManager = FileManager.default
        var results: [SkillItem] = []

        for source in sources {
            let roots = source.globalPaths.map { home.appendingPathComponent($0, isDirectory: true) }
                + source.projectPaths.map { project.appendingPathComponent($0, isDirectory: true) }

            for root in roots {
                guard let folders = try? fileManager.contentsOfDirectory(
                    at: root,
                    includingPropertiesForKeys: [.isDirectoryKey],
                    options: [.skipsHiddenFiles]
                ) else { continue }

                for folder in folders {
                    let manifest = folder.appendingPathComponent("SKILL.md")
                    guard let contents = try? String(contentsOf: manifest, encoding: .utf8) else { continue }
                    let fields = parse(contents)
                    let name = fields.name ?? folder.lastPathComponent
                    let description = fields.description ?? "No description provided."
                    results.append(SkillItem(path: manifest.standardizedFileURL.path, name: name, description: description, contents: contents, tool: source.tool))
                }
            }
        }

        var seen = Set<String>()
        return results.filter { seen.insert("\($0.path)|\($0.tool)").inserted }
            .sorted { ($0.name.localizedCaseInsensitiveCompare($1.name) == .orderedSame ? $0.tool < $1.tool : $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending) }
    }

    private static func parse(_ contents: String) -> (name: String?, description: String?) {
        let lines = contents.components(separatedBy: .newlines)
        var name: String?
        var description: String?
        var inFrontMatter = false
        var frontMatterEnded = false
        var multilineDescription = false
        var descriptionLines: [String] = []

        for (index, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if index == 0 && trimmed == "---" { inFrontMatter = true; continue }
            if inFrontMatter && trimmed == "---" { inFrontMatter = false; frontMatterEnded = true; continue }
            if inFrontMatter {
                if multilineDescription {
                    if line.hasPrefix(" ") || line.hasPrefix("\t") {
                        descriptionLines.append(trimmed)
                        continue
                    }
                    description = descriptionLines.joined(separator: " ").nilIfEmpty
                    multilineDescription = false
                }
                if let value = yamlValue(for: "name", in: line) { name = value }
                if let value = yamlValue(for: "description", in: line) {
                    if value == ">" || value == "|" || value == ">-" || value == "|-" {
                        multilineDescription = true
                    } else {
                        description = value
                    }
                }
                continue
            }
            if frontMatterEnded && description == nil && !trimmed.isEmpty && !trimmed.hasPrefix("#") {
                description = trimmed
                break
            }
        }
        if description == nil, !descriptionLines.isEmpty { description = descriptionLines.joined(separator: " ").nilIfEmpty }
        return (name, description)
    }

    private static func yamlValue(for key: String, in line: String) -> String? {
        guard line.hasPrefix("\(key):") else { return nil }
        let value = String(line.dropFirst(key.count + 1)).trimmingCharacters(in: .whitespaces)
        guard !value.isEmpty else { return nil }
        if (value.first == "'" && value.last == "'") || (value.first == "\"" && value.last == "\"") {
            return String(value.dropFirst().dropLast())
        }
        return value
    }
}

extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}
