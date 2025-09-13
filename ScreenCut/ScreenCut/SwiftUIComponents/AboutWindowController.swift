//
//  AboutWindowController.swift
//  ScreenCut
//
//  Created by helinyu on 2024/12/19.
//

import SwiftUI
import AppKit

struct SwiftUIAboutView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(alignment: .center) {
                Image("logo-img-white")
                    .resizable()
                    .frame(width: 60, height: 60)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("ScreenCut")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                }
                
                Spacer()
            }
            .frame(height: 80)
            .frame(maxWidth: .infinity)
            .background(Color.black)
            .padding(.horizontal, 20)
            
            // Content
            VStack(alignment: .leading, spacing: 16) {
                Text("你所使用的版本是最新版本")
                    .font(.system(size: 14))
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("使用本软件意味着你了解并同意遵循服务条款")
                        .font(.system(size: 12))
                    
                    Text("软件使用部分开源代码和公共领域代码，并遵循相应的协议。")
                        .font(.system(size: 12))
                    
                    Text("helinyu 版权所有 @2024-未来")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            
            Spacer()
        }
        .frame(width: 540, height: 200)
        .background(Color.white)
    }
}

class SwiftUIAboutWindowController: NSWindowController {
    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 540, height: 200),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        window.center()
        window.setFrameAutosaveName("About")
        window.level = .screenSaver
        window.contentView = NSHostingView(rootView: SwiftUIAboutView())
        
        self.init(window: window)
    }
    
    override func showWindow(_ sender: Any?) {
        super.showWindow(sender)
    }
}

#Preview {
    AboutView()
}