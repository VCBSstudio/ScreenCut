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
    
    @StateObject private var swiftUIAppDelegate = SwiftUIAppDelegate.shared
    
    init() {
        // 设置激活策略为 accessory
        NSApplication.shared.setActivationPolicy(.accessory)
        
        // 初始化 SwiftUI AppDelegate
        swiftUIAppDelegate.applicationDidFinishLaunching()
    }
    
    var body: some Scene {
//         直接使用MenuBar 替代掉主窗口
        MenuBarExtra("", systemImage: "scissors"){
            Button("截屏") {
                ScreenCut.saveScreenFullImage()
            }
            .padding()
            Button("选择截屏") {
                NSCursor.crosshair.set()
                ScreenshotManager.shared.showScreenshotWindow()
            }
            Divider()
            Button("偏好设置") {
                PureSwiftUIPreferencesWindowController().showPreferencesWindow()
            }
            .padding()
            Button("关于"){
                PureSwiftUIAboutWindowController().showAboutWindow()
            }
            .padding()
            Divider()
            Button("退出") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("Q", modifiers: [.command])
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
