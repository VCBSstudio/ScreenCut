import Foundation
import SwiftUI
import ScreenCaptureKit
import AppKit

let kSelectionMinWidth = 2.0

//  矩形的属性
class ScreenshotRectangleView: ScreenshotBaseOverlayView {
    
    var selectionRect: NSRect = NSRect.zero // 默认是zero
    //     这个应该是可以只留下一个的
    var initialLocation: NSPoint?
    var lastMouseLocation: NSPoint?
    
    var dragIng: Bool = false
    var activeHandle: RetangleResizeHandle = .none
    var maxFrame: NSRect?
    let controlPointDiameter: CGFloat = 8.0
    let controlPointColor: NSColor = NSColor.white
    var fillOverLayeralpha: CGFloat = 0.0 // 默认值
//    var selectedColor: NSColor = NSColor.white
//    var lineWidth: CGFloat = 4.0
    
    var hasSelectionRect: Bool {
        return (self.selectionRect.size.width > 0 && self.selectionRect.size.height > 0)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        
        selectionRect = NSRect.zero
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        maxFrame = dirtyRect
        
//        暂时先这样吧
        NSColor.clear.withAlphaComponent(self.fillOverLayeralpha).setFill()
        
        dirtyRect.fill()
        
        if !self.hasSelectionRect {
            return
        }
        
        let rect = selectionRect
        // 绘制边框
        let dashedBorder = NSBezierPath(rect: rect)
        dashedBorder.lineWidth = lineWidth
        selectedColor.setStroke()
        dashedBorder.stroke()
        NSColor.init(white: 1, alpha: 0.01).setFill()
        //            selectedColor.setFill()
        __NSRectFill(rect)
        // 绘制边框中的点
        if (!self.editFinished) {
            for handle in RetangleResizeHandle.allCases {
                if let point = controlPointForHandle(handle, inRect: rect) {
                    let controlPointRect = NSRect(origin: point, size: CGSize(width: controlPointDiameter, height: controlPointDiameter))
                    let controlPointPath = NSBezierPath(ovalIn: controlPointRect)
                    controlPointColor.setFill()
                    controlPointPath.fill()
                }
            }
        }
    }
    
    override func handleForPoint(_ point: NSPoint) -> RetangleResizeHandle {
        if self.selectionRect.size.width < kSelectionMinWidth {
            return .none
        }
        let rect = self.selectionRect
        for handle in RetangleResizeHandle.allCases {
            if let controlPoint = controlPointForHandle(handle, inRect: rect), NSRect(origin: controlPoint, size: CGSize(width: controlPointDiameter, height: controlPointDiameter)).contains(point) {
                return handle
            }
        }
        return .none
    }
    
    override func handleborderForPoint(_ point: NSPoint) -> RetangleResizeHandle {
        if self.selectionRect.size.width < kSelectionMinWidth {
            return .none
        }
        let deta = controlPointDiameter / 2
        let rect = self.selectionRect
//         上
        if (point.x > rect.minX - deta && point.x < rect.maxX + deta && point.y > rect.maxY - deta && point.y < rect.maxY + deta) {
            return .top
        }
        
//          下
        if (point.x > rect.minX - deta && point.x < rect.maxX + deta && point.y > rect.minY - deta && point.y < rect.minY + deta) {
            return .bottom
        }
            
//        左
        if (point.x > rect.minX - deta && point.x < rect.minX + deta && point.y > rect.minY - deta && point.y < rect.maxY + deta) {
            return .left
        }
//         右
        if (point.x > rect.maxX - deta && point.x < rect.maxX + deta && point.y > rect.minY - deta && point.y < rect.maxY + deta) {
            return .right
        }
        
        return .none
    }
    
    func controlPointForHandle(_ handle: RetangleResizeHandle, inRect rect: NSRect) -> NSPoint? {
        switch handle {
        case .topLeft:
            return NSPoint(x: rect.minX - controlPointDiameter / 2 - 1, y: rect.maxY - controlPointDiameter / 2 + 1)
        case .top:
            return NSPoint(x: rect.midX - controlPointDiameter / 2, y: rect.maxY - controlPointDiameter / 2 + 1)
        case .topRight:
            return NSPoint(x: rect.maxX - controlPointDiameter / 2 + 1, y: rect.maxY - controlPointDiameter / 2 + 1)
        case .right:
            return NSPoint(x: rect.maxX - controlPointDiameter / 2 + 1, y: rect.midY - controlPointDiameter / 2)
        case .bottomRight:
            return NSPoint(x: rect.maxX - controlPointDiameter / 2 + 1, y: rect.minY - controlPointDiameter / 2 - 1)
        case .bottom:
            return NSPoint(x: rect.midX - controlPointDiameter / 2, y: rect.minY - controlPointDiameter / 2 - 1)
        case .bottomLeft:
            return NSPoint(x: rect.minX - controlPointDiameter / 2 - 1, y: rect.minY - controlPointDiameter / 2 - 1)
        case .left:
            return NSPoint(x: rect.minX - controlPointDiameter / 2 - 1, y: rect.midY - controlPointDiameter / 2)
        case .none:
            return nil
        }
    }
    
    override func mouseDragged(with event: NSEvent) {
//        print("lt -- inner view mouseDragged 0 : \(self) \(self.dragIng)")
        if (self.editFinished) {
            return
        }
        
//        print("lt -- inner view mouseDragged 1 : \(self)")
        guard var initialLocation = initialLocation else { return }
        let currentLocation = convert(event.locationInWindow, from: nil)
        
        if activeHandle != .none {
            var newRect = selectionRect
            let lastLocation = lastMouseLocation ?? currentLocation
            
            let deltaX = currentLocation.x - lastLocation.x
            let deltaY = currentLocation.y - lastLocation.y
            
            switch activeHandle {
            case .topLeft:
                newRect.origin.x = min(newRect.origin.x + newRect.size.width - 20, newRect.origin.x + deltaX)
                newRect.size.width = max(20, newRect.size.width - deltaX)
                newRect.size.height = max(20, newRect.size.height + deltaY)
            case .top:
                newRect.size.height = max(20, newRect.size.height + deltaY)
            case .topRight:
                newRect.size.width = max(20, newRect.size.width + deltaX)
                newRect.size.height = max(20, newRect.size.height + deltaY)
            case .right:
                newRect.size.width = max(20, newRect.size.width + deltaX)
            case .bottomRight:
                newRect.origin.y = min(newRect.origin.y + newRect.size.height - 20, newRect.origin.y + deltaY)
                newRect.size.width = max(20, newRect.size.width + deltaX)
                newRect.size.height = max(20, newRect.size.height - deltaY)
            case .bottom:
                newRect.origin.y = min(newRect.origin.y + newRect.size.height - 20, newRect.origin.y + deltaY)
                newRect.size.height = max(20, newRect.size.height - deltaY)
            case .bottomLeft:
                newRect.origin.y = min(newRect.origin.y + newRect.size.height - 20, newRect.origin.y + deltaY)
                newRect.origin.x = min(newRect.origin.x + newRect.size.width - 20, newRect.origin.x + deltaX)
                newRect.size.width = max(20, newRect.size.width - deltaX)
                newRect.size.height = max(20, newRect.size.height - deltaY)
            case .left:
                newRect.origin.x = min(newRect.origin.x + newRect.size.width - 20, newRect.origin.x + deltaX)
                newRect.size.width = max(20, newRect.size.width - deltaX)
            default:
                break
            }
            self.selectionRect = newRect
            initialLocation = currentLocation // Update initial location for continuous dragging
        } else {
            if self.dragIng {
//                print("lt -- draging : \(self.dragIng)")
                // 计算移动偏移量
                let deltaX = currentLocation.x - initialLocation.x
                let deltaY = currentLocation.y - initialLocation.y
                
                // 更新矩形位置
                let x = self.selectionRect.origin.x
                let y = self.selectionRect.origin.y
                let w = self.selectionRect.size.width
                let h = self.selectionRect.size.height
//                print("lt -- select rect: \(self.selectionRect)")
                self.selectionRect.origin.x = min(max(0.0, x + deltaX), self.frame.width - w)
                self.selectionRect.origin.y = min(max(0.0, y + deltaY), self.frame.height - h)
//                print("lt -- select rect 1: \(self.selectionRect)")
                initialLocation = currentLocation
            } else {
                // 创建新矩形
                guard let maxFrame = maxFrame else { return }
                let origin = NSPoint(x: max(maxFrame.origin.x, min(initialLocation.x, currentLocation.x)), y: max(maxFrame.origin.y, min(initialLocation.y, currentLocation.y)))
                var maxH = abs(currentLocation.y - initialLocation.y)
                var maxW = abs(currentLocation.x - initialLocation.x)
                if currentLocation.y < maxFrame.origin.y { maxH = initialLocation.y }
                if currentLocation.x < maxFrame.origin.x { maxW = initialLocation.x }
                let size = NSSize(width: maxW, height: maxH)
                self.selectionRect = NSIntersectionRect(maxFrame, NSRect(origin: origin, size: size))
            }
            self.initialLocation = initialLocation
        }
        lastMouseLocation = currentLocation
        needsDisplay = true
    }
    
    override func mouseDown(with event: NSEvent) {
//        print("lt -- son inner view mouseDown 0 : \(self)")
        if (self.editFinished) {
            return
        }
        let location = convert(event.locationInWindow, from: nil)
//        print("lt -- inner view mouseDown 1: \(event.locationInWindow) \(location)")

        initialLocation = location
        lastMouseLocation = location
        activeHandle = handleForPoint(location)
        let borderHandle = self.handleborderForPoint(location)
//        print("lt -- mousedown borderHandle : \(borderHandle)")
        if (borderHandle != .none) {
            self.dragIng = true
        }
        self.needsDisplay = true
    }
    
    override func mouseUp(with event: NSEvent) {
//        print("lt -- sone mouseup")
        if (self.editFinished) {
            return
        }
        initialLocation = nil
        activeHandle = .none
        dragIng = false
        self.needsDisplay = true
    }
    
    
//    这样是为了让mouseDown在superView中监听到来调用子View的方法
    override func hitTest(_ point: NSPoint) -> NSView? {
        let hitView = super.hitTest(point)
        if hitView == self && hitView is ScreenshotRectangleView {
//            print("对象是 ParentClass 类型而不是 ChildClass（或其他子类）")
//            print("lt -- 当前子类的页面传递处理")
            return self.superview
        }
        return hitView
    }
}

