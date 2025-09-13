//
//  SwiftUIIntegration.swift
//  ScreenCut
//
//  Created by helinyu on 2024/12/19.
//

import SwiftUI
import AppKit
import Combine

// MARK: - SwiftUI Integration Manager
class SwiftUIIntegrationManager: ObservableObject {
    static let shared = SwiftUIIntegrationManager()
    
    @Published var isScreenshotMode = false
    @Published var currentScreenshotWindow: SwiftUIScreenshotWindowController?
    
    private init() {}
    
    func startScreenshotMode() {
        isScreenshotMode = true
        currentScreenshotWindow = SwiftUIScreenshotWindowController()
        currentScreenshotWindow?.showWindow(nil)
    }
    
    func endScreenshotMode() {
        isScreenshotMode = false
        currentScreenshotWindow?.close()
        currentScreenshotWindow = nil
    }
}

// MARK: - Enhanced Screenshot Overlay View
struct EnhancedScreenshotOverlayView: View {
    @StateObject private var bottomEditItem = EditCutBottomShareModel.shared
    @ObservedObject private var actionItem = EditActionShareModel.shared
    @StateObject private var integrationManager = SwiftUIIntegrationManager.shared
    
    @State private var selectionRect = CGRect.zero
    @State private var hasSelectionRect = false
    @State private var isDragging = false
    @State private var dragStartPoint = CGPoint.zero
    @State private var operViews: [AnyView] = []
    @State private var currentOperViewIndex: Int?
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
                SelectionRectangleView(
                    rect: selectionRect,
                    isDragging: isDragging,
                    onDragChanged: handleSelectionDragChanged,
                    onDragEnded: handleSelectionDragEnded
                )
            }
            
            // Drawing views
            ForEach(operViews.indices, id: \.self) { index in
                operViews[index]
                    .position(
                        x: operViews[index].frame?.midX ?? 0,
                        y: operViews[index].frame?.midY ?? 0
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
            updateCurrentOperView()
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
    
    private func updateCurrentOperView() {
        guard let index = currentOperViewIndex,
              index < operViews.count else { return }
        
        // Update the current oper view properties
        // This would need to be implemented based on the specific drawing view type
    }
    
    private func handleKeyPress(_ keyPress: KeyPress) -> KeyPress.Result {
        switch keyPress.key {
        case .return:
            actionItem.actionType = .download
            return .handled
        case .delete:
            deleteCurrentOperView()
            return .handled
        case KeyEquivalent("z") where keyPress.modifiers.contains(.command):
            undoLastOperation()
            return .handled
        case .escape:
            integrationManager.endScreenshotMode()
            return .handled
        default:
            return .ignored
        }
    }
    
    private func deleteCurrentOperView() {
        guard let index = currentOperViewIndex,
              index < operViews.count else {
            showToast(message: "目前没有选中要删除的页面")
            return
        }
        
        operViews.remove(at: index)
        currentOperViewIndex = nil
    }
    
    private func undoLastOperation() {
        guard !operViews.isEmpty else {
            showToast(message: "没有操作可回退了")
            return
        }
        
        operViews.removeLast()
        currentOperViewIndex = nil
    }
    
    private func showToast(message: String) {
        ToastController.shared.showToast(message: message)
    }
    
    private func cleanup() {
        cancellables.removeAll()
    }
}

// MARK: - Selection Rectangle View
struct SelectionRectangleView: View {
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

// MARK: - Enhanced Drawing Views
struct EnhancedRectangleDrawingView: View {
    @State var frame: CGRect
    @State var isEditFinished = false
    @State var selectedColor: Color = .white
    @State var lineWidth: CGFloat = 2.0
    
    var body: some View {
        Rectangle()
            .stroke(selectedColor, lineWidth: lineWidth)
            .frame(width: frame.width, height: frame.height)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if !isEditFinished {
                            frame.origin = value.location
                        }
                    }
            )
    }
}

struct EnhancedCircleDrawingView: View {
    @State var frame: CGRect
    @State var isEditFinished = false
    @State var selectedColor: Color = .white
    @State var lineWidth: CGFloat = 2.0
    
    var body: some View {
        Circle()
            .stroke(selectedColor, lineWidth: lineWidth)
            .frame(width: frame.width, height: frame.height)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if !isEditFinished {
                            frame.origin = value.location
                        }
                    }
            )
    }
}

struct EnhancedArrowDrawingView: View {
    @State var frame: CGRect
    @State var isEditFinished = false
    @State var selectedColor: Color = .white
    @State var lineWidth: CGFloat = 2.0
    
    var body: some View {
        Path { path in
            path.move(to: CGPoint(x: frame.minX, y: frame.midY))
            path.addLine(to: CGPoint(x: frame.maxX, y: frame.midY))
            path.addLine(to: CGPoint(x: frame.maxX - 10, y: frame.midY - 5))
            path.move(to: CGPoint(x: frame.maxX, y: frame.midY))
            path.addLine(to: CGPoint(x: frame.maxX - 10, y: frame.midY + 5))
        }
        .stroke(selectedColor, lineWidth: lineWidth)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    if !isEditFinished {
                        frame.origin = value.location
                    }
                }
        )
    }
}

struct EnhancedTextDrawingView: View {
    @State var frame: CGRect
    @State var isEditFinished = false
    @State var selectedColor: Color = .white
    @State var fontSize: CGFloat = 12
    @State var text: String = ""
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        TextField("输入文字", text: $text)
            .font(.system(size: fontSize))
            .foregroundColor(selectedColor)
            .frame(width: frame.width, height: frame.height)
            .background(Color.clear)
            .focused($isTextFieldFocused)
            .onTapGesture {
                isTextFieldFocused = true
            }
    }
}

// MARK: - Extensions for AnyView
extension AnyView {
    var frame: CGRect? {
        // This would need to be implemented to track frame information
        // For now, return a default frame
        return CGRect(x: 0, y: 0, width: 100, height: 50)
    }
}