//
//  SwiftUIScreenshotOverlayView.swift
//  ScreenCut
//
//  Created by helinyu on 2024/12/19.
//

import SwiftUI
import AppKit
import Combine

struct SwiftUIScreenshotOverlayView: View {
    @StateObject private var bottomEditItem = EditCutBottomShareModel.shared
    @ObservedObject private var actionItem = EditActionShareModel.shared
    
    @State private var selectionRect = CGRect.zero
    @State private var hasSelectionRect = false
    @State private var isDragging = false
    @State private var dragStartPoint = CGPoint.zero
    @State private var isEditFinished = false
    @State private var isFindForDown = false
    
    @State private var cancellables = Set<AnyCancellable>()
    @State private var bottomPanelVisible = false
    
    var body: some View {
        ZStack {
            // Background overlay
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .ignoresSafeArea()
                .onTapGesture { location in
                    if !hasSelectionRect {
                        startSelection(at: location)
                    }
                }
            
            // Selection rectangle
            if hasSelectionRect {
                SwiftUISelectionRectangleView(
                    rect: selectionRect,
                    isDragging: isDragging,
                    onDragChanged: handleSelectionDragChanged,
                    onDragEnded: handleSelectionDragEnded
                )
            }
            
            // Bottom edit panel
            if bottomPanelVisible {
                VStack {
                    Spacer()
                    EditCutBottomView()
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(8)
                        .padding()
                }
            }
        }
        .onAppear {
            setupNotifications()
        }
        .onDisappear {
            cleanup()
        }
        .focusable()
        .onKeyPress { keyPress in
            handleKeyPress(keyPress)
        }
    }
    
    private func setupNotifications() {
        NotificationCenter.default.publisher(for: .kCutTypeChange)
            .merge(with: NotificationCenter.default.publisher(for: .kSelectColorTypeChange))
            .merge(with: NotificationCenter.default.publisher(for: .kDrawSizeTypeChange))
            .merge(with: NotificationCenter.default.publisher(for: .kTextSizeTypeChange))
            .sink { notification in
                handleNotification(notification)
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: .kDownloadClick)
            .sink { _ in
                handleDownloadClick()
            }
            .store(in: &cancellables)
    }
    
    private func handleNotification(_ notification: Notification) {
        switch notification.name {
        case .kCutTypeChange:
            isEditFinished = true
        case .kSelectColorTypeChange, .kDrawSizeTypeChange, .kTextSizeTypeChange:
            // Update current oper view properties
            break
        default:
            break
        }
    }
    
    private func handleDownloadClick() {
        if !isEditFinished {
            isEditFinished = true
        }
        bottomPanelVisible = false
    }
    
    private func startSelection(at location: CGPoint) {
        hasSelectionRect = true
        dragStartPoint = location
        selectionRect = CGRect(origin: location, size: .zero)
    }
    
    private func handleSelectionDragChanged(_ value: DragGesture.Value) {
        if !hasSelectionRect { return }
        
        let currentPoint = value.location
        let minX = min(dragStartPoint.x, currentPoint.x)
        let minY = min(dragStartPoint.y, currentPoint.y)
        let maxX = max(dragStartPoint.x, currentPoint.x)
        let maxY = max(dragStartPoint.y, currentPoint.y)
        
        selectionRect = CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
        isDragging = true
    }
    
    private func handleSelectionDragEnded(_ value: DragGesture.Value) {
        isDragging = false
        if hasSelectionRect && selectionRect.width > 10 && selectionRect.height > 10 {
            ScreenCut.screenArea = selectionRect
            bottomPanelVisible = true
        }
    }
    
    private func handleKeyPress(_ keyPress: KeyPress) -> KeyPress.Result {
        switch keyPress.key {
        case .return:
            actionItem.actionType = .download
            return .handled
        case .delete:
            showToast(message: "删除功能暂未实现")
            return .handled
        case .escape:
            // Close screenshot window
            NSApplication.shared.keyWindow?.close()
            return .handled
        default:
            return .ignored
        }
    }
    
    private func showToast(message: String) {
        ToastController.shared.showToast(message: message)
    }
    
    private func cleanup() {
        cancellables.removeAll()
    }
}

// MARK: - Selection Rectangle View
struct SwiftUISelectionRectangleView: View {
    let rect: CGRect
    let isDragging: Bool
    let onDragChanged: (DragGesture.Value) -> Void
    let onDragEnded: (DragGesture.Value) -> Void
    
    var body: some View {
        Rectangle()
            .stroke(Color.white, lineWidth: 2)
            .frame(width: rect.width, height: rect.height)
            .position(x: rect.midX, y: rect.midY)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged(onDragChanged)
                    .onEnded(onDragEnded)
            )
    }
}