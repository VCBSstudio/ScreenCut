import ScreenCaptureKit
import Cocoa
import FileKit
import SwiftUI
import Vision
import Moya
import Combine


var cancellables = Set<AnyCancellable>()


func findCurrentScreen(id: CGDirectDisplayID, displays:[SCDisplay]) -> SCDisplay? {
    for display in displays {
        if (id == display.displayID) {
            return display
        }
    }
    return nil
}

// 这个是查找Screen的内容
func findCurrentScreen(id: CGDirectDisplayID, screens:[NSScreen]) -> NSScreen? {
    for screen in screens {
        if let screenID = screen.deviceDescription[NSDeviceDescriptionKey(rawValue: "NSScreenNumber")] as? CGDirectDisplayID,
           id == screenID {
            return screen
        }
    }
    return nil
}


class ScreenCut {
    
    static var availableContent: SCShareableContent?
    static var screenArea: NSRect?
    
    func closeAllWindow(except: String = "") {
        for w in NSApp.windows.filter({
            $0.title != "Item-0" && $0.title != ""
            && !$0.title.lowercased().contains(".qma")
            && !$0.title.contains(except) }) { w.close() }
    }
    
    static  func updateScreenContent() async {
        SCShareableContent.getExcludingDesktopWindows(false, onScreenWindowsOnly: false) { content, error in
            if let error = error {
                switch error {
                case SCStreamError.userDeclined: Auth.requestPermissions()
                default: print("Error: failed to fetch available content: ", error.localizedDescription)
                }
                return
            }
            
            ScreenCut.availableContent = content
        }
    }
    
    //    保存整张图片
    @MainActor static func saveScreenFullImage() {
        let content = ScreenCut.availableContent
        guard let displays = content?.displays else {
            return
        }
        let display: SCDisplay = findCurrentScreen(
            id: SwiftUIAppDelegate.shared.screentId!,
            displays: displays
        )!
        let contentFilter = SCContentFilter(display: display, excludingWindows: [])
        let configuration = SCStreamConfiguration()
        configuration.width = display.width
        configuration.height = display.height
        SCScreenshotManager.captureImage(contentFilter: contentFilter, configuration: configuration) { image, error in
            print("lt -- image : eror : %@", error.debugDescription)
            guard let img = image else {
                print(" : %@", error.debugDescription)
                return
            }
            self.onlyPasteboardOfSameTime(img)
        }
    }
    
    //     保存图片
    @MainActor static func saveImageToFile(_ image: CGImage) {
        let imgName = Date.getNameByDate()
        let curPath = "file://" + VarExtension.createTargetDirIfNotExit() + "/" + imgName + ".png"
        let destinationURL: CFURL = URL(string: curPath)! as CFURL
        let destination = CGImageDestinationCreateWithURL(destinationURL, kUTTypePNG, 1, nil)
        guard let destination = destination else {
//            print("保存路径没有创建成功")
            return
        }
        CGImageDestinationAddImage(destination, image, nil)
        
        if CGImageDestinationFinalize(destination) {
            print("保存成功路径: \(destinationURL)")
        } else {
            print("保存失败")
        }
    }
    
    // 显示识别的内容
    static func showOCR() {
        self.cutSelectionAreaImage()
            .flatMap { cgImage in
                self.getTexWithOCR(cgImage)
            }
            .receive(on: DispatchQueue.main)  // 切换到主线程
            .sink(
                receiveCompletion: { completion in
                    print("lt -- \(completion)")
                },
                receiveValue: { text in
                    print("lt -- text: \(text)")
                    OCRViewWindowController(transText: text).showWindow(nil)
                }
            )
            .store(in: &cancellables)
    }
    
    
    static  func copyImageToPasteboard(_ img: CGImage) {
        let image: NSImage = cgImageToNSImage(img)
        // 创建粘贴板
        let pasteboard = NSPasteboard.general
        
        // 清空当前粘贴板
        pasteboard.clearContents()
        
        // 将图片数据转换为 PNG 数据
        if let tiffData = image.tiffRepresentation,
           let bitmapRep = NSBitmapImageRep(data: tiffData),
           let pngData = bitmapRep.representation(using: .png, properties: [:]) {
            // 将 PNG 数据写入粘贴板
            pasteboard.setData(pngData, forType: .png)
        }
    }
    
    static func cgImageToNSImage(_ cgImage: CGImage) -> NSImage {
        // 创建 NSImage
        let nsImage = NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
        return nsImage
    }
    
    //    识别并且翻译： 业务代码了，可以修改
    static func ocrThenTransRequest()  {
        self.cutSelectionAreaImage()
            .flatMap { cgImage in
                self.getTexWithOCR(cgImage) ?? Fail(error: NSError(domain: "Error", code: -1, userInfo: nil)).eraseToAnyPublisher()
            }
            .flatMap { text in
                self.transforRequest(text) ?? Fail(error: NSError(domain: "Error", code: -1, userInfo: nil)).eraseToAnyPublisher()
            }
            .receive(on: DispatchQueue.main) // 切换到主线程
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        print("操作完成")
                    case .failure(let error):
                        print("发生错误: \(error)")
                    }
                },
                receiveValue: { text in
                    print("转换后的文本: \(text)")
                    DispatchQueue.main.async {
                        TranslatorViewWindowController(transText: text).showWindow(nil)
                    }
                }
            )
            .store(in: &cancellables)
    }
    
//     combine method base methods
    
    // 通过图片识别出来文本
    static func getTexWithOCR(_ image: CGImage?) -> AnyPublisher<String, NSError> {
        return Future<String, NSError> { promise in
            guard let cgImage = image else {
                promise(.failure(NSError(domain: "image error", code: -1, userInfo: [NSLocalizedDescriptionKey: "image can not be nil"])))
                return
            }
            
            let request = VNRecognizeTextRequest { request, error in
                guard let results = request.results as? [VNRecognizedTextObservation] else { return }
                var resultText = ""
                for observation in results {
                    if let topCandidate = observation.topCandidates(1).first {
                        print("Recognized text: \(topCandidate.string)")
                        resultText += topCandidate.string
                        resultText += "\n"
                    }
                }
                promise(.success(resultText))
            }
            
            request.recognitionLevel = .accurate
            request.recognitionLanguages = ["zh-Hans"] // 支持简体中文
            
            let handler = VNImageRequestHandler(cgImage: cgImage , options: [:])
            try? handler.perform([request])
        }.eraseToAnyPublisher()
    }
    
    static func transforRequest(_ text: String) -> AnyPublisher<String, NSError> {
        return Future<String, NSError> { promise in
            let urlString = "http://127.0.0.1:5000/translate" // 应该是本地没有解析localhost，要使用127.0.0.1
            guard let url = URL(string: urlString) else { return }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let parameters: [String: Any] = ["text": text] // 替换为你的参数
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: [])
            } catch {
                promise(.failure(NSError(domain: "encode error", code: -1, userInfo: [NSLocalizedDescriptionKey: "Error encoding parameters"])))
                return
            }
            
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                do {
                    if let json = try JSONSerialization.jsonObject(with: data!, options: []) as? [String: Any] {
                        print("Response Dictionary: \(json)")
                        let translatedText:String = json["translated_text"] as! String
                        promise(.success(translatedText))
                        
                    } else {
                        promise(.failure(error! as NSError))
                    }
                } catch {
                    print(": \(error)")
                    promise(.failure(NSError(domain: "json error", code: -1, userInfo: [NSLocalizedDescriptionKey: "Error parsing JSON"])))
                }
            }
            
            task.resume()
        }.eraseToAnyPublisher()
    }
    
    static func cutSelectionAreaImage() -> AnyPublisher<CGImage, NSError> {
        return Future<CGImage, NSError> { promise in
            DispatchQueue.main.async {
                guard let displays = ScreenCut.availableContent?.displays else {
                    promise(.failure(NSError(domain: "display error", code: -1, userInfo: [NSLocalizedDescriptionKey: "没有获取设备"])))
                    return
                }
                let display: SCDisplay = findCurrentScreen(
                    id: SwiftUIAppDelegate.shared.screentId!,
                    displays: displays
                )!
//            print("lt -- displays : \(displays)")
            let contentFilter = SCContentFilter(display: display, excludingWindows: [])
            let configuration = SCStreamConfiguration()
            
            // 翻转 Y 坐标
            let flippedY = CGFloat(display.height) - ScreenCut.screenArea!.origin.y - ScreenCut.screenArea!.size.height
            configuration.sourceRect = CGRectMake( ScreenCut.screenArea!.origin.x, flippedY, ScreenCut.screenArea!.size.width, ScreenCut.screenArea!.size.height)
            configuration.destinationRect = CGRectMake( 0, 0, ScreenCut.screenArea!.size.width, ScreenCut.screenArea!.size.height)
            configuration.scalesToFit = true
            configuration.width = Int(ScreenCut.screenArea!.size.width)
            configuration.height = Int(ScreenCut.screenArea!.size.height)
            configuration.preservesAspectRatio = true
//            print("lt -- source \(configuration.sourceRect) desc:\(configuration.destinationRect)")
            
                SCScreenshotManager.captureImage(contentFilter: contentFilter, configuration: configuration) { image, error in
//                print("lt -- image \(String(describing: image)): eror : %@", error.debugDescription)
                    
                    if error == nil && image != nil {
                        promise(.success(image!))
                    }
                    else {
                        promise(.failure((error ?? NSError(domain: "capture failure", code: -1, userInfo: [NSLocalizedDescriptionKey: "获取截图数据失败"])) as NSError))
                    }
                }
            }
        }.eraseToAnyPublisher()
    }
    
    //     这个要修改
    static func cutImage() {
        self.cutSelectionAreaImage().sink { completion in
            switch completion {
                case .finished:
                    print("No error.")
                case .failure(let error):
                    print("Error occurred: \(error)")
                }
        } receiveValue: { cgImage in
            self.onlyPasteboardOfSameTime(cgImage)
        }.store(in: &cancellables)
    }
    
    static func onlyPasteboardOfSameTime(_ cgImage: CGImage) {
        DispatchQueue.main.async {
            if UserDefaults.standard.bool(forKey: kplayAudioOfFinished) {
//                print("lt -- 播放音效")
                NSSound(named: "Ping")?.play()
            }
            if UserDefaults.standard.bool(forKey: konlySaveInPasteBoard) {
                ScreenCut.copyImageToPasteboard(cgImage)
            }
            else {
                ScreenCut.saveImageToFile(cgImage)
                ScreenCut.copyImageToPasteboard(cgImage)
            }
        }
    }
}
