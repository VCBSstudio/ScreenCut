//
//  PureSwiftUIScreenshotWindow.swift
//  ScreenCut
//
//  Created by helinyu on 2024/12/19.
//

import SwiftUI
import Combine

// MARK: - Pure SwiftUI Screenshot Window
struct PureSwiftUIScreenshotWindow: View {
    @StateObject private var screenshotManager = ScreenshotManager.shared
    @State private var isVisible = false
    
    var body: some View {
        ZStack {
            if isVisible {
                ScreenshotOverlayView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.3))
                    .ignoresSafeArea()
            }
        }
        .onAppear {
            isVisible = true
        }
        .onDisappear {
            isVisible = false
        }
    }
}

// MARK: - Screenshot Manager
@MainActor
class ScreenshotManager: ObservableObject {
    static let shared = ScreenshotManager()
    
    @Published var isScreenshotActive = false
    @Published var showScreenshotOverlay = false
    
    private init() {}
    
    func showScreenshotWindow() {
        guard !isScreenshotActive else { return }
        
        showScreenshotOverlay = true
        isScreenshotActive = true
        
        // 设置屏幕ID
        SwiftUIAppDelegate.shared.screentId = findCurrentScreenForSwiftUI()
    }
    
    func hideScreenshotWindow() {
        showScreenshotOverlay = false
        isScreenshotActive = false
    }
}

// MARK: - Pure SwiftUI Screenshot Overlay
struct ScreenshotOverlayView: View {
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
    
    // Drawing views
    @State private var operViews: [AnyView] = []
    @State private var currentOperView: AnyView?
    
    var body: some View {
        ZStack {
            // Background overlay
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            // Selection rectangle
            if hasSelectionRect {
                Rectangle()
                    .stroke(Color.white, lineWidth: 2)
                    .background(Color.white.opacity(0.1))
                    .frame(width: selectionRect.width, height: selectionRect.height)
                    .position(
                        x: selectionRect.midX,
                        y: selectionRect.midY
                    )
            }
            
            // Drawing views based on current tool
            Group {
                switch bottomEditItem.cutType {
                case .square:
                    SwiftUIRectangleView(editModel: bottomEditItem)
                case .circle:
                    SwiftUICircleView(editModel: bottomEditItem)
                case .arrow:
                    SwiftUIArrowView(editModel: bottomEditItem)
                case .doodle:
                    SwiftUIDoodleView(editModel: bottomEditItem)
                case .text:
                    SwiftUITextView(editModel: bottomEditItem)
                case .none:
                    EmptyView()
                }
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
            cancellables.removeAll()
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    handleDragChanged(value)
                }
                .onEnded { value in
                    handleDragEnded(value)
                }
        )
        .onKeyPress(.escape) {
            ScreenshotManager.shared.hideScreenshotWindow()
            return .handled
        }
    }
    
    private func setupNotifications() {
        let cutTypePublisher = NotificationCenter.default.publisher(for: .kCutTypeChange)
        let selectColorPublisher = NotificationCenter.default.publisher(for: .kSelectColorTypeChange)
        let drawSizedPublisher = NotificationCenter.default.publisher(for: .kDrawSizeTypeChange)
        let textSizePublisher = NotificationCenter.default.publisher(for: .kTextSizeTypeChange)
        let downloadPublisher = NotificationCenter.default.publisher(for: .kDownloadClick)
        
        cutTypePublisher
            .merge(with: selectColorPublisher, drawSizedPublisher, textSizePublisher)
            .sink { notification in
                switch notification.name {
                case .kCutTypeChange:
                    isEditFinished = true
                case .kSelectColorTypeChange, .kDrawSizeTypeChange, .kTextSizeTypeChange:
                    // Handle color and size changes
                    break
                default:
                    break
                }
            }
            .store(in: &cancellables)
        
        downloadPublisher.sink { _ in
            if !isEditFinished {
                isEditFinished = true
            }
            bottomPanelVisible = false
        }
        .store(in: &cancellables)
    }
    
    private func handleDragChanged(_ value: DragGesture.Value) {
        if !isEditFinished {
            // Handle selection rectangle dragging
            if !isDragging {
                dragStartPoint = value.startLocation
                isDragging = true
            }
            
            let currentPoint = value.location
            let minX = min(dragStartPoint.x, currentPoint.x)
            let minY = min(dragStartPoint.y, currentPoint.y)
            let maxX = max(dragStartPoint.x, currentPoint.x)
            let maxY = max(dragStartPoint.y, currentPoint.y)
            
            selectionRect = CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
            hasSelectionRect = true
        } else {
            // Handle drawing operations
            // This would be implemented based on the current drawing tool
        }
    }
    
    private func handleDragEnded(_ value: DragGesture.Value) {
        if !isEditFinished {
            isDragging = false
            if hasSelectionRect {
                ScreenCut.screenArea = selectionRect
                showEditCutBottomView()
            }
        } else {
            // Handle drawing operations end
        }
    }
    
    private func showEditCutBottomView() {
        bottomPanelVisible = true
    }
}

// MARK: - Helper Functions
func findCurrentScreenForSwiftUI() -> CGDirectDisplayID? {
    // For now, return the main display ID
    // In a real implementation, you might want to use Core Graphics APIs
    return CGMainDisplayID()
}
