//
//  PureSwiftUIWindowController.swift
//  ScreenCut
//
//  Created by helinyu on 2024/12/19.
//

import SwiftUI
import KeyboardShortcuts
import ServiceManagement

// MARK: - Pure SwiftUI Window Manager
@MainActor
class PureSwiftUIWindowManager: ObservableObject {
    static let shared = PureSwiftUIWindowManager()
    
    @Published var showPreferences = false
    @Published var showAbout = false
    
    private init() {}
    
    func showPreferencesWindow() {
        showPreferences = true
    }
    
    func hidePreferencesWindow() {
        showPreferences = false
    }
    
    func showAboutWindow() {
        showAbout = true
    }
    
    func hideAboutWindow() {
        showAbout = false
    }
}

// MARK: - Preferences Window Controller
@MainActor
class PureSwiftUIPreferencesWindowController: ObservableObject {
    private let windowManager = PureSwiftUIWindowManager.shared
    
    func showPreferencesWindow() {
        windowManager.showPreferencesWindow()
    }
    
    func hidePreferencesWindow() {
        windowManager.hidePreferencesWindow()
    }
}

// MARK: - About Window Controller
@MainActor
class PureSwiftUIAboutWindowController: ObservableObject {
    private let windowManager = PureSwiftUIWindowManager.shared
    
    func showAboutWindow() {
        windowManager.showAboutWindow()
    }
    
    func hideAboutWindow() {
        windowManager.hideAboutWindow()
    }
}

// MARK: - Preferences View
struct PreferencesView: View {
    @ObservedObject private var windowManager = PureSwiftUIWindowManager.shared
    @AppStorage(kSelectedSavePath) private var selectedPath: String = ""
    @AppStorage(kAutoStartup) private var autoStartup: Bool = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("偏好设置")
                .font(.title)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 15) {
                HStack {
                    Text("保存路径:")
                        .frame(width: 100, alignment: .leading)
                    
                    TextField("选择保存路径", text: $selectedPath)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button("选择") {
                        // TODO: Implement file picker
                    }
                }
                
                HStack {
                    Text("开机自启:")
                        .frame(width: 100, alignment: .leading)
                    
                    Toggle("", isOn: $autoStartup)
                        .onChange(of: autoStartup) { newValue in
                            updateAutoStartup(newValue)
                        }
                }
            }
            
            HStack {
                Button("确定") {
                    windowManager.hidePreferencesWindow()
                }
                .buttonStyle(.borderedProminent)
                
                Button("取消") {
                    windowManager.hidePreferencesWindow()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .frame(width: 400, height: 200)
    }
    
    private func updateAutoStartup(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            print("Failed to update auto startup: \(error)")
        }
    }
}

// MARK: - SwiftUI About View
struct SwiftUIAboutView: View {
    @ObservedObject private var windowManager = PureSwiftUIWindowManager.shared
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "scissors")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("ScreenCut")
                .font(.title)
                .fontWeight(.bold)
            
            Text("版本 1.0.0")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text("一个强大的屏幕截图工具")
                .font(.body)
                .multilineTextAlignment(.center)
            
            Button("确定") {
                windowManager.hideAboutWindow()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(width: 300, height: 250)
    }
}

// MARK: - Window Overlay
struct WindowOverlay: View {
    @ObservedObject private var windowManager = PureSwiftUIWindowManager.shared
    
    var body: some View {
        ZStack {
            if windowManager.showPreferences {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        windowManager.hidePreferencesWindow()
                    }
                
                VStack {
                    Spacer()
                    PreferencesView()
                        .background(Color(.windowBackgroundColor))
                        .cornerRadius(10)
                        .shadow(radius: 10)
                    Spacer()
                }
            }
            
            if windowManager.showAbout {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        windowManager.hideAboutWindow()
                    }
                
                VStack {
                    Spacer()
                    SwiftUIAboutView()
                        .background(Color(.windowBackgroundColor))
                        .cornerRadius(10)
                        .shadow(radius: 10)
                    Spacer()
                }
            }
        }
    }
}

// MARK: - Preview
struct WindowOverlay_Previews: PreviewProvider {
    static var previews: some View {
        WindowOverlay()
    }
}