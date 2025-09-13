//
//  PreferenceSettingsWindowController.swift
//  ScreenCut
//
//  Created by helinyu on 2024/12/19.
//

import SwiftUI
import AppKit
import KeyboardShortcuts
import Sparkle
import ServiceManagement

struct SwiftUIPreferenceSettingsView: View {
    
    enum PathSelectionType: String, CaseIterable {
        case defaultS, desktopS, documentS, imageS
        var id: Self { self }
        
        var path: String {
            switch self {
            case .defaultS:
                return defaultSavepath
            case .desktopS:
                return FileManager.default.urls(for:.desktopDirectory, in:.userDomainMask).first?.path ?? ""
            case .documentS:
                return FileManager.default.urls(for:.documentDirectory, in:.userDomainMask).first?.path ?? ""
            case .imageS:
                return FileManager.default.urls(for:.picturesDirectory, in:.userDomainMask).first?.path ?? ""
            }
        }
        
        var name: String {
            switch self {
            case .defaultS:
                return "ScreenCut"
            case .desktopS:
                return kDesktoptext
            case .documentS:
                return kDocumentText
            case .imageS:
                return kImageText
            }
        }
    }
    
    @AppStorage(kplayAudioOfFinished) private var playAudioOfFinished: Bool = false
    @AppStorage(ksavePasteboardSameTime) private var savePasteboardSameTime: Bool = true
    @AppStorage(konlySaveInPasteBoard) private var onlySaveInPasteBoard: Bool = false
    @AppStorage(kautoUpdate) private var autoUpdate: Bool = false
    @AppStorage(kautoLaunchByComputer) private var autoLaunchByComputer: Bool = false
    @AppStorage(kSelectedSavePath) private var lastSelectedPath: String = defaultSavepath
    
    @State private var selectOption: PathSelectionType = .defaultS
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(alignment: .center) {
                Spacer().frame(width: 20)
                Image("logo-img-white")
                    .resizable()
                    .frame(width: 60, height: 60)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("偏好设置")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("请使用前完成一下设置")
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                }
                
                Spacer()
            }
            .frame(height: 80)
            .frame(maxWidth: .infinity)
            .background(Color.black)
            
            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Keyboard Shortcuts
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("全屏截图快捷键: ")
                                .frame(width: kLeftTextWidth, alignment: .trailing)
                            KeyboardShortcuts.Recorder("", name: .fullScreenCut)
                        }
                        
                        HStack {
                            Text("区域截图快捷键: ")
                                .frame(width: kLeftTextWidth, alignment: .trailing)
                            KeyboardShortcuts.Recorder("", name: .selectedAreaCut)
                        }
                    }
                    
                    Divider()
                    
                    // Screenshot Settings
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .top) {
                            Text("截屏时: ")
                                .frame(width: kLeftTextWidth, alignment: .trailing)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Spacer().frame(width: kRightFirstSpaceWidth)
                                    Toggle("截图完成后播放声音", isOn: $playAudioOfFinished)
                                        .toggleStyle(CheckboxToggleStyle())
                                }
                            }
                        }
                    }
                    
                    Divider()
                    
                    // Save Settings
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .top) {
                            Text("图片保存的位置:")
                                .frame(width: kLeftTextWidth, alignment: .trailing)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text(self.lastSelectedPath)
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                    
                                    Button("修改") {
                                        let openPanel = NSOpenPanel()
                                        openPanel.canChooseFiles = false
                                        openPanel.canChooseDirectories = true
                                        openPanel.allowedContentTypes = []
                                        openPanel.allowsOtherFileTypes = false
                                        
                                        if openPanel.runModal() == NSApplication.ModalResponse.OK {
                                            if let path = openPanel.urls.first?.path {
                                                self.lastSelectedPath = path
                                            }
                                        }
                                    }
                                    .buttonStyle(.bordered)
                                }
                                
                                Toggle("同时保存在粘贴版", isOn: $savePasteboardSameTime)
                                    .toggleStyle(CheckboxToggleStyle())
                                
                                Toggle("只保存到粘贴版", isOn: $onlySaveInPasteBoard)
                                    .toggleStyle(CheckboxToggleStyle())
                            }
                        }
                    }
                    
                    Divider()
                    
                    // App Settings
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Spacer().frame(width: kLeftTextWidth)
                            Spacer().frame(width: kRightFirstSpaceWidth)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Toggle("开机自动启动", isOn: $autoLaunchByComputer)
                                    .toggleStyle(CheckboxToggleStyle())
                                    .onChange(of: autoLaunchByComputer) { oldValue, newValue in
                                        do {
                                            if newValue {
                                                try SMAppService.mainApp.register()
                                            } else {
                                                try SMAppService.mainApp.unregister()
                                            }
                                        } catch {
                                            print("Failed to update launch at login setting: \(error)")
                                        }
                                    }
                                
                                Toggle("自动检查更新", isOn: $autoUpdate)
                                    .toggleStyle(CheckboxToggleStyle())
                                
                                Button {
                                    NotificationCenter.default.post(name: Notification.Name("update.app.noti"), object: "")
                                } label: {
                                    Text("检查更新")
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                    }
                    
                    Spacer().frame(height: 30)
                }
                .padding(.horizontal, 40)
                .padding(.vertical, 20)
            }
        }
        .frame(width: 560, height: 500)
        .background(Color.white)
    }
}

class PreferenceSettingsWindowController: NSWindowController {
    
    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 560, height: 500),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        
        window.center()
        window.setFrameAutosaveName("偏好设置")
        window.level = .normal + 1
        window.contentView = NSHostingView(rootView: SwiftUIPreferenceSettingsView())
        
        self.init(window: window)
    }
    
    override func showWindow(_ sender: Any?) {
        super.showWindow(sender)
    }
}

#Preview {
    PreferenceSettingsView()
}