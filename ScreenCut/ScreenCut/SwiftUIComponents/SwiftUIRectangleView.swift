//
//  SwiftUIRectangleView.swift
//  ScreenCut
//
//  Created by helinyu on 2024/10/26.
//

import SwiftUI
import Foundation

// MARK: - SwiftUI Rectangle Selection View
struct SwiftUIRectangleView: View {
    @State private var selectionRect: CGRect = .zero
    @State private var initialLocation: CGPoint?
    @State private var lastMouseLocation: CGPoint?
    @State private var isDragging: Bool = false
    @State private var activeHandle: RetangleResizeHandle = .none
    @State private var maxFrame: CGRect = .zero
    @State private var fillOverlayAlpha: CGFloat = 0.0
    
    let controlPointDiameter: CGFloat = 8.0
    let controlPointColor: Color = .white
    
    @ObservedObject var editModel: EditCutBottomShareModel
    
    var hasSelectionRect: Bool {
        return selectionRect.size.width > 0 && selectionRect.size.height > 0
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background overlay
                Rectangle()
                    .fill(Color.clear.opacity(fillOverlayAlpha))
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .onAppear {
                        maxFrame = geometry.frame(in: .global)
                    }
                
                // Selection rectangle
                if hasSelectionRect {
                    Rectangle()
                        .stroke(editModel.selectColor.color, lineWidth: CGFloat(editModel.sizeType.rawValue))
                        .frame(width: selectionRect.width, height: selectionRect.height)
                        .position(
                            x: selectionRect.midX,
                            y: selectionRect.midY
                        )
                        .overlay(
                            // Control points
                            ForEach(RetangleResizeHandle.allCases, id: \.self) { handle in
                                if let point = controlPointForHandle(handle, inRect: selectionRect) {
                                    Circle()
                                        .fill(controlPointColor)
                                        .frame(width: controlPointDiameter, height: controlPointDiameter)
                                        .position(point)
                                        .opacity(editModel.cutType == .none ? 1.0 : 0.0)
                                }
                            }
                        )
                }
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        handleDragChanged(value, in: geometry)
                    }
                    .onEnded { value in
                        handleDragEnded(value, in: geometry)
                    }
            )
        }
    }
    
    // MARK: - Drag Handling
    private func handleDragChanged(_ value: DragGesture.Value, in geometry: GeometryProxy) {
        let location = value.location
        
        if !isDragging {
            // Start new selection
            initialLocation = location
            selectionRect = CGRect(origin: location, size: .zero)
            isDragging = true
        } else {
            // Update selection
            guard let start = initialLocation else { return }
            
            let newRect = CGRect(
                x: min(start.x, location.x),
                y: min(start.y, location.y),
                width: abs(location.x - start.x),
                height: abs(location.y - start.y)
            )
            
            selectionRect = newRect
        }
    }
    
    private func handleDragEnded(_ value: DragGesture.Value, in geometry: GeometryProxy) {
        isDragging = false
        initialLocation = nil
    }
    
    // MARK: - Control Point Calculation
    private func controlPointForHandle(_ handle: RetangleResizeHandle, inRect rect: CGRect) -> CGPoint? {
        switch handle {
        case .none:
            return nil
        case .topLeft:
            return CGPoint(x: rect.minX, y: rect.minY)
        case .top:
            return CGPoint(x: rect.midX, y: rect.minY)
        case .topRight:
            return CGPoint(x: rect.maxX, y: rect.minY)
        case .right:
            return CGPoint(x: rect.maxX, y: rect.midY)
        case .bottomRight:
            return CGPoint(x: rect.maxX, y: rect.maxY)
        case .bottom:
            return CGPoint(x: rect.midX, y: rect.maxY)
        case .bottomLeft:
            return CGPoint(x: rect.minX, y: rect.maxY)
        case .left:
            return CGPoint(x: rect.minX, y: rect.midY)
        }
    }
    
    // MARK: - Handle Detection
    private func handleForPoint(_ point: CGPoint) -> RetangleResizeHandle {
        if selectionRect.size.width < 2.0 {
            return .none
        }
        
        for handle in RetangleResizeHandle.allCases {
            if let controlPoint = controlPointForHandle(handle, inRect: selectionRect) {
                let controlRect = CGRect(
                    origin: CGPoint(
                        x: controlPoint.x - controlPointDiameter / 2,
                        y: controlPoint.y - controlPointDiameter / 2
                    ),
                    size: CGSize(width: controlPointDiameter, height: controlPointDiameter)
                )
                if controlRect.contains(point) {
                    return handle
                }
            }
        }
        return .none
    }
    
    // MARK: - Public Methods
    func resetSelection() {
        selectionRect = .zero
        isDragging = false
        initialLocation = nil
        activeHandle = .none
    }
    
    func getSelectionRect() -> CGRect {
        return selectionRect
    }
}

// MARK: - Preview
struct SwiftUIRectangleView_Previews: PreviewProvider {
    static var previews: some View {
        SwiftUIRectangleView(editModel: EditCutBottomShareModel.shared)
            .frame(width: 400, height: 300)
    }
}
