//
//  ViewController.swift
//  CartoonVideo
//
//  Created by Alexandre Brispot on 29/01/15.
//  Copyright (c) 2015 KiwiMobile. All rights reserved.
//

import UIKit
import GPUImage

class ViewController: UIViewController {
    
    @IBOutlet weak var view_preview: GPUImageView!
    @IBOutlet weak var img_capturedImage: UIImageView!
    
    var camera = GPUImageStillCamera()
    var filter = GPUImageSmoothToonFilter()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        view_preview.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "previewTaped"))
        img_capturedImage.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "imageTaped"))
        camera = GPUImageStillCamera(sessionPreset: AVCaptureSessionPresetPhoto, cameraPosition: .Back)
        camera.outputImageOrientation = UIInterfaceOrientation.Portrait
        
        filter.texelHeight = 0.0005
        filter.texelWidth = 0.0005
        filter.blurRadiusInPixels = 2
        filter.threshold = 0.05
        filter.quantizationLevels = 8
        var videoView = view_preview
        videoView.fillMode = kGPUImageFillModePreserveAspectRatioAndFill
        camera.addTarget(filter)
        filter.addTarget(videoView)
    }
    
    override func viewDidAppear(animated: Bool) {
        camera.startCameraCapture()
    }
    
    func previewTaped() {
        camera.capturePhotoAsImageProcessedUpToFilter(filter, withCompletionHandler: {(capturedImage: UIImage!, error: NSError!) in
            self.img_capturedImage.image = capturedImage
            self.img_capturedImage.hidden = false
        })
    }
    
    func imageTaped() {
        img_capturedImage.hidden = true
    }
}

