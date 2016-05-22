//
//  PhotoEditingViewController.swift
//  PhotoEditingExtension
//
//  Created by k2o on 2016/05/22.
//  Copyright © 2016年 Yuichi Kobayashi. All rights reserved.
//

import UIKit
import Photos
import PhotosUI

class PhotoEditingViewController: UIViewController, PHContentEditingController {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var slider: UISlider!

    // エクステンション(効果)のIDとバージョン
    private let formatIdentifier = "com.example.myphotofilter"
    private let formatVersion = "1.0.0"

    // 入力は完了まで握っておく必要がある
    var input: PHContentEditingInput!

    // プレビュー用入力(CoreImage)
    private var ciInputImage: CIImage?
    // プレビューおよび出力用コンテキスト(CoreImage)
    private var ciContext: CIContext = {
        return CIContext()
    }()
    
    private var currentValue: Float {
        return self.slider.value
    }
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func sliderDidChangeValue(sender: UISlider) {
        self.updatePreview()
    }
    
    // MARK: - PHContentEditingController

    func canHandleAdjustmentData(adjustmentData: PHAdjustmentData?) -> Bool {
        guard let adjustmentData = adjustmentData else {
            return false
        }

        // IDとバージョンが一致しているか？
        return adjustmentData.formatIdentifier == self.formatIdentifier && adjustmentData.formatVersion == self.formatVersion
    }

    func startContentEditingWithInput(contentEditingInput: PHContentEditingInput?, placeholderImage: UIImage) {
        self.input = contentEditingInput

        // 前回編集時の設定したパラメータを取得し、スライダーに反映
        let parameters = NSKeyedUnarchiver.unarchiveObjectWithData(self.input.adjustmentData.data) as? [String: AnyObject]
        if let inputIntensity = parameters?["inputIntensity"] as? Float {
            self.slider.value = inputIntensity
        }

        // プレビュー用の入力CI画像を生成しておく
        if let CGImage = self.input.displaySizeImage?.CGImage {
            self.ciInputImage = CIImage(CGImage: CGImage)
        }
        
        self.updatePreview()
    }

    func finishContentEditingWithCompletionHandler(completionHandler: ((PHContentEditingOutput!) -> Void)!) {
        // Render and provide output on a background queue.
        dispatch_async(dispatch_get_global_queue(CLong(DISPATCH_QUEUE_PRIORITY_DEFAULT), 0)) {

            let output = PHContentEditingOutput(contentEditingInput: self.input)
            let inputIntensity = self.currentValue

            // 編集パラメータを構築
            output.adjustmentData = PHAdjustmentData(
                formatIdentifier: self.formatIdentifier,
                formatVersion: self.formatVersion,
                data: NSKeyedArchiver.archivedDataWithRootObject(["inputIntensity": inputIntensity])
            )

            // オリジナル画像を取得し、フィルタを適用
            guard
                let inputImageURL = self.input.fullSizeImageURL,
                let ciInputImage = CIImage(contentsOfURL: inputImageURL)
            else {
                return	// FIXME
            }
            let filteredImage = ciInputImage.createVignetteFilteredImage(inputIntensity, context: self.ciContext)

            // JPEGファイルを出力 (TODO: CIImageから直接JPEGファイルを出力する方法はあるのか？)
            guard let JPEGData = UIImageJPEGRepresentation(filteredImage, 0.8) else {
                return	// FIXME
            }
            JPEGData.writeToURL(output.renderedContentURL, atomically: true)
            
            // Call completion handler to commit edit to Photos.
            completionHandler?(output)
        }
    }

    var shouldShowCancelConfirmation: Bool {
        // Determines whether a confirmation to discard changes should be shown to the user on cancel.
        // (Typically, this should be "true" if there are any unsaved changes.)
        return false
    }

    func cancelContentEditing() {
        // Clean up temporary files, etc.
        // May be called after finishContentEditingWithCompletionHandler: while you prepare output.
    }
    
    // MARK: - misc

    private func updatePreview() {
        guard let ciInputImage = self.ciInputImage else {
            return
        }

        self.imageView.image = ciInputImage.createVignetteFilteredImage(self.currentValue, context: self.ciContext)
    }
}

private extension CIImage {
    func createVignetteFilteredImage(inputIntensity: Float, context: CIContext) -> UIImage {
        let ciFilteredImage = self.imageByApplyingFilter("CIVignette", withInputParameters: ["inputIntensity": inputIntensity])
        
        // CIImageから直接UIImageを生成すると、Aspect Fitが適用されない？
        // http://stackoverflow.com/questions/15878060/setting-uiimageview-content-mode-after-applying-a-cifilter
        //return UIImage(CIImage: ciFilteredImage)
        let filteredImage = context.createCGImage(ciFilteredImage, fromRect: ciFilteredImage.extent)
        return UIImage(CGImage: filteredImage)
    }
}
