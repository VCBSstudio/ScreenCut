//
//  PureSwiftUIToast.swift
//  ScreenCut
//
//  Created by helinyu on 2024/12/19.
//

import SwiftUI

// MARK: - Pure SwiftUI Toast
struct PureSwiftUIToast: View {
    let message: String
    @State private var isVisible = false
    
    var body: some View {
        HStack {
            Text(message)
                .foregroundColor(.white)
                .font(.system(size: 14))
                .padding()
        }
        .background(Color.black.opacity(0.8))
        .cornerRadius(8)
        .opacity(isVisible ? 1 : 0)
        .scaleEffect(isVisible ? 1 : 0.8)
        .animation(.easeInOut(duration: 0.3), value: isVisible)
        .onAppear {
            withAnimation {
                isVisible = true
            }
            
            // Auto hide after 2 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation {
                    isVisible = false
                }
            }
        }
    }
}

// MARK: - Toast Manager
@MainActor
class ToastManager: ObservableObject {
    static let shared = ToastManager()
    
    @Published var currentToast: String?
    @Published var isShowing = false
    
    private init() {}
    
    func show(_ message: String) {
        currentToast = message
        isShowing = true
        
        // Auto hide after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.hide()
        }
    }
    
    func hide() {
        isShowing = false
        currentToast = nil
    }
}

// MARK: - Toast Container
struct ToastContainer: View {
    @StateObject private var toastManager = ToastManager.shared
    
    var body: some View {
        ZStack {
            if toastManager.isShowing, let message = toastManager.currentToast {
                VStack {
                    Spacer()
                    PureSwiftUIToast(message: message)
                        .padding()
                }
            }
        }
    }
}

// MARK: - Toast Extension
extension View {
    func showToast(_ message: String) {
        ToastManager.shared.show(message)
    }
}
