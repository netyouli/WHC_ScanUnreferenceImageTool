//
//  ViewController.swift
//  WHC_ScanUnreferenceImageTool
//
//  Created by WHC on 16/7/1.
//  Copyright © 2016年 WHC. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {
    
    @IBOutlet var directoryText: NSTextField!
    @IBOutlet var openDirectoryButton: NSButton!
    @IBOutlet var resultContentView: NSTextField!
    @IBOutlet var scanButton: NSButton!
    @IBOutlet var progressLabel: NSTextField!
    @IBOutlet var processBar: NSProgressIndicator!
    
    private var filePathArray = [String]()
    private var imageNameArray = [String]()
    
    private var noReferenceImageNameArray = [String]()
    let fileManager = NSFileManager.defaultManager()
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    override var representedObject: AnyObject? {
        didSet {
            // Update the view, if already loaded.
        }
    }
    
    @IBAction func clickOpenDirectory(sender: NSButton) {
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = false
        openPanel.canChooseDirectories = true
        if openPanel.runModal() == NSModalResponseOK {
            self.directoryText.stringValue = (openPanel.directoryURL?.path)!
        }
    }
    
    @IBAction func clickStartScan(sender: NSButton) {
        self.processBar.maxValue = 1.0
        self.processBar.minValue = 0.0
        if self.directoryText.stringValue.characters.count > 0 {
            self.filePathArray.removeAll()
            self.imageNameArray.removeAll()
            let directoryFileNameArray = try! fileManager.contentsOfDirectoryAtPath(self.directoryText.stringValue)
            dispatch_async(dispatch_get_global_queue(0, 0), {
                self.execScan(directoryFileNameArray, path: self.directoryText.stringValue)
                self.processBar.doubleValue = 0;
                let imageCount = self.imageNameArray.count
                for (index,imageName) in self.imageNameArray.enumerate() {
                    var isReference = false
                    dispatch_async(dispatch_get_main_queue(), {
                        self.processBar.doubleValue = Double(index) / Double(imageCount)
                    })
                    for filePath in self.filePathArray {
                        dispatch_async(dispatch_get_main_queue(), {
                            self.progressLabel.stringValue = filePath
                        })
                        let bookData = try! NSData(contentsOfFile: filePath, options: NSDataReadingOptions.DataReadingMappedIfSafe);
                        let fileContent = NSString(data: bookData, encoding: NSUTF8StringEncoding)
                        if fileContent != nil {
                            if fileContent!.containsString("\"" + imageName) {
                                isReference = true
                                break
                            }
                        }
                    }
                    if !isReference {
                        self.noReferenceImageNameArray.append(imageName)
                        dispatch_async(dispatch_get_main_queue(), {
                            self.resultContentView.stringValue = self.resultContentView.stringValue + imageName + "\n"
                        })
                    }
                }
            })
        }
    }
    
    private func execScan(directoryFileNameArray :[String]!, path: String!) {
        if directoryFileNameArray != nil {
            for (_, fileName) in directoryFileNameArray.enumerate() {
                var isDirectory: ObjCBool = ObjCBool(true)
                let pathName = path + "/" + fileName
                let exist = fileManager.fileExistsAtPath(pathName, isDirectory: &isDirectory)
                if exist && Bool(isDirectory) {
                    let tempDirectoryFileNameArray = try! fileManager.contentsOfDirectoryAtPath(pathName)
                    self.execScan(tempDirectoryFileNameArray, path: pathName)
                }else {
                    if fileName.containsString(".png") || fileName.containsString(".jpg") {
                        let name = (fileName as NSString)
                        var suffRange = name.rangeOfString("@")
                        if suffRange.location != NSNotFound {
                            if !self.imageNameArray.contains(name.substringToIndex(suffRange.location)) {
                                self.imageNameArray.append(name.substringToIndex(suffRange.location))
                            }
                        }else {
                            suffRange = name.rangeOfString(".")
                            if suffRange.location != NSNotFound {
                                if !self.imageNameArray.contains(name.substringToIndex(suffRange.location)) {
                                    self.imageNameArray.append(name.substringToIndex(suffRange.location))
                                }
                            }else {
                                if !self.imageNameArray.contains(fileName) {
                                    self.imageNameArray.append(fileName)
                                }
                            }
                        }
                    }else if fileName != ".DS_Store" {
                        let name = (fileName as NSString)
                        let suffRange = name.rangeOfString(".")
                        if suffRange.location != NSNotFound {
                            let suff = name.substringFromIndex(suffRange.location + suffRange.length)
                            if suff == "m" || suff == "swift" || suff == "xib"{
                                self.filePathArray.append(pathName)
                            }
                        }
                    }
                }
            }
        }
    }
}

