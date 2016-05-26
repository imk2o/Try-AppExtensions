//
//  ActionViewController.swift
//  ActionExtension
//
//  Created by k2o on 2016/05/21.
//  Copyright © 2016年 Yuichi Kobayashi. All rights reserved.
//

import UIKit
import MobileCoreServices

class ActionViewController: UIViewController {

    @IBOutlet weak var webView: UIWebView!
    @IBOutlet weak var captureButton: UIBarButtonItem!

    override func viewDidLoad() {
        super.viewDidLoad()

        // 1つのアイテムを抽出(Info.plistの設定により制限されている)
        guard
            let item = self.extensionContext?.inputItems.first as? NSExtensionItem,
            let itemProvider = item.attachments?.first as? NSItemProvider
        else {
            return
        }

        // アイテムからURLを抽出
        if itemProvider.hasItemConformingToTypeIdentifier(kUTTypeURL as String) {
            itemProvider.loadItemForTypeIdentifier(kUTTypeURL as String, options: nil) { [weak self] (item, error) in
                if let error = error {
                    self?.extensionContext?.cancelRequestWithError(error)
                } else if let URL = item as? NSURL {
                    dispatch_async(dispatch_get_main_queue()) {
                        self?.loadURL(URL)
                    }
                }
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func cancel() {
        self.extensionContext?.completeRequestReturningItems(nil, completionHandler: nil)
    }
    
    @IBAction func capture() {
        self.captureWebViewAndComplete()
    }
    
    private func loadURL(URL: NSURL) {
        self.webView.loadRequest(NSURLRequest(URL: URL))
    }

    // Webページをキャプチャする
    // http://hack.sonix.asia/archives/936
    private func captureWebViewAndComplete() {
        let originalFrame = self.webView.frame
        
        var frame = self.webView.frame;
        frame.size.height = self.webView.sizeThatFits(UIScreen.mainScreen().bounds.size).height
        self.webView.frame = frame

        UIGraphicsBeginImageContextWithOptions(frame.size, false, 0)
        guard let context = UIGraphicsGetCurrentContext() else {
            fatalError()
        }
        self.webView.layer.renderInContext(context)
        let image: UIImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        // restore frame
        self.webView.frame = originalFrame
        
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(ActionViewController.image(_:didFinishSavingWithError:contextInfo:)), nil)
    }

    // キャプチャ画像保存完了ハンドラ
    func image(image: UIImage, didFinishSavingWithError error: NSError?, contextInfo: UnsafeMutablePointer<Void>) {
        if let error = error {
            self.extensionContext?.cancelRequestWithError(error)
        } else {
            self.extensionContext?.completeRequestReturningItems(nil, completionHandler: nil)
        }
    }
}

extension ActionViewController: UIWebViewDelegate {
    func webViewDidFinishLoad(webView: UIWebView) {
        self.captureButton.enabled = true
    }
}
