//
//  ContentView.swift
//  Uninstall CommandPost
//
//  Created by Chris Hocking on 20/2/2026.
//

import SwiftUI
import AppKit

struct ContentView: View {
    @State private var isUninstalling = false
    @State private var hasRunUninstall = false
    @State private var uninstallIssues: [String] = []
    private let commandPostPaths = [
        "/Applications/CommandPost.app",
        ("~/Applications/CommandPost.app" as NSString).expandingTildeInPath
    ]

    var body: some View {
        VStack(spacing: 18) {
            Image(nsImage: displayedIcon)
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(width: 96, height: 96)

            Text("Uninstall CommandPost")
                .font(.title2.weight(.semibold))

            Text("Completely remove CommandPost, including all user preferences and support files.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .frame(maxWidth: 420)

            HStack(spacing: 12) {
                Button("Uninstall CommandPost", role: .destructive) {
                    runUninstall()
                }
                .disabled(isUninstalling)

                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
            }

            if isUninstalling {
                ProgressView("Uninstalling...")
                    .controlSize(.small)
                    .padding(.top, 6)
            }

            if hasRunUninstall && !isUninstalling {
                Group {
                    if uninstallIssues.isEmpty {
                        Text("CommandPost has been successfully uninstalled.")
                    } else {
                        Text("Uninstall finished with some issues:")
                        Text(uninstallIssues.joined(separator: "\n"))
                            .font(.caption)
                    }
                }
                .multilineTextAlignment(.center)
                .frame(maxWidth: 440)
            }
        }
        .padding(24)
        .frame(width: 520, height: 340)
    }

    private var displayedIcon: NSImage {
        for path in commandPostPaths where FileManager.default.fileExists(atPath: path) {
            return NSWorkspace.shared.icon(forFile: path)
        }

        return NSApplication.shared.applicationIconImage
    }

    private func runUninstall() {
        isUninstalling = true
        hasRunUninstall = false
        uninstallIssues = []

        Task {
            let issues = await Task.detached(priority: .userInitiated) {
                CommandPostUninstaller.run()
            }.value

            await MainActor.run {
                uninstallIssues = issues
                isUninstalling = false
                hasRunUninstall = true
            }
        }
    }
}

private enum CommandPostUninstaller {
    nonisolated static func run() -> [String] {
        var issues: [String] = []

        runCommand(
            executable: "/usr/bin/killall",
            arguments: ["CommandPost"],
            ignoreFailure: true,
            issues: &issues
        )

        trashIfExists("~/Applications/CommandPost.app", issues: &issues)
        trashIfExists("/Applications/CommandPost.app", issues: &issues)

        runCommand(
            executable: "/usr/bin/osascript",
            arguments: ["-e", #"tell application "System Events" to delete login item "CommandPost""#],
            ignoreFailure: true,
            issues: &issues
        )

        runCommand(
            executable: "/usr/bin/defaults",
            arguments: ["delete", expandedPath("~/Library/Preferences/org.latenitefilms.CommandPost.plist")],
            ignoreFailure: true,
            issues: &issues
        )

        trashIfExists("~/Library/Preferences/org.latenitefilms.CommandPost.plist", issues: &issues)
        trashIfExists("~/Library/Application Support/CommandPost", issues: &issues)
        trashIfExists("~/Library/Application Support/org.latenitefilms.CommandPost", issues: &issues)
        trashIfExists("~/Library/Caches/org.latenitefilms.CommandPost", issues: &issues)
        trashIfExists("~/Library/WebKit/org.latenitefilms.CommandPost", issues: &issues)
        trashIfExists("~/Library/Caches/io.fabric.sdk.mac.data/org.latenitefilms.CommandPost", issues: &issues)
        trashIfExists("~/Library/Caches/com.crashlytics.data/org.latenitefilms.CommandPost", issues: &issues)
        trashIfExists("~/Library/Caches/com.apple.nsurlsessiond/Downloads/org.latenitefilms.CommandPost", issues: &issues)

        trashIfExists("/usr/local/bin/cmdpost", issues: &issues)

        runCommand(
            executable: "/usr/bin/tccutil",
            arguments: ["reset", "All", "org.latenitefilms.CommandPost"],
            ignoreFailure: true,
            issues: &issues
        )

        return issues
    }

    nonisolated private static func trashIfExists(_ path: String, issues: inout [String]) {
        let destination = expandedPath(path)
        guard FileManager.default.fileExists(atPath: destination) else {
            return
        }

        do {
            let destinationURL = URL(fileURLWithPath: destination)
            try FileManager.default.trashItem(at: destinationURL, resultingItemURL: nil)
        } catch {
            issues.append("Failed to move to Trash (\(destination)): \(error.localizedDescription)")
        }
    }

    nonisolated private static func runCommand(
        executable: String,
        arguments: [String],
        ignoreFailure: Bool,
        issues: inout [String]
    ) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments

        let stderrPipe = Pipe()
        process.standardError = stderrPipe
        process.standardOutput = Pipe()

        do {
            try process.run()
            process.waitUntilExit()

            guard process.terminationStatus == 0 || ignoreFailure == true else {
                let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
                let stderrText = String(decoding: stderrData, as: UTF8.self)
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                let command = ([executable] + arguments).joined(separator: " ")
                let details = stderrText.isEmpty ? "exit code \(process.terminationStatus)" : stderrText
                issues.append("Command failed (\(command)): \(details)")
                return
            }
        } catch {
            guard ignoreFailure == false else {
                return
            }

            let command = ([executable] + arguments).joined(separator: " ")
            issues.append("Unable to run command (\(command)): \(error.localizedDescription)")
        }
    }

    nonisolated private static func expandedPath(_ path: String) -> String {
        (path as NSString).expandingTildeInPath
    }
}

#Preview {
    ContentView()
}
