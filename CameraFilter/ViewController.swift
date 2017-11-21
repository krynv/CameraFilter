//
//  ViewController.swift
//  CameraFilter
//
//  Created by Vitaliy Krynytskyy on 29/10/2017.
//  Copyright © 2017 Vitaliy Krynytskyy. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate, UITabBarDelegate {
    
    var captureSession = AVCaptureSession()
    var backCamera: AVCaptureDevice?
    var frontCamera: AVCaptureDevice?
    var currentCamera: AVCaptureDevice?
    
    var photoOutput: AVCapturePhotoOutput?
    var orientation: AVCaptureVideoOrientation = .portrait
    
    let context = CIContext()
    
    @IBOutlet weak var filteredImage: UIImageView!
    
    @IBOutlet weak var tabBar: UITabBar!
    @IBOutlet weak var moreButton: UITabBarItem!
    
    @IBAction func toggleFlashlight(_ sender: UISwitch) {
        
        switch sender.isOn {
            
        case true:
            print("turn on flashlight")
            
            do {
                try currentCamera?.lockForConfiguration()
                currentCamera?.torchMode = .on
                currentCamera?.unlockForConfiguration()
            }
            catch {
                print("Cannot enable flashlight")
            }
            
            break
            
        default:
            print("turn off flashlight")
            do {
                try currentCamera?.lockForConfiguration()
                currentCamera?.torchMode = .off
                currentCamera?.unlockForConfiguration()
            }
            catch {
                print("Cannot enable flashlight")
            }
            
            break
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tabBar.delegate = self
        
        setupDevice()
        setupInputOutput()
    }
    
    override func viewDidLayoutSubviews() {
        orientation = AVCaptureVideoOrientation(rawValue: UIApplication.shared.statusBarOrientation.rawValue)!
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if AVCaptureDevice.authorizationStatus(for: AVMediaType.video) != .authorized
        {
            AVCaptureDevice.requestAccess(for: AVMediaType.video, completionHandler:
                { (authorized) in
                    DispatchQueue.main.async
                        {
                            if authorized
                            {
                                self.setupInputOutput()
                            }
                    }
            })
        }
    }
    
    func setupDevice() {
        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [AVCaptureDevice.DeviceType.builtInWideAngleCamera], mediaType: AVMediaType.video, position: AVCaptureDevice.Position.unspecified)
        let devices = deviceDiscoverySession.devices
        
        for device in devices {
            if device.position == AVCaptureDevice.Position.back {
                backCamera = device
            }
            else if device.position == AVCaptureDevice.Position.front {
                frontCamera = device
            }
        }
        
        currentCamera = backCamera
    }
    
    func setupInputOutput() {
        do {
            setupCorrectFramerate(currentCamera: currentCamera!)
            let captureDeviceInput = try AVCaptureDeviceInput(device: currentCamera!)
            captureSession.sessionPreset = AVCaptureSession.Preset.hd1280x720
            if captureSession.canAddInput(captureDeviceInput) {
                captureSession.addInput(captureDeviceInput)
            }
            let videoOutput = AVCaptureVideoDataOutput()
            
            videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "sample buffer delegate", attributes: []))
            if captureSession.canAddOutput(videoOutput) {
                captureSession.addOutput(videoOutput)
            }
            captureSession.startRunning()
        } catch {
            print(error)
        }
    }
    
    func setupCorrectFramerate(currentCamera: AVCaptureDevice) {
        for vFormat in currentCamera.formats {
            //see available types
            //print("\(vFormat) \n")
            
            var ranges = vFormat.videoSupportedFrameRateRanges as [AVFrameRateRange]
            let frameRates = ranges[0]
            
            do {
                //set to 240fps - available types are: 30, 60, 120 and 240 and custom
                // lower framerates cause major stuttering
                if frameRates.maxFrameRate == 240 {
                    try currentCamera.lockForConfiguration()
                    currentCamera.activeFormat = vFormat as AVCaptureDevice.Format
                    //for custom framerate set min max activeVideoFrameDuration to whatever you like, e.g. 1 and 180
                    currentCamera.activeVideoMinFrameDuration = frameRates.minFrameDuration
                    currentCamera.activeVideoMaxFrameDuration = frameRates.maxFrameDuration
                }
            }
            catch {
                print("Could not set active format")
                print(error)
            }
        }
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        connection.videoOrientation = orientation
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue.main)
        
        let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        let cameraImage = CIImage(cvImageBuffer: pixelBuffer!)
        
        DispatchQueue.main.async {
            self.filteredImage.image = self.applyHue(cameraImage: cameraImage)
        }
    }
    
    lazy var optionLauncher: OptionLauncher = {
        let launcher = OptionLauncher()
        launcher.homeController = self
        return launcher
    }()

    func applyHue(cameraImage: CIImage) -> UIImage {
        // Create a place to render the filtered image
        let context = CIContext(options: nil)
        
        // Create a random color to pass to a filter
        let randomColor = [kCIInputAngleKey: 1.5]
        
        // Apply a filter to the image
        let filteredImage = cameraImage.applyingFilter("CIHueAdjust", parameters: randomColor)
        
        // Render the filtered image
        let renderedImage = context.createCGImage(filteredImage, from: filteredImage.extent)
        
        // Return a UIImage
        return UIImage(cgImage: renderedImage!)
    }

    
    func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        
        switch item.tag {
            
        case 0:
            print("do something")
            
            break
            
        case 1:
            print("show options")
            // show options
            optionLauncher.showOptions()
            break
            
        default:
            break
        }
    }
    
    func showControllerForOption(option: Option) {
        let dummyOptionViewController = UIViewController()
        dummyOptionViewController.view.backgroundColor = UIColor.white
        dummyOptionViewController.navigationItem.title = option.name.rawValue
        navigationController?.navigationBar.tintColor = UIColor.white
        navigationController?.navigationBar.titleTextAttributes = [NSAttributedStringKey.foregroundColor: UIColor.white]
        navigationController?.pushViewController(dummyOptionViewController, animated: true)
    }
    
}
