//
//  ScreenCutApp.swift
//  ScreenCut
//
//  Created by helinyu on 2024/10/25.
//

import SwiftUI
import AppKit
import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    static let selectedAreaCut = Self("selectedAreaCut")
    static let fullScreenCut = Self("fullScreenCut")
}

@main
struct ScreenCutApp: App {
    
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    init() {
        // 设置激活策略为 accessory
        NSApplication.shared.setActivationPolicy(.accessory)
    }
    
    var body: some Scene {
        // 直接使用MenuBar 替代掉主窗口
        MenuBarExtra("", systemImage: "scissors"){
            MenuBarContentView()
        }

        // SwiftUI 原生的设置窗口
        Settings {
            PreferenceSettingsView()
                .frame(width: 560, height: 500)
        }

        // SwiftUI 原生的关于窗口
        WindowGroup("关于", id: "about") {
            AboutView()
                .frame(width: 540, height: 200)
        }
    }
}

extension Scene {
    func myWindowIsContentResizable() -> some Scene {
        if #available(macOS 13.0, *) {
            return self.windowResizability(.contentSize)
        }
        else {
            return self
        }
    }
}

// 菜单栏内容，使用 SwiftUI 的 openSettings/openWindow 打开设置与关于窗口
private struct MenuBarContentView: View {
    @Environment(\.openWindow) private var openWindow
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        Button("截屏") {
            ScreenCut.saveScreenFullImage()
        }
        .padding()
        Button("选择截屏") {
            NSCursor.crosshair.set()
            ScreenshotWindow().makeKeyAndOrderFront(nil)
        }
        Divider()
        Button("偏好设置") {
            if #available(macOS 13.0, *) {
                openSettings()
            } else {
                let controller = PreferenceSettingsViewController()
                controller.showWindow(nil)
            }
        }
        .padding()
        Button("关于"){
            if #available(macOS 13.0, *) {
                openWindow(id: "about")
            } else {
                let controller = AboutWindowController()
                controller.showWindow(nil)
            }
        }
        .padding()
        Divider()
        Button("退出") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("Q", modifiers: [.command])
    }
}
