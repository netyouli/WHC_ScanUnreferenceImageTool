//
//  ViewController.swift
//  WHC_ScanUnreferenceImageTool
//
//  Created by WHC on 16/7/1.
//  Copyright © 2016年 WHC. All rights reserved.
//  Github <https://github.com/netyouli/WHC_ScanUnreferenceImageTool>
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
// VERSON (1.0.7)
import Cocoa

enum WHCScanProjectType {
    case iOS
    case android
}


class ViewController: NSViewController {
    
    @IBOutlet weak var directoryText: NSTextField!
    @IBOutlet weak var openDirectoryButton: NSButton!
    @IBOutlet weak var resultView: NSScrollView!
    @IBOutlet var resultContentView: NSTextView!
    @IBOutlet weak var scanButton: NSButton!
    @IBOutlet weak var progressLabel: NSTextField!
    @IBOutlet weak var processBar: NSProgressIndicator!
    
    @IBOutlet weak var iOSRadio: NSButton!
    @IBOutlet weak var androidRadio: NSButton!
    
    fileprivate var filePathArray = [String]()
    fileprivate var imageNameArray = [String]()
    fileprivate var imageFileNameMap = [String: String]()
    
    fileprivate var noReferenceImageNameArray = [String]()
    fileprivate let fileManager = FileManager.default
    fileprivate var scanProjectType = WHCScanProjectType.iOS
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        processBar.maxValue = 1.0
        processBar.minValue = 0.0
        resultContentView.backgroundColor = NSColor(red: 40.0 / 255.0, green: 40.0 / 255.0, blue: 40.0 / 255.0, alpha: 1.0)
    }
    
    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }

    private func setResultContent(content: String?) {
        if content != nil {
            let attrContent = NSMutableAttributedString(string: content!)
            resultContentView.textStorage?.setAttributedString(attrContent)
            resultContentView.textStorage?.font = NSFont.systemFont(ofSize: 14)
            resultContentView.textStorage?.foregroundColor = NSColor.orange
            resultContentView.scroll(NSPoint(x: 0, y: resultContentView.textContainer!.containerSize.height))
        }
    }
    
    @IBAction func clickCheckUpdate(_ sender: NSButton) {
        NSWorkspace.shared().open(URL(string: "https://github.com/netyouli/WHC_ScanUnreferenceImageTool")!)
    }
    
    @IBAction func clickAbout(_ sender: NSButton) {
        NSWorkspace.shared().open(URL(string: "https://github.com/netyouli/")!)
    }
    
    @IBAction func clickOpenDirectory(_ sender: NSButton) {
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = false
        openPanel.canChooseDirectories = true
        if openPanel.runModal() == NSModalResponseOK {
            self.directoryText.stringValue = (openPanel.directoryURL?.path)!
        }
    }
    
    @IBAction func clickRadio(_ sender: NSButton) {
        
    }
    
    @IBAction func clickStartScan(_ sender: NSButton) {
        sender.isEnabled = false
        if (iOSRadio.state == 1) {
            scanProjectType = .iOS
        }else {
            scanProjectType = .android
        }
        setResultContent(content: "")
        self.processBar.doubleValue = 0;
        if self.directoryText.stringValue.characters.count > 0 {
            self.filePathArray.removeAll()
            self.imageNameArray.removeAll()
            self.imageFileNameMap.removeAll()
            let directoryFileNameArray = try! fileManager.contentsOfDirectory(atPath: self.directoryText.stringValue)
            DispatchQueue.global().async(execute: {
                self.execScan(directoryFileNameArray, path: self.directoryText.stringValue)
                self.processBar.doubleValue = 0;
                let imageCount = self.imageNameArray.count
                for (index,imageName) in self.imageNameArray.enumerated() {
                    var isReference = false
                    DispatchQueue.main.async(execute: {
                        self.processBar.doubleValue = Double(index + 1) / Double(imageCount)
                    })
                    for filePath in self.filePathArray {
                        DispatchQueue.main.async(execute: {
                            self.progressLabel.stringValue = filePath
                        })
                        let bookData = try! Data(contentsOf: URL(fileURLWithPath: filePath), options: NSData.ReadingOptions.mappedIfSafe);
                        let fileContent = NSString(data: bookData, encoding: String.Encoding.utf8.rawValue)
                        if fileContent != nil {
                            switch self.scanProjectType {
                                case .android:
                                    if fileContent!.contains("@drawable/" + imageName) ||
                                       fileContent!.contains("R.drawable." + imageName) {
                                        isReference = true
                                        break
                                    }
                                case .iOS:
                                    if fileContent!.contains("\"" + imageName) {
                                        isReference = true
                                        break
                                    }
                            }
                        }
                    }
                    if !isReference {
                        self.noReferenceImageNameArray.append(imageName)
                        let originTxt = self.resultContentView.string == nil ? "" : self.resultContentView.string!
                        DispatchQueue.main.sync(execute: {
                            var noReferenceImageName = ">>>>> " + self.imageFileNameMap[imageName]!
                            if noReferenceImageName.hasSuffix(".imageset") {
                                noReferenceImageName = ">>>>> " + imageName + "      [该图片删除请去项目的Images.xcassets里删除]"
                            }
                            self.setResultContent(content: originTxt + noReferenceImageName + "\n")
                        })
                    }
                }
                DispatchQueue.main.async {
                    sender.isEnabled = true
                    let alert = NSAlert()
                    alert.messageText = "恭喜您WHC已经帮你扫描完成了,是否要把扫描日志保存到文件？"
                    alert.addButton(withTitle: "保存")
                    alert.addButton(withTitle: "取消")
                    alert.beginSheetModal(for: self.view.window!, completionHandler: { (modalResponse) in
                        if modalResponse == 1000 {
                            let savaPanel = NSSavePanel()
                            savaPanel.message = "Choose the path to save the document"
                            savaPanel.allowedFileTypes = ["txt"]
                            savaPanel.allowsOtherFileTypes = false
                            savaPanel.canCreateDirectories = true
                            savaPanel.beginSheetModal(for: self.view.window!, completionHandler: {[unowned self] (code) in
                                if code == 1 {
                                    do {
                                        let originTxt = self.resultContentView.string == nil ? "" : self.resultContentView.string!
                                        try originTxt.write(toFile: savaPanel.url!.path, atomically: true, encoding: String.Encoding(rawValue: String.Encoding.utf8.rawValue))
                                    }catch {
                                        print("写文件异常")
                                    }
                                }
                            })
                        }
                    })
                }
            })
        }else {
            sender.isEnabled = true
            let alert = NSAlert()
            alert.messageText = "恭喜您WHC提示您请选择扫描项目目录"
            alert.addButton(withTitle: "确定")
            alert.runModal()
        }
    }
    
    fileprivate func execScan(_ directoryFileNameArray :[String]!, path: String!) {
        if directoryFileNameArray != nil {
            for (_, fileName) in directoryFileNameArray.enumerated() {
                var isDirectory = ObjCBool(true)
                let pathName = path + "/" + fileName
                let exist = fileManager.fileExists(atPath: pathName, isDirectory: &isDirectory)
                if exist && isDirectory.boolValue && !fileName.hasSuffix(".imageset") && !fileName.hasSuffix(".bundle") && fileName != "AppIcon.appiconset" && fileName != "LaunchImage.launchimage" {
                    let tempDirectoryFileNameArray = try! fileManager.contentsOfDirectory(atPath: pathName)
                    self.execScan(tempDirectoryFileNameArray, path: pathName)
                }else {
                    if fileName.contains(".png") || fileName.contains(".jpg") ||
                       fileName.contains(".jpeg") || fileName.contains(".gif") || fileName.contains(".imageset") {
                        let name = (fileName as NSString)
                        switch scanProjectType {
                            case .android:
                                let suffRange = name.range(of: ".")
                                if suffRange.location != NSNotFound {
                                    let imageName = name.substring(to: suffRange.location)
                                    if !self.imageNameArray.contains(imageName) {
                                        self.imageNameArray.append(imageName)
                                        self.imageFileNameMap.updateValue(fileName, forKey: imageName)
                                    }
                                }else {
                                    if !self.imageNameArray.contains(fileName) {
                                        self.imageNameArray.append(fileName)
                                        self.imageFileNameMap.updateValue(fileName, forKey: fileName)
                                    }
                                }
                            case .iOS:
                                var suffRange = name.range(of: "@")
                                if suffRange.location != NSNotFound {
                                    let imageName = name.substring(to: suffRange.location)
                                    if !self.imageNameArray.contains(imageName) {
                                        self.imageNameArray.append(imageName)
                                        self.imageFileNameMap.updateValue(fileName, forKey: imageName)
                                    }
                                }else {
                                    suffRange = name.range(of: ".")
                                    if suffRange.location != NSNotFound {
                                        let imageName = name.substring(to: suffRange.location)
                                        if !self.imageNameArray.contains(imageName) {
                                            self.imageNameArray.append(imageName)
                                            self.imageFileNameMap.updateValue(fileName, forKey: imageName)
                                        }
                                    }else {
                                        if !self.imageNameArray.contains(fileName) {
                                            self.imageNameArray.append(fileName)
                                            self.imageFileNameMap.updateValue(fileName, forKey: fileName)
                                        }
                                    }
                                }
                        }
                        
                    }else if fileName != ".DS_Store" {
                        let name = (fileName as NSString)
                        let suffRange = name.range(of: ".")
                        if suffRange.location != NSNotFound {
                            let suff = name.substring(from: suffRange.location + suffRange.length)
                            switch scanProjectType {
                                case .android:
                                    if suff == "java" || suff == "xml" {
                                        self.filePathArray.append(pathName)
                                    }
                                case .iOS:
                                    if suff == "m" || suff == "swift" || suff == "xib" || suff == "storyboard"{
                                        self.filePathArray.append(pathName)
                                    }
                            }
                            
                        }
                    }
                }
            }
        }
    }
}

