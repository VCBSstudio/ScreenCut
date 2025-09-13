//
//  DateExtension.swift
//  TestMacApp
//
//  Created by helinyu on 2024/10/24.
//

import Foundation
import SwiftUI
import FileKit
import ScreenCaptureKit
import Combine
import FileKit

// 通知的类型
extension Notification.Name {
    static let kCutTypeChange = Notification.Name("kCutTypeChange")
    static let kSelectColorTypeChange = Notification.Name("kSelectColorTypeChange")
    static let kDrawSizeTypeChange = Notification.Name("kDrawSizeTypeChange")
    static let kTextSizeTypeChange = Notification.Name("kTextSizeTypeChange")
    static let kDownloadClick = Notification.Name("kDownloadClick")
}

let kplayAudioOfFinished = "playAudioOfFinished"
let ksavePasteboardSameTime = "savePasteboardSameTime"
let konlySaveInPasteBoard = "onlySaveInPasteBoard"
let kautoUpdate = "autoUpdate"
let kautoLaunchByComputer = "autoLaunchByComputer"
let kSelectedSavePath = "kSelectedSavePath1"
let kAutoStartup = "kAutoStartup"



class VarExtension {
    
    static func getTargetName() -> String {
        guard let targetName = Bundle.main.infoDictionary?["CFBundleName"] as? String else {
            return ""
        }
        return targetName
    }
    
    @MainActor static func createTargetDirIfNotExit() -> String {
        let downLoadPath = Path.userDownloads + self.getTargetName()
        self.createDirIfNotExit(downLoadPath.rawValue)
        return downLoadPath.rawValue
    }
    
    @MainActor static func createDirIfNotExit(_ atPath: String) {
        let fileManager = FileManager.default
        var isDirectory: ObjCBool = false
        if fileManager.fileExists(atPath: atPath, isDirectory: &isDirectory) {
            if !isDirectory.boolValue {
                _ = UI.createAlert(title: "Failed to Record", message: "The output path is a file instead of a folder!", button1: "OK").runModal()
                return
            }
        } else {
            do {
                try fileManager.createDirectory(atPath: atPath, withIntermediateDirectories: true, attributes: nil)
            } catch {
                _ = UI.createAlert(title: "Failed to Record", message: "Unable to create output folder!", button1: "OK").runModal()
                return
            }
        }
    }
    
}

extension Date {
    static func getNameByDate() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "y-MM-dd HH.mm.ss"
         return dateFormatter.string(from: Date())
    }
}


class Auth {
    static func requestPermissions() {
        DispatchQueue.main.async {
            let alert = UI.createAlert(title: "Permission Required",
                                                       message: "VCB needs screen recording permissions, even if you only intend on recording audio.",
                                                       button1: "Open Settings",
                                                       button2: "Quit")
            if alert.runModal() == .alertFirstButtonReturn {
                NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture")!)
            }
            NSApp.terminate(NSApplication.shared)
        }
    }
}

class UI {
    @MainActor static func createAlert(title: String, message: String, button1: String, button2: String = "") -> NSAlert {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.addButton(withTitle: button1)
        if button2 != "" {
            alert.addButton(withTitle: button2)
        }
        alert.alertStyle = .critical
        return alert
    }
}


extension NSPoint {
    func isOnEllipse(inRect rect: NSRect) -> Bool {
        let centerX = rect.origin.x + rect.width / 2
        let centerY = rect.origin.y + rect.height / 2
        let radiusX = rect.width / 2
        let radiusY = rect.height / 2
        let a = pow(self.x - centerX, 2) / pow(radiusX, 2)
        let b = pow(self.y - centerY, 2) / pow(radiusY, 2)
        return a + b == 1
    }
    
//     在边线里面
    static func isPointOnEllipseInRect(rect: NSRect, pointToCheck: NSPoint) -> Bool {
        let centerX = rect.origin.x + rect.size.width / 2
        let centerY = rect.origin.y + rect.size.height / 2
        let radiusX = rect.size.width / 2
        let radiusY = rect.size.height / 2
        let dx = pointToCheck.x - centerX
        let dy = pointToCheck.y - centerY
        let normalizedX = dx / radiusX
        let normalizedY = dy / radiusY
        return (normalizedX * normalizedX + normalizedY * normalizedY) <= 1
    }

    static func isPointOnEllipseBorderInRect(rect: NSRect, pointToCheck: NSPoint, tolerance: CGFloat = 0) -> Bool {
        let centerX = rect.origin.x + rect.size.width / 2
        let centerY = rect.origin.y + rect.size.height / 2
        let radiusX = rect.size.width / 2
        let radiusY = rect.size.height / 2
        let dx = pointToCheck.x - centerX
        let dy = pointToCheck.y - centerY
        let normalizedX = dx / radiusX
        let normalizedY = dy / radiusY
        let distanceFromCenterSquared = normalizedX * normalizedX + normalizedY * normalizedY
        return (distanceFromCenterSquared <= (1 + tolerance)) && (distanceFromCenterSquared >= (1 - tolerance))
    }
    
    static func isPointOnLine(linePoint1: NSPoint, linePoint2: NSPoint, pointToCheck: NSPoint) -> Bool {
        let dx = linePoint2.x - linePoint1.x
        let dy = linePoint2.y - linePoint1.y
        let slope = dy / dx
        let yIntercept = linePoint1.y - slope * linePoint1.x
        let yAtPointToCheck = slope * pointToCheck.x + yIntercept
        return (abs(pointToCheck.y - yAtPointToCheck) <= 5)
    }

    static func isPointOnDoodleLine(doodlePoints: [NSPoint], pointToCheck: NSPoint) -> Bool {
        if (doodlePoints.count == 0) { return false }
        for index in 0..<doodlePoints.count - 1 {
            let p1 = doodlePoints[index]
            let p2 = doodlePoints[index + 1]
                let centerX = (p1.x + p2.x) / 2.0
                let centerY = (p1.y + p2.y) / 2.0
                if (abs(pointToCheck.x - centerX) < 4 && abs(pointToCheck.y - centerY) < 4) {
                    return true
                }
        }
        return false
    }
    
    static func isPointAtFrame(point: NSPoint, rect: CGRect , deta: CGFloat = 4.0) -> Bool {
        let rect = rect
//         上
        if (point.x > rect.minX - deta && point.x < rect.maxX + deta && point.y > rect.maxY - deta && point.y < rect.maxY + deta) {
            return true
        }
        
//          下
        if (point.x > rect.minX - deta && point.x < rect.maxX + deta && point.y > rect.minY - deta && point.y < rect.minY + deta) {
            return true
        }
            
//        左
        if (point.x > rect.minX - deta && point.x < rect.minX + deta && point.y > rect.minY - deta && point.y < rect.maxY + deta) {
            return true
        }
//         右
        if (point.x > rect.maxX - deta && point.x < rect.maxX + deta && point.y > rect.minY - deta && point.y < rect.maxY + deta) {
            return true
        }
        return false
    }
}
