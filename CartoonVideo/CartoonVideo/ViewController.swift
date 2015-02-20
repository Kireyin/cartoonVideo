//
//  ViewController.swift
//  CartoonVideo
//
//  Created by Alexandre Brispot on 29/01/15.
//  Copyright (c) 2015 KiwiMobile. All rights reserved.
//

import UIKit
import GPUImage

enum Mode {
    case EFFECT, PREVIEW//, EDITION, SHOOTING
}

enum ShootingMode {
    case PHOTO//, VIDEO, SLOW_MOTION, SQUARE_PHOTO, PANORAMIC_PHOTO, TIMELAPSE
}

class ViewController: UIViewController {
    
    @IBOutlet var view_header: UIView!
    @IBOutlet var view_footer: UIView!
    @IBOutlet weak var view_preview: GPUImageView!
    @IBOutlet weak var img_capturedImage: UIImageView!
    @IBOutlet var img_imageLibrary: UIImageView!
    @IBOutlet var btn_shoot: UIButton!
    @IBOutlet var btn_flash: UIButton!
    @IBOutlet var btn_switchCamera: UIButton!
    
    var camera = GPUImageStillCamera()
    var filter = GPUImageSmoothToonFilter()
    var effectViewWidth = (UIScreen.mainScreen().bounds.width - 16) / 3
    var effectViewHeight: CGFloat!
    
    var currentMode: Mode = .PREVIEW
//    var currentSootingMode: ShootingMode = .PHOTO
    
    override func viewDidLoad() {
        super.viewDidLoad()
        effectViewHeight = (UIScreen.mainScreen().bounds.height - 16 - view_header.frame.height - view_footer.frame.height) / 3

        img_capturedImage.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "imageTaped"))
        view_preview.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "previewTaped"))
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
        
        camera.horizontallyMirrorFrontFacingCamera = true
    }
    
    @IBAction func btn_clicked_switchCamera(sender: AnyObject) {
        
        let reductionFactor: CGFloat = 5
        UIGraphicsBeginImageContext(CGSizeMake(view_preview.frame.size.width/reductionFactor, view_preview.frame.size.height/reductionFactor))
        view_preview.drawViewHierarchyInRect(CGRectMake(0, 0, view_preview.frame.size.width/reductionFactor, view_preview.frame.size.height/reductionFactor), afterScreenUpdates: true)
        let transitionImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        img_capturedImage.image = transitionImage
        
        let blurEffect = UIBlurEffect(style: UIBlurEffectStyle.Light)
        let effectView = UIVisualEffectView(effect: blurEffect)
        effectView.frame = img_capturedImage.frame
        img_capturedImage.addSubview(effectView)
        img_capturedImage.hidden = false
        
        UIView.transitionWithView(view_preview, duration: 0.4, options: UIViewAnimationOptions.TransitionFlipFromLeft, animations: {_ in
            }, completion: {_ in
                self.camera.rotateCamera()
                usleep(500000)
                self.img_capturedImage.hidden = true
                effectView.removeFromSuperview()
        })
    }
    
    @IBAction func btn_clicked_flash(sender: AnyObject) {
        let device = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
        if device.hasTorch {
            device.lockForConfiguration(nil)
            if (device.torchMode == AVCaptureTorchMode.On) {
                device.torchMode = AVCaptureTorchMode.Off
                btn_flash.setTitle("Off", forState: .Normal)
            } else {
                device.setTorchModeOnWithLevel(1.0, error: nil)
                btn_flash.setTitle("On", forState: .Normal)
            }
            device.unlockForConfiguration()
        }
    }
    
    @IBAction func btn_clicked_effects(sender: AnyObject) {
        
        if currentMode == .EFFECT {
            UIView.animateWithDuration(0.2, animations: {_ in
                self.view_preview.frame = UIScreen.mainScreen().bounds
                self.btn_shoot.alpha = 1
                self.img_imageLibrary.alpha = 1
                }, completion: {_ in
                    self.btn_shoot.enabled = true
                    self.img_imageLibrary.userInteractionEnabled = true
                    self.currentMode = .PREVIEW
            })
        } else {
            self.btn_shoot.enabled = false
            self.img_imageLibrary.userInteractionEnabled = false
            UIView.animateWithDuration(0.2, animations: {_ in
                self.view_preview.frame = CGRectMake(0, self.view_header.frame.height, self.effectViewWidth, self.effectViewHeight)
                self.btn_shoot.alpha = 0
                self.img_imageLibrary.alpha = 0
                self.currentMode = .EFFECT
            })
        }
    }
    
    @IBAction func btn_clicked_shoot(sender: AnyObject) {
        camera.capturePhotoAsImageProcessedUpToFilter(filter, withCompletionHandler: {(capturedImage: UIImage!, error: NSError!) in
            self.img_capturedImage.image = capturedImage
            self.img_capturedImage.hidden = false
        })
        UIView.animateWithDuration(0.2, delay: 0.4, options: nil, animations: {_ in
            self.img_capturedImage.frame.size = self.img_imageLibrary.frame.size
            self.img_capturedImage.frame.origin = CGPointMake(self.view_footer.frame.origin.x + self.img_imageLibrary.frame.origin.x, self.view_footer.frame.origin.y + self.img_imageLibrary.frame.origin.y)
            }, completion: {_ in
                self.img_capturedImage.hidden = true
                self.img_capturedImage.frame = UIScreen.mainScreen().bounds
        })
    }
    
    func previewTaped() {
        UIView.animateWithDuration(0.2, animations: {_ in
            self.view_preview.frame = UIScreen.mainScreen().bounds
            self.btn_shoot.alpha = 1
            self.img_imageLibrary.alpha = 1
            }, completion: {_ in
                self.btn_shoot.enabled = true
                self.img_imageLibrary.userInteractionEnabled = true
                self.currentMode = .PREVIEW
        })
    }
    
    override func viewDidAppear(animated: Bool) {
        camera.startCameraCapture()
    }

    func imageTaped() {
        img_capturedImage.hidden = true
    }
}

