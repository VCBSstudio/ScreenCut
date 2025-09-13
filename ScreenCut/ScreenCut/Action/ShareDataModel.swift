

//
//  ShareDataModel.swift
//  TestMap
//
//  Created by helinyu on 2024/10/26.
//
import Foundation
import Combine


//let kCutTypeChange = "kCutTypeChange"

class EditCutBottomShareModel: ObservableObject {
    static let shared = EditCutBottomShareModel(cutType: .none, sizeType: .Two, textSize: 12, selectColor: .red)

    init(cutType: EditCutBottmType, sizeType: LineWidthType, textSize: Int, selectColor: SelectedColorHandle) {
        self.cutType = cutType
        self.sizeType = sizeType
        self.textSize = textSize
        self.selectColor = selectColor
    }
    
    @Published var cutType: EditCutBottmType = .none {
        didSet {
            NotificationCenter.default.post(name: .kCutTypeChange, object: cutType)
        }
    }
    
    @Published var sizeType: LineWidthType = .Two { // 用来设置绘制的宽度大小，也可能是字体大小
        didSet {
            NotificationCenter.default.post(name: .kDrawSizeTypeChange, object: sizeType)
        }
    }
    
    @Published var textSize: Int = 12 { // 写字的颜色
        didSet {
            NotificationCenter.default.post(name: .kTextSizeTypeChange, object: textSize)
        }
    }
    @Published var selectColor: SelectedColorHandle = .red {
        didSet {
            NotificationCenter.default.post(name: .kSelectColorTypeChange, object: selectColor)
        }
    }
}

class EditActionShareModel: ObservableObject {
    static let shared = EditActionShareModel()
    
    @Published var actionType: EditActionBottmType = .none {
        didSet {
            switch actionType {
            case .ocr:
                ScreenCut.showOCR()
            case .translate:
                ScreenCut.ocrThenTransRequest()
            case .cancel, .download:
                DispatchQueue.main.async { [self] in
                    if actionType == .download {
                        NotificationCenter.default.post(name:.kDownloadClick, object: nil)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            ScreenCut.cutImage()
                            // Close screenshot windows using SwiftUI manager
                            ScreenshotManager.shared.hideScreenshotWindow()
                        }
                    }
                    else {
                        // Close screenshot windows using SwiftUI manager
                        ScreenshotManager.shared.hideScreenshotWindow()
                    }
                   
                }
                
            case .none:
                break
            }
        }
    }
}
