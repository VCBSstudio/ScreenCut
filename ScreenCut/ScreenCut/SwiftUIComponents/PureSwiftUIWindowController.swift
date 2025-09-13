//
//  PureSwiftUIWindowController.swift
//  ScreenCut
//
//  Created by helinyu on 2024/12/19.
//

import SwiftUI
import AppKit
import KeyboardShortcuts
import ServiceManagement

// MARK: - Pure SwiftUI Window Controller
@MainActor
class PureSwiftUIWindowController: ObservableObject {
    private var window: NSWindow?
    
    func showWindow<T: View>(_ view: T, title: String = "", size: CGSize = CGSize(width: 400, height: 300)) {
        // Close existing window if any
        window?.close()
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: size.width, height: size.height),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        window.center()
        window.title = title
        window.contentView = NSHostingView(rootView: view)
        window.makeKeyAndOrderFront(nil)
        
        self.window = window
    }
    
    func hideWindow() {
        window?.close()
        window = nil
    }
}

// MARK: - About Window Controller
class PureSwiftUIAboutWindowController: PureSwiftUIWindowController {
    func showAboutWindow() {
        showWindow(
            SwiftUIAboutView(),
            title: "关于 ScreenCut",
            size: CGSize(width: 540, height: 200)
        )
    }
}

// MARK: - Preferences Window Controller
class PureSwiftUIPreferencesWindowController: PureSwiftUIWindowController {
    func showPreferencesWindow() {
        showWindow(
            SwiftUIPreferenceSettingsView(),
            title: "偏好设置",
            size: CGSize(width: 560, height: 500)
        )
    }
}

// MARK: - SwiftUI About View
struct SwiftUIAboutView: View {
    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .center) {
                Image("logo-img-white")
                VStack(alignment: .leading) {
                    Text("ScreenCut")
                        .fontWeight(.bold)
                        .font(.title)
                    Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                        .font(.system(size: 14))
                }
                Spacer()
            }
            .frame(width: 540, height: 80.0)
            .background(.black)
            .foregroundColor(.white)
            
            VStack(alignment: .leading) {
                Text("你所使用的版本是最新版本")
                
                Spacer()
                Spacer()
                Spacer()
                Spacer()
                
                Text("使用本软件意味着你了解并同意遵循服务条款")
                Spacer()
                Text("软件使用部分开源代码和公共领域代码，并遵循相应的协议。")
                Spacer()
                Text("helinyu 版权所有 @2024-未来")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                Spacer()
            }
            .padding(EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 0))
        }
        .frame(width: 540, height: 200)
    }
}

// MARK: - SwiftUI Preferences View
struct SwiftUIPreferenceSettingsView: View {
    enum PathSelectionType: String, CaseIterable {
        case defaultS, desktopS, documentS, imageS
        var id: Self { self }
        
        var path: String {
            switch self {
            case .defaultS:
                return defaultSavepath
            case .desktopS:
                return FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first?.path ?? ""
            case .documentS:
                return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.path ?? ""
            case .imageS:
                return FileManager.default.urls(for: .picturesDirectory, in: .userDomainMask).first?.path ?? ""
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
        VStack(alignment: .leading) {
            HStack(alignment: .center) {
                Spacer().frame(width: 20)
                Image("logo-img-white")
                VStack(alignment: .leading) {
                    Text("偏好设置")
                        .fontWeight(.bold)
                        .font(.title)
                    Text("请使用前完成一下设置")
                        .font(.system(size: 14))
                }
                Spacer()
            }
            .frame(height: 80.0)
            .background(.black)
            .foregroundColor(.white)
            
            VStack(alignment: .leading) {
                HStack() {
                    Text("全屏截图快捷键: ")
                        .frame(width: kLeftTextWidth, alignment: .trailing)
                    KeyboardShortcuts.Recorder("", name: .fullScreenCut)
                }
                HStack() {
                    Text("区域截图快捷键: ")
                        .frame(width: kLeftTextWidth, alignment: .trailing)
                    KeyboardShortcuts.Recorder("", name: .selectedAreaCut)
                }
                HStack(alignment: .top) {
                    Text("截屏时: ")
                        .frame(width: kLeftTextWidth, alignment: .trailing)
                    VStack(alignment: .leading) {
                        HStack {
                            Spacer().frame(width: kRightFirstSpaceWidth)
                            Toggle("截图完成后播放声音", isOn: $playAudioOfFinished)
                                .toggleStyle(CheckboxToggleStyle())
                        }
                    }
                }
                
                Divider()
                Spacer().frame(height: 10.0)
                
                HStack(alignment: .top) {
                    Text("图片保存的位置:")
                        .frame(width: kLeftTextWidth, alignment: .trailing)
                    VStack(alignment: .leading) {
                        HStack {
                            Text(self.lastSelectedPath)
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
                        }
                        Toggle("同时保存在粘贴版", isOn: $savePasteboardSameTime)
                            .toggleStyle(CheckboxToggleStyle())
                        Toggle("只保存到粘贴版", isOn: $onlySaveInPasteBoard)
                            .toggleStyle(CheckboxToggleStyle())
                    }
                }
                
                Spacer().frame(height: 10.0)
                Divider()
                Spacer().frame(height: 10.0)
                
                HStack(alignment: .top) {
                    VStack(alignment: .leading) {
                        HStack {
                            Spacer().frame(width: kLeftTextWidth)
                            Spacer().frame(width: kRightFirstSpaceWidth)
                            Toggle("开机自动启动", isOn: $autoLaunchByComputer)
                                .toggleStyle(CheckboxToggleStyle())
                        }
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
                        HStack {
                            Spacer().frame(width: kLeftTextWidth)
                            Spacer().frame(width: kRightFirstSpaceWidth)
                            Toggle("自动检查更新", isOn: $autoUpdate)
                                .toggleStyle(CheckboxToggleStyle())
                        }
                    }
                }
                
                HStack {
                    Spacer().frame(width: kLeftTextWidth)
                    Spacer().frame(width: kRightFirstSpaceWidth)
                    Button {
                        NotificationCenter.default.post(name: Notification.Name("update.app.noti"), object: "")
                    } label: {
                        Text("检查更新")
                    }
                }
                
                Spacer().frame(height: 30.0)
            }
            .padding(EdgeInsets(top: 0, leading: 40, bottom: 0, trailing: 0))
        }
    }
}
