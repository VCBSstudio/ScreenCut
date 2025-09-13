//
//  AreaSelector.swift
//  VCB
//
//  Created by helinyu on 2024/10/23.
//


import Foundation
import SwiftUI
import ScreenCaptureKit
import AppKit
import KeyboardShortcuts
import Sparkle

var defaultSavepath:String = "";

extension NSScreen {
    var displayID: CGDirectDisplayID? {
        return deviceDescription[NSDeviceDescriptionKey(rawValue: "NSScreenNumber")] as? CGDirectDisplayID
    }
}

extension SCDisplay {
    var nsScreen: NSScreen? {
        return NSScreen.screens.first(where: { $0.displayID == self.displayID })
    }
}

class AppDelegate : NSObject, NSApplicationDelegate {
    
    
    var screentId: CGDirectDisplayID?
    
    var isResizing = false
    static let shared = AppDelegate()
    var updaterController: SPUStandardUpdaterController! // 更新
    
    @AppStorage(kSelectedSavePath) private var selectedPath: String = defaultSavepath
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        
        Task {
            await ScreenCut.updateScreenContent()
        }
        
        defaultSavepath = VarExtension.createTargetDirIfNotExit() // 先创建目录
        if (self.selectedPath.count == 0) {
            self.selectedPath = defaultSavepath
        }
//        print("lt --- selctePath: \(self.selectedPath)")
        
        KeyboardShortcuts.onKeyDown(for: .selectedAreaCut) {[] in
            NSCursor.crosshair.set()
            ScreenshotWindow().makeKeyAndOrderFront(nil)
        }
        
        updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: self, userDriverDelegate: self)
        NotificationCenter.default.addObserver(self, selector: #selector(onCheckUpdate), name: Notification.Name("update.app.noti"), object: nil)
        
        
//        这个暂时先不处理
//        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
//            //            let captureHelper = ScreenCaptureHelper()
//            //            captureHelper.startCapturing(scrollHeight: 600, screenWidth: 1400, screenHeight: 3000)
//            
//            
//            Task {
//                let desktopURL = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first!
//                let outputURL = desktopURL.appendingPathComponent("ScreenRecording.mov")
//                let capture = ScreenRecorder()
//                await capture.startRecording(outputURL: outputURL)
//                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
//                    capture.stopRecording()
//                }
//            }                
//        }
      
       
    }
    
    @objc func onCheckUpdate(noti: Notification) {
        updaterController.checkForUpdates(self)
    }
}

// 有关的代理方法
extension AppDelegate: SPUUpdaterDelegate, SPUStandardUserDriverDelegate {
    
    func updater(_ updater: SPUUpdater, didExtractUpdate item: SUAppcastItem) {
        
    }
    
    func updater(_ updater: SPUUpdater, mayPerform updateCheck: SPUUpdateCheck) throws {
        
    }
    
    func updater(_ updater: SPUUpdater, willExtractUpdate item: SUAppcastItem) {
        
    }
    
    func updater(_ updater: SPUUpdater, didFinishUpdateCycleFor updateCheck: SPUUpdateCheck, error: (any Error)?) {
        
    }
}
