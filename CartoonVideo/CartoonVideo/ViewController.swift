//
//  ViewController.swift
//  CartoonVideo
//
//  Created by Alexandre Brispot on 29/01/15.
//  Copyright (c) 2015 KiwiMobile. All rights reserved.
//

import UIKit
import GPUImage
import Photos

enum Mode {
    case EFFECT, PREVIEW, EDITION, SHOOTING, TRANSITIONING
}

enum ShootingMode: Int {
    case PHOTO = 0, SQUARE_PHOTO//, VIDEO, SLOW_MOTION,  PANORAMIC_PHOTO, TIMELAPSE
    var description : String {
        get {
            switch rawValue {
            case 0:
                return "PHOTO"
            case 1:
                return "SQUARE"
            default:
                return ""
            }
        }
    }
}

enum FlashMode {
    case ON, OFF
}

class ViewController: UIViewController, AKPickerViewDelegate, AKPickerViewDataSource {
    
    @IBOutlet var view_header: UIView!
    @IBOutlet var view_footer: UIView!
    @IBOutlet var img_imageLibrary: UIImageView!
    @IBOutlet var btn_shoot: UIButton!
    @IBOutlet var btn_flash: UIButton!
    @IBOutlet var btn_switchCamera: UIButton!
    @IBOutlet var picker_shootingMode: AKPickerView!
    
    var camera = GPUImageStillCamera()
    var filter = GPUImageSmoothToonFilter()
    var effectViewWidth = (UIScreen.mainScreen().bounds.width - 16) / 3
    var effectViewHeight: CGFloat!
    var view_preview = GPUImageView()
    
    var currentMode: Mode = .PREVIEW {
        didSet {
            modeChanged()
        }
    }
    var currentSootingMode: ShootingMode = .PHOTO {
        didSet {
            shootingModeChanged()
        }
    }
    
    func numberOfItemsInPickerView(pickerView: AKPickerView) -> Int {
        return 2
    }
    
    func pickerView(pickerView: AKPickerView, titleForItem item: Int) -> NSString {
        return ShootingMode(rawValue: item)!.description
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //INIT SHOOTIN MODE PICKER
        picker_shootingMode.delegate = self
        picker_shootingMode.dataSource = self
        picker_shootingMode.selectItem(0, animated: false)
        picker_shootingMode.textColor = UIColor(red: 48/255, green: 93/255, blue: 145/255, alpha: 1)
        picker_shootingMode.highlightedTextColor = UIColor(red: 74/255, green: 144/255, blue: 226/255, alpha: 1)
        picker_shootingMode.font = UIFont(name: "HelveticaNeue-Light", size: 16.0)!
        picker_shootingMode.highlightedFont = UIFont(name: "HelveticaNeue-Light", size: 16.0)!
        picker_shootingMode.interitemSpacing = 12.0
        
        //INIT HEIGHT OF VIEWS FOR .EFFECT MODE
        effectViewHeight = (UIScreen.mainScreen().bounds.height - 16 - view_header.frame.height - view_footer.frame.height) / 3
        
        // A REFAIRE PLUS PROPREMENT
        view_preview.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "previewTaped"))
        let rightSwipeReconizer = UISwipeGestureRecognizer(target: self, action: "previewSwipedRight")
        rightSwipeReconizer.direction = UISwipeGestureRecognizerDirection.Right
        let leftSwipeReconizer = UISwipeGestureRecognizer(target: self, action: "previewSwipedLeft")
        leftSwipeReconizer.direction = UISwipeGestureRecognizerDirection.Left
        view_preview.addGestureRecognizer(rightSwipeReconizer)
        view_preview.addGestureRecognizer(leftSwipeReconizer)
        camera = GPUImageStillCamera(sessionPreset: AVCaptureSessionPresetPhoto, cameraPosition: .Back)
        camera.outputImageOrientation = UIInterfaceOrientation.Portrait
        filter.texelHeight = 0.0005
        filter.texelWidth = 0.0005
        filter.blurRadiusInPixels = 2
        filter.threshold = 0.05
        filter.quantizationLevels = 8
        view_preview.fillMode = kGPUImageFillModePreserveAspectRatioAndFill
        camera.addTarget(filter)
        filter.addTarget(view_preview)
        
        camera.horizontallyMirrorFrontFacingCamera = true //FOR A MORE NATURAL FEELING
        
        //GETTING LAST TAKEN PIC IN THE LIBRARY
        let fetchOptions: PHFetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        let fetchResult = PHAsset.fetchAssetsWithMediaType(PHAssetMediaType.Image, options: fetchOptions)
        if (fetchResult.lastObject != nil) {
            let lastAsset: PHAsset = fetchResult.lastObject as! PHAsset
            PHImageManager.defaultManager().requestImageForAsset(lastAsset, targetSize: self.img_imageLibrary.bounds.size, contentMode: PHImageContentMode.AspectFill, options: PHImageRequestOptions(), resultHandler: { (result, info) -> Void in
                self.img_imageLibrary.image = result
            })
        }
        view.insertSubview(view_preview, belowSubview: view_header)
    }
    
    override func viewDidAppear(animated: Bool) {
        setUIForShootingMode(0.0)
        camera.startCameraCapture()
    }
    
    func modeChanged() {
        switch currentMode {
        case .TRANSITIONING:
            //BLUR THE PREVIEW
            btn_flash.enabled = false
            btn_shoot.enabled = false
            btn_switchCamera.enabled = false
            img_imageLibrary.userInteractionEnabled = false
        case .PREVIEW:
            btn_flash.enabled = true
            btn_shoot.enabled = true
            btn_switchCamera.enabled = true
            img_imageLibrary.userInteractionEnabled = true
            UIView.animateWithDuration(0.2, animations: {_ in
                self.btn_shoot.alpha = 1
                self.img_imageLibrary.alpha = 1
                self.picker_shootingMode.alpha = 1
            })
        case .SHOOTING:
            btn_flash.enabled = false
            btn_shoot.enabled = false
            btn_switchCamera.enabled = false
            img_imageLibrary.userInteractionEnabled = false
        case .EFFECT:
            UIView.animateWithDuration(0.2, animations: {_ in
                self.view_preview.frame = CGRectMake(0, self.view_header.frame.height, self.effectViewWidth, self.effectViewHeight)
                self.btn_shoot.alpha = 0
                self.img_imageLibrary.alpha = 0
                self.picker_shootingMode.alpha = 0
                })
        case .EDITION:
            break
        default:
            break
        }
    }
    
    func shootingModeChanged() {
        currentMode = .TRANSITIONING
        setUIForShootingMode()
    }
    
    func setUIForShootingMode(animationDuration: NSTimeInterval = 0.4) {
        switch currentSootingMode {
        case .PHOTO:
            camera.removeAllTargets()
            filter.removeAllTargets()
            camera.addTarget(filter)
            filter.addTarget(view_preview)
            UIView.animateWithDuration(animationDuration, animations: {_ in
                self.view_preview.frame.size.height = self.view_footer.frame.origin.y - self.view_header.frame.height
                self.view_preview.frame.size.width = UIScreen.mainScreen().bounds.width
                self.view_preview.center.y = (self.view_header.frame.height + self.view_footer.frame.origin.y) / 2.0
                }, completion: {_ in
                    self.currentMode = .PREVIEW
            })
        case .SQUARE_PHOTO:
            camera.removeAllTargets()
            filter.removeAllTargets()
            let cropFilter = GPUImageCropFilter(cropRegion: CGRectMake(0, 0.125, 1, 0.75))
            cropFilter.addTarget(filter)
            camera.addTarget(cropFilter)
            filter.addTarget(view_preview)
            UIView.animateWithDuration(animationDuration, animations: {_ in
                self.view_preview.frame.size.width = UIScreen.mainScreen().bounds.width
                self.view_preview.frame.size.height = UIScreen.mainScreen().bounds.width
                self.view_preview.center.y = (self.view_header.frame.height + self.view_footer.frame.origin.y) / 2.0
                }, completion: {_ in
                    self.currentMode = .PREVIEW
            })
        default:
            currentMode = .PREVIEW
        }
    }
    
    @IBAction func btn_clicked_switchCamera(sender: AnyObject) {
        //USE .TRANSITION MODE TO BLUR THE VIEW
        let reductionFactor: CGFloat = 5
        UIGraphicsBeginImageContext(CGSizeMake(view_preview.frame.size.width/reductionFactor, view_preview.frame.size.height/reductionFactor))
        view_preview.drawViewHierarchyInRect(CGRectMake(0, 0, view_preview.frame.size.width/reductionFactor, view_preview.frame.size.height/reductionFactor), afterScreenUpdates: true)
        let transitionImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        let transitionImageView = UIImageView()
        transitionImageView.frame = CGRectMake(0, 0, view_preview.frame.width, view_preview.frame.height)
        transitionImageView.image = transitionImage
        
        let blurEffect = UIBlurEffect(style: UIBlurEffectStyle.Light)
        let effectView = UIVisualEffectView(effect: blurEffect)
        effectView.frame = transitionImageView.frame
        transitionImageView.addSubview(effectView)
        view_preview.addSubview(transitionImageView)
        
        UIView.transitionWithView(view_preview, duration: 0.4, options: UIViewAnimationOptions.TransitionFlipFromLeft, animations: {_ in
            }, completion: {_ in
                self.camera.rotateCamera()
                usleep(100000)
                transitionImageView.removeFromSuperview()
        })
    }
    
    @IBAction func btn_clicked_flash(sender: AnyObject) {
        let device = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
        if device.hasTorch {
            do {
                try device.lockForConfiguration()
            } catch _ {
            }
            if (device.torchMode == AVCaptureTorchMode.On) {
                device.torchMode = AVCaptureTorchMode.Off
                btn_flash.setTitle("Off", forState: .Normal)
            } else {
                do {
                    try device.setTorchModeOnWithLevel(1.0)
                } catch _ {
                }
                btn_flash.setTitle("On", forState: .Normal)
            }
            device.unlockForConfiguration()
        }
    }
    
    @IBAction func btn_clicked_effects(sender: AnyObject) {
        if currentMode == .EFFECT {
            currentMode = .PREVIEW
            setUIForShootingMode()
        } else {
            currentMode = .EFFECT
        }
    }
    
    @IBAction func btn_clicked_shoot(sender: AnyObject) {
        currentMode = .SHOOTING
        let imageView = UIImageView()
        imageView.frame = view_preview.frame
        imageView.contentMode = .ScaleAspectFill
        
        camera.capturePhotoAsImageProcessedUpToFilter(filter, withCompletionHandler: {(capturedImage: UIImage!, error: NSError!) in
            imageView.image = capturedImage
            self.view.addSubview(imageView)
            
            UIView.animateWithDuration(0.2, delay: 0.4, options: [], animations: {_ in
                imageView.frame.size = self.img_imageLibrary.frame.size
                imageView.frame.origin = CGPointMake(self.view_footer.frame.origin.x + self.img_imageLibrary.frame.origin.x, self.view_footer.frame.origin.y + self.img_imageLibrary.frame.origin.y)
                }, completion: {_ in
                    self.img_imageLibrary.image = imageView.image
                    imageView.removeFromSuperview()
                    self.currentMode = .PREVIEW
            })
            UIImageWriteToSavedPhotosAlbum(capturedImage, self, nil, nil)
        })
    }
    
    func previewTaped() {
        if currentMode == .EFFECT {
            setUIForShootingMode()
        }
    }
    
    func previewSwipedRight() {
        if currentSootingMode.rawValue > 0 {
            currentSootingMode = ShootingMode(rawValue: currentSootingMode.rawValue - 1)!
            picker_shootingMode.selectItem(currentSootingMode.rawValue, animated: true)
        }
    }
    
    func previewSwipedLeft() {
        if currentSootingMode.rawValue < 1 {
            currentSootingMode = ShootingMode(rawValue: currentSootingMode.rawValue + 1)!
            picker_shootingMode.selectItem(currentSootingMode.rawValue, animated: true)
        }
    }
}

