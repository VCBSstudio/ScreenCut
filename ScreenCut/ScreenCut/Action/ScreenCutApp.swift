//
//  ScreenCutApp.swift
//  ScreenCut
//
//  Created by helinyu on 2024/10/25.
//

import SwiftUI
import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    static let selectedAreaCut = Self("selectedAreaCut")
    static let fullScreenCut = Self("fullScreenCut")
}

@main
struct ScreenCutApp: App {
    
    @StateObject private var swiftUIAppDelegate = SwiftUIAppDelegate.shared
    @StateObject private var windowManager = PureSwiftUIWindowManager.shared
    @StateObject private var screenshotManager = ScreenshotManager.shared
    
    var body: some Scene {
        // 初始化 SwiftUI AppDelegate
        let _ = swiftUIAppDelegate.applicationDidFinishLaunching()
        
//         直接使用MenuBar 替代掉主窗口
        MenuBarExtra("", systemImage: "scissors"){
            Button("截屏") {
                ScreenCut.saveScreenFullImage()
            }
            .padding()
            Button("选择截屏") {
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
                exit(0)
            }
            .keyboardShortcut("Q", modifiers: [.command])
        }
        
        // Add window scenes for overlay views
        WindowGroup("Screenshot Overlay") {
            if screenshotManager.showScreenshotOverlay {
                ScreenshotOverlayView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.clear)
                    .ignoresSafeArea()
            }
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        
        WindowGroup("Window Overlay") {
            WindowOverlay()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.clear)
                .ignoresSafeArea()
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
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
