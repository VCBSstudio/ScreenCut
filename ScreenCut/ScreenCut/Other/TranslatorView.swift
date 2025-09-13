//
//  TranslatorView.swift
//  ScreenCut
//
//  Created by helinyu on 2024/11/2.
//

import SwiftUI

class TranslatorViewWindowController : NSWindowController {
    
    convenience init(transText: String?) {
       
        let window = NSWindow(
            contentRect: NSScreen.main!.frame,
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        window.center()
        window.setFrameAutosaveName("翻译")
        window.title = "翻译"
        window.level = .screenSaver
        window.contentView = NSHostingView(rootView: TranslatorView(resultText: transText))
        
        self.init(window: window)
    }

    override func showWindow(_ sender: Any?) {
        super.showWindow(sender)
    }
}

struct TranslatorView: View {
    var resultText: String?
    var body: some View {
        VStack {
            Button("拷贝") {
                let paste = NSPasteboard.general
                paste.clearContents()
                paste.setString(resultText ?? "", forType: .string)
                ToastManager.shared.show("拷贝成功")

            }
            Text(resultText ?? "没有文字内容")
                .padding(EdgeInsets(top: 40, leading: 40, bottom: 40, trailing: 40))
        }
    }
}

#Preview {
    OCRView()
}
