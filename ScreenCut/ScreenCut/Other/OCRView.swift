//
//  TranslatorView.swift
//  ScreenCut
//
//  Created by helinyu on 2024/11/2.
//

import SwiftUI

class OCRViewWindowController : NSWindowController {
    var cuText: String?
    
    convenience init(transText: String?) {
        //        let originX = NSScreen.main!.frame.size.width/2 - 270
        //        let originY = NSScreen.main!.frame.size.height/2 - 200
        let window = NSWindow(
            contentRect: NSScreen.main!.frame,
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.makeKey()
        window.center()
        window.setFrameAutosaveName("OCR")
        window.title = "OCR"
        window.level = .screenSaver
        window.contentView = NSHostingView(rootView: OCRView(resultText: transText))
        self.init(window: window)
        
        cuText = transText
    }
    
    override func showWindow(_ sender: Any?) {
        super.showWindow(sender)
    }
}

struct OCRView: View {
    var resultText: String?
    var body: some View {
        VStack {
            HStack {
                Button("拷贝") {
                    let paste = NSPasteboard.general
                    paste.clearContents()
                    paste.setString(resultText ?? "", forType: .string)
                    DispatchQueue.main.async {
                        ToastManager.shared.show("拷贝成功")
                    }
                }
                Button("翻译") {
                    if resultText == nil {
                        return
                    }
                    ScreenCut.transforRequest(resultText!).sink { completion in
                        switch completion {
                        case .finished:
                            print("finished")
                        case .failure(let error):
                            DispatchQueue.main.async {
                                ToastManager.shared.show(error.userInfo.description)
                            }
                        }
                    } receiveValue: { text in
                        DispatchQueue.main.async {
                            TranslatorViewWindowController(transText: text).showWindow(nil)
                        }
                    }.store(in: &cancellables)
                    
                }
            }
            ScrollView { // 使用垂直方向的 ScrollView
                Text(resultText ?? "没有文字内容")
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading) // 左对齐
            }.padding(EdgeInsets(top: 50, leading: 40, bottom: 40, trailing: 40))
            
        }
        
    }
}

#Preview {
    OCRView()
}
