//
//  ScreenshotWindow.swift
//  ScreenCut
//
//  Created by helinyu on 2024/12/19.
//

import SwiftUI
import AppKit

class SwiftUIScreenshotWindowController: NSWindowController {
    private var overlayView: SwiftUIScreenshotOverlayView?
    private var bottomPanelController: BottomEditPanelController?
    
    convenience init() {
        let screenFrame = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1920, height: 1080)
        
        let window = NSWindow(
            contentRect: screenFrame,
            styleMask: [.closable, .borderless],
            backing: .buffered,
            defer: false
        )
        
        window.isOpaque = false
        window.hasShadow = false
        window.level = .screenSaver - 1
        window.title = kAreaSelector
        window.backgroundColor = NSColor.clear
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.isReleasedWhenClosed = false
        
        self.init(window: window)
        
        setupOverlayView()
        setupNotifications()
    }
    
    private func setupOverlayView() {
        let overlayView = SwiftUIScreenshotOverlayView()
        let hostingView = NSHostingView(rootView: overlayView)
        hostingView.frame = window?.contentView?.bounds ?? NSRect.zero
        window?.contentView = hostingView
        self.overlayView = overlayView
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(showBottomEditView),
            name: Notification.Name("showBottomEditView"),
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(hideBottomEditView),
            name: Notification.Name("hideBottomEditView"),
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(showToast(_:)),
            name: Notification.Name("showToast"),
            object: nil
        )
    }
    
    @objc private func showBottomEditView() {
        if bottomPanelController == nil {
            bottomPanelController = BottomEditPanelController()
        }
        bottomPanelController?.showWindow(nil)
    }
    
    @objc private func hideBottomEditView() {
        bottomPanelController?.hideWindow()
    }
    
    @objc private func showToast(_ notification: Notification) {
        guard let message = notification.object as? String else { return }
        ToastController.shared.showToast(message: message)
    }
    
    override func showWindow(_ sender: Any?) {
        super.showWindow(sender)
        AppDelegate.shared.screentId = findCurrentScreenForSwiftUI()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Bottom Edit Panel Controller
class BottomEditPanelController: NSWindowController {
    convenience init() {
        let contentView = NSHostingView(rootView: EditCutBottomView())
        contentView.frame = NSRect(x: 0, y: 0, width: kBottomEditRowWidth, height: kBottomEditRowHeight)
        
        let window = NSWindow(
            contentRect: contentView.frame,
            styleMask: [.fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        window.collectionBehavior = [.canJoinAllSpaces]
        window.level = .screenSaver
        window.title = kEditImageText
        window.contentView = contentView
        window.backgroundColor = .clear
        window.titleVisibility = .hidden
        window.isReleasedWhenClosed = false
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        
        self.init(window: window)
    }
    
    func hideWindow() {
        window?.setIsVisible(false)
    }
}

// MARK: - Toast Controller
class ToastController: ObservableObject {
    static let shared = ToastController()
    
    private var toastWindow: NSWindow?
    
    private init() {}
    
    func showToast(message: String) {
        DispatchQueue.main.async {
            self.createToastWindow(message: message)
            self.toastWindow?.makeKeyAndOrderFront(nil)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.toastWindow?.close()
                self.toastWindow = nil
            }
        }
    }
    
    private func createToastWindow(message: String) {
        let toastHeight: CGFloat = 50
        let toastWidth: CGFloat = 300
        
        let screenSize = NSScreen.main?.frame.size ?? CGSize(width: 800, height: 600)
        let toastPosition = CGPoint(x: (screenSize.width - toastWidth) / 2, y: screenSize.height - toastHeight - 100)
        
        let window = NSWindow(
            contentRect: NSRect(x: toastPosition.x, y: toastPosition.y, width: toastWidth, height: toastHeight),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        window.isOpaque = false
        window.backgroundColor = NSColor.black.withAlphaComponent(0.8)
        window.level = .screenSaver + 1
        window.hasShadow = true
        window.isReleasedWhenClosed = false
        window.isMovableByWindowBackground = false
        
        let hostingView = NSHostingView(rootView: SwiftUIToastView(message: message))
        window.contentView = hostingView
        
        self.toastWindow = window
    }
}

// MARK: - Toast View
struct SwiftUIToastView: View {
    let message: String
    
    var body: some View {
        Text(message)
            .font(.system(size: 14))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black.opacity(0.8))
            .cornerRadius(8)
    }
}

// MARK: - Helper Functions
func findCurrentScreenForSwiftUI() -> CGDirectDisplayID? {
    let mouseLocation = NSEvent.mouseLocation
    let screens = NSScreen.screens
    for screen in screens {
        let screenFrame = screen.frame
        if screenFrame.contains(mouseLocation) {
            return screen.displayID
        }
    }
    return nil
}