//
//  SwiftUIOverlayProtocol.swift
//  ScreenCut
//
//  Created by helinyu on 2024/10/27.
//

import Foundation
import SwiftUI

protocol SwiftUIOverlayProtocol {
    var selectedColor: Color { get set }
    var lineWidth: CGFloat { get set }
}

// MARK: - SwiftUI Circle View
struct SwiftUICircleView: View, SwiftUIOverlayProtocol {
    @State private var selectionRect: CGRect = .zero
    @State private var initialLocation: CGPoint?
    @State private var isDragging: Bool = false
    @State private var activeHandle: RetangleResizeHandle = .none
    @State private var fillOverlayAlpha: CGFloat = 0.0
    
    let controlPointDiameter: CGFloat = 8.0
    let controlPointColor: Color = .white
    
    @ObservedObject var editModel: EditCutBottomShareModel
    
    var selectedColor: Color {
        get { editModel.selectColor.color }
        set { /* Handle color change if needed */ }
    }
    
    var lineWidth: CGFloat {
        get { CGFloat(editModel.sizeType.rawValue) }
        set { /* Handle line width change if needed */ }
    }
    
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
                
                // Selection ellipse
                if hasSelectionRect {
                    Ellipse()
                        .stroke(selectedColor, lineWidth: lineWidth)
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
            initialLocation = location
            selectionRect = CGRect(origin: location, size: .zero)
            isDragging = true
        } else {
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

// MARK: - SwiftUI Arrow View
struct SwiftUIArrowView: View, SwiftUIOverlayProtocol {
    @State private var startPoint: CGPoint = .zero
    @State private var endPoint: CGPoint = .zero
    @State private var isDragging: Bool = false
    @State private var fillOverlayAlpha: CGFloat = 0.0
    
    @ObservedObject var editModel: EditCutBottomShareModel
    
    var selectedColor: Color {
        get { editModel.selectColor.color }
        set { /* Handle color change if needed */ }
    }
    
    var lineWidth: CGFloat {
        get { CGFloat(editModel.sizeType.rawValue) }
        set { /* Handle line width change if needed */ }
    }
    
    var hasArrow: Bool {
        return startPoint != .zero || endPoint != .zero
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background overlay
                Rectangle()
                    .fill(Color.clear.opacity(fillOverlayAlpha))
                    .frame(width: geometry.size.width, height: geometry.size.height)
                
                // Arrow
                if hasArrow {
                    ArrowShape(startPoint: startPoint, endPoint: endPoint)
                        .stroke(selectedColor, lineWidth: lineWidth)
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
            startPoint = location
            endPoint = location
            isDragging = true
        } else {
            endPoint = location
        }
    }
    
    private func handleDragEnded(_ value: DragGesture.Value, in geometry: GeometryProxy) {
        isDragging = false
    }
    
    // MARK: - Public Methods
    func resetArrow() {
        startPoint = .zero
        endPoint = .zero
        isDragging = false
    }
}

// MARK: - Arrow Shape
struct ArrowShape: Shape {
    let startPoint: CGPoint
    let endPoint: CGPoint
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // Draw arrow line
        path.move(to: startPoint)
        path.addLine(to: endPoint)
        
        // Draw arrow head
        let angle = atan2(endPoint.y - startPoint.y, endPoint.x - startPoint.x)
        let arrowLength: CGFloat = 20
        let arrowAngle: CGFloat = .pi / 6
        
        let arrowPoint1 = CGPoint(
            x: endPoint.x - arrowLength * cos(angle - arrowAngle),
            y: endPoint.y - arrowLength * sin(angle - arrowAngle)
        )
        
        let arrowPoint2 = CGPoint(
            x: endPoint.x - arrowLength * cos(angle + arrowAngle),
            y: endPoint.y - arrowLength * sin(angle + arrowAngle)
        )
        
        path.move(to: endPoint)
        path.addLine(to: arrowPoint1)
        path.move(to: endPoint)
        path.addLine(to: arrowPoint2)
        
        return path
    }
}

// MARK: - SwiftUI Doodle View
struct SwiftUIDoodleView: View, SwiftUIOverlayProtocol {
    @State private var lines: [[CGPoint]] = []
    @State private var currentLine: [CGPoint] = []
    @State private var isDrawing: Bool = false
    @State private var fillOverlayAlpha: CGFloat = 0.0
    
    @ObservedObject var editModel: EditCutBottomShareModel
    
    var selectedColor: Color {
        get { editModel.selectColor.color }
        set { /* Handle color change if needed */ }
    }
    
    var lineWidth: CGFloat {
        get { CGFloat(editModel.sizeType.rawValue) }
        set { /* Handle line width change if needed */ }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background overlay
                Rectangle()
                    .fill(Color.clear.opacity(fillOverlayAlpha))
                    .frame(width: geometry.size.width, height: geometry.size.height)
                
                // Draw all lines
                ForEach(0..<lines.count, id: \.self) { lineIndex in
                    Path { path in
                        let line = lines[lineIndex]
                        if !line.isEmpty {
                            path.move(to: line[0])
                            for point in line.dropFirst() {
                                path.addLine(to: point)
                            }
                        }
                    }
                    .stroke(selectedColor, lineWidth: lineWidth)
                }
                
                // Draw current line
                if !currentLine.isEmpty {
                    Path { path in
                        path.move(to: currentLine[0])
                        for point in currentLine.dropFirst() {
                            path.addLine(to: point)
                        }
                    }
                    .stroke(selectedColor, lineWidth: lineWidth)
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
        
        if !isDrawing {
            currentLine = [location]
            isDrawing = true
        } else {
            currentLine.append(location)
        }
    }
    
    private func handleDragEnded(_ value: DragGesture.Value, in geometry: GeometryProxy) {
        if !currentLine.isEmpty {
            lines.append(currentLine)
            currentLine = []
        }
        isDrawing = false
    }
    
    // MARK: - Public Methods
    func clearDrawing() {
        lines.removeAll()
        currentLine = []
        isDrawing = false
    }
}

// MARK: - SwiftUI Text View
struct SwiftUITextView: View, SwiftUIOverlayProtocol {
    @State private var textRect: CGRect = .zero
    @State private var text: String = ""
    @State private var isEditing: Bool = false
    @State private var fillOverlayAlpha: CGFloat = 0.0
    
    @ObservedObject var editModel: EditCutBottomShareModel
    
    var selectedColor: Color {
        get { editModel.selectColor.color }
        set { /* Handle color change if needed */ }
    }
    
    var lineWidth: CGFloat {
        get { CGFloat(editModel.sizeType.rawValue) }
        set { /* Handle line width change if needed */ }
    }
    
    var fontSize: CGFloat {
        return CGFloat(editModel.textSize)
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background overlay
                Rectangle()
                    .fill(Color.clear.opacity(fillOverlayAlpha))
                    .frame(width: geometry.size.width, height: geometry.size.height)
                
                // Text
                if !textRect.isEmpty {
                    if isEditing {
                        TextField("Enter text", text: $text)
                            .font(.system(size: fontSize))
                            .foregroundColor(selectedColor)
                            .frame(width: textRect.width, height: textRect.height)
                            .position(
                                x: textRect.midX,
                                y: textRect.midY
                            )
                            .onSubmit {
                                isEditing = false
                            }
                    } else {
                        Text(text.isEmpty ? "Double tap to edit" : text)
                            .font(.system(size: fontSize))
                            .foregroundColor(selectedColor)
                            .frame(width: textRect.width, height: textRect.height)
                            .position(
                                x: textRect.midX,
                                y: textRect.midY
                            )
                            .onTapGesture(count: 2) {
                                isEditing = true
                            }
                    }
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
        
        if textRect.isEmpty {
            textRect = CGRect(origin: location, size: CGSize(width: 200, height: 50))
        }
    }
    
    private func handleDragEnded(_ value: DragGesture.Value, in geometry: GeometryProxy) {
        // Text rect is set, ready for editing
    }
    
    // MARK: - Public Methods
    func resetText() {
        textRect = .zero
        text = ""
        isEditing = false
    }
}

// MARK: - Preview
struct SwiftUIOverlayViews_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            SwiftUIRectangleView(editModel: EditCutBottomShareModel.shared)
            SwiftUICircleView(editModel: EditCutBottomShareModel.shared)
            SwiftUIArrowView(editModel: EditCutBottomShareModel.shared)
            SwiftUIDoodleView(editModel: EditCutBottomShareModel.shared)
            SwiftUITextView(editModel: EditCutBottomShareModel.shared)
        }
        .frame(width: 400, height: 300)
    }
}
