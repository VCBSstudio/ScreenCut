//
//  test.swift
//  TestMacApp
//
//  Created by helinyu on 2024/10/25.
//

import SwiftUI

let kAreaSelector: String = "Area Selector"
let kEditImageText: String = "编辑图片"
let kBottomEditRowHeight: CGFloat = 45.0
let kBottomEditRowWidth: CGFloat = 340

class EditCutBottomPanel: NSWindow {

    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect, styleMask: style, backing: backingStoreType, defer: flag)
        isMovable = false
    }

    override func mouseDown(with event: NSEvent) {
        return
    }
}

let FirstIconLength: CGFloat = 20
let FirstIconPadding: CGFloat = 5

struct EditCutBottomView: View {
    
//     这个看是否需要修噶 EditCutBottomShareModel.shared ，将它修改为observer类型
    @StateObject private var bottomEditItem = EditCutBottomShareModel.shared
    @ObservedObject private var actionItem = EditActionShareModel.shared

    private func createShapeImageView(for type: EditCutBottmType) -> some View {
        Image(nsImage: NSImage(systemSymbolName: type.imgName, accessibilityDescription: nil) ?? NSImage())
            .resizable()
            .scaledToFit()
            .frame(width: FirstIconLength, height: FirstIconLength)
            .foregroundColor(bottomEditItem.cutType == type ? Color.black : Color.white)
            .background(bottomEditItem.cutType == type ? Color.white : Color.black)
            .padding(FirstIconPadding)
            .cornerRadius(3)
            .tag(type.imgName)
    }
    
    private func createActionImageView(for type: EditActionBottmType) -> some View {
        Image(nsImage: NSImage(systemSymbolName: type.imgName, accessibilityDescription: nil) ?? NSImage())
            .resizable()
            .scaledToFit()
            .frame(width: FirstIconLength, height: FirstIconLength)
            .foregroundColor(.white)
            .padding(FirstIconPadding)
    }
    
    var body: some View {
        VStack {
            HStack {
                Spacer()
                ForEach(EditCutBottmType.allCases) { type in
                    createShapeImageView(for: type)
                        .onTapGesture {
                            bottomEditItem.cutType = type
                        }
                }
                Divider()
                    .frame(width: 2, height: 25)  // 设置分割线的高度
                    .background(Color.white.opacity(0.3))  // 设置分割线的颜色
                
                ForEach(EditActionBottmType.allCases) { type in
                    createActionImageView(for: type)
                        .onTapGesture {
                            actionItem.actionType = type
                        }
                }
                Spacer()
            }.frame(height: 40.0)
            if bottomEditItem.cutType != .none {
                SecondEditView()
            }
        }.padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
            .background(Color.black.opacity(0.7))
            .frame(width: kBottomEditRowWidth)
            .frame(maxWidth: .infinity)
    }
}

struct SecondEditView: View {
    var isText: Bool = false
    
    @StateObject private var bottomEditItem = EditCutBottomShareModel.shared

    private func createLineWidthImageView(for type: LineWidthType) -> some View {
        HStack {
            Image(nsImage: NSImage(systemSymbolName: "circlebadge.fill", accessibilityDescription: nil) ?? NSImage())
                .resizable()
                .scaledToFit()
                .frame(width: CGFloat(type.rawValue) * 4, height: CGFloat(type.rawValue) * 4)
                .foregroundColor(.white)
                .padding(10)
                .background(bottomEditItem.sizeType == type ? Color.white.opacity(0.3) : Color.black)
                
        }.frame(width: 25, height: 25).cornerRadius(3, antialiased: true)
    }
    
    private func createColorView(for type: SelectedColorHandle) -> some View {
        type.color
            .frame(height: 30.0)
            .border(type == bottomEditItem.selectColor ? Color.purple: Color.clear, width: 2)
    }
    
    var body: some View {
        HStack {
            if bottomEditItem.cutType == .text {
                HStack {
                    Picker("  文字:", selection: $bottomEditItem.textSize) {
                        ForEach(12...100, id: \.self) { value in
                            Text("\(value)").tag(value)
                        }
                    }
                    .pickerStyle(DefaultPickerStyle()) // 使用下拉菜单样式
                    .frame(width: 120)
                    .background(.clear)
                    .cornerRadius(5)
                    .foregroundColor(.white)
                    .padding()
                }.frame(width: 120.0)
            }
            else {
                HStack {
                    ForEach(LineWidthType.allCases) { type in
                        createLineWidthImageView(for: type)
                            .onTapGesture {
                                self.bottomEditItem.sizeType = type
                            }
                    }
                }.frame(width: 120.0)
            }
            Divider()
                .frame(width: 2, height: 25)
                .background(Color.white.opacity(0.3))
            
            HStack {
                ForEach(SelectedColorHandle.allCases) { type in
                    createColorView(for: type)
                        .onTapGesture {
                            self.bottomEditItem.selectColor = type
                    }
                }
            }.frame(width: 200.0)
        }.padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
            .background(Color.black.opacity(0.7))
            .frame(width: kBottomEditRowWidth ,height: 40)
            .frame(maxWidth: .infinity)
    }
}

#Preview {
    SecondEditView()
}

#Preview {
    EditCutBottomView()
}

