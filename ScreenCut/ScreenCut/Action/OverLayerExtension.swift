//
//  OverLayerExtension.swift
//  TestMap
//
//  Created by helinyu on 2024/10/26.
//

import Foundation
import SwiftUI

enum RetangleResizeHandle: CaseIterable {
    case none
    case topLeft, top, topRight, right, bottomRight, bottom, bottomLeft, left
}

enum SelectedColorHandle: String, CaseIterable, Identifiable {
    case red, yellow, green, blue, gray, white
    var id: Self { self }
    
    var color: Color {
        switch self {
        case .red:
            return Color.red
        case .yellow:
            return Color.yellow
        case .green:
            return Color.green
        case .blue:
            return Color.blue
        case .gray:
            return Color.gray
        case .white:
            return Color.white
        }
    }
}

enum EditCutBottmType: CaseIterable,Identifiable {
    
    case none
    case square, circle, arrow, doodle, text
    
    static var allCases: [EditCutBottmType] = [square, circle, arrow, doodle, text]
    
    var id: Self { self }

    var imgName: String {
        switch self {
        case .square:
            return "square"
        case .circle:
            return "circle"
        case .arrow:
            return "arrow.up.forward"
        case .doodle:
            return "pencil.line"
        case .text:
            return "t.square.fill"
        default:
            return ""
        }
    }
}

enum EditActionBottmType: CaseIterable,Identifiable {
    
    case none
    case ocr, translate, cancel, download
    
    static var allCases: [EditActionBottmType] = [ocr, translate, cancel, download]
    
    var id: Self { self }

    var imgName: String {
        switch self {
        case .ocr:
            return "text.document"
        case .translate:
            return "translate"
        case .cancel:
            return "xmark"
        case .download:
            return "square.and.arrow.down"
        default:
            return ""
        }
    }
}

enum LineWidthType: Int, CaseIterable, Identifiable {
    
    case Two = 2
    case Four = 4
    case Six = 6
    
    var id: Self { self }
    
    var imgName: String {
        switch self {
        case .Two:
            return "circlebadge.fill"
        case .Four:
            return "circlebadge.fill"
        case .Six:
            return "circlebadge.fill"
        }
    }
    
}
