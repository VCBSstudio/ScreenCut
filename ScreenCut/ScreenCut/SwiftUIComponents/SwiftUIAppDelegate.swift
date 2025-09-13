//
//  SwiftUIAppDelegate.swift
//  ScreenCut
//
//  Created by helinyu on 2024/12/19.
//

import Foundation
import SwiftUI
import ScreenCaptureKit
import KeyboardShortcuts
import Sparkle
import Combine

var defaultSavepath: String = ""

 @MainActor
class SwiftUIAppDelegate: NSObject, ObservableObject {
    static let shared = SwiftUIAppDelegate()
    
    var screentId: CGDirectDisplayID?
    var isResizing = false
    var updaterController: SPUStandardUpdaterController!
    
    @AppStorage(kSelectedSavePath) private var selectedPath: String = defaultSavepath
    
    private var cancellables = Set<AnyCancellable>()
    
    private override init() {}
    
    func applicationDidFinishLaunching() {
        Task {
            await ScreenCut.updateScreenContent()
        }
        
        defaultSavepath = VarExtension.createTargetDirIfNotExit()
        if self.selectedPath.count == 0 {
            self.selectedPath = defaultSavepath
        }
        
        // Setup keyboard shortcuts
        KeyboardShortcuts.onKeyDown(for: .selectedAreaCut) { [] in
            NSCursor.crosshair.set()
            ScreenshotManager.shared.showScreenshotWindow()
        }
        
        // Setup updater
        updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: self, userDriverDelegate: self)
        NotificationCenter.default.addObserver(self, selector: #selector(onCheckUpdate), name: Notification.Name("update.app.noti"), object: nil)
    }
    
    @objc func onCheckUpdate(noti: Notification) {
        updaterController.checkForUpdates(self)
    }
}

// MARK: - SPUUpdaterDelegate, SPUStandardUserDriverDelegate
extension SwiftUIAppDelegate: @preconcurrency SPUUpdaterDelegate, @preconcurrency SPUStandardUserDriverDelegate {
    nonisolated func updater(_ updater: SPUUpdater, didExtractUpdate item: SUAppcastItem) {
        
    }
    
    nonisolated func updater(_ updater: SPUUpdater, mayPerform updateCheck: SPUUpdateCheck) throws {
        
    }
    
    nonisolated func updater(_ updater: SPUUpdater, willExtractUpdate item: SUAppcastItem) {
        
    }
    
    nonisolated func updater(_ updater: SPUUpdater, didFinishUpdateCycleFor updateCheck: SPUUpdateCheck, error: (any Error)?) {
        
    }
}
