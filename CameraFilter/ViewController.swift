//
//  ViewController.swift
//  CameraFilter
//
//  Created by Vitaliy Krynytskyy on 29/10/2017.
//  Copyright © 2017 Vitaliy Krynytskyy. All rights reserved.
//

import UIKit
import AVFoundation
import CoreGraphics

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate, UITabBarDelegate {
    
    var captureSession = AVCaptureSession()
    var backCamera: AVCaptureDevice?
    var frontCamera: AVCaptureDevice?
    var currentCamera: AVCaptureDevice?
    
    var photoOutput: AVCapturePhotoOutput?
    var orientation: AVCaptureVideoOrientation = .portrait
    
    let context = CIContext()
    
    @IBOutlet weak var filteredImage: UIImageView!
    
    let recognizer = UITapGestureRecognizer()
    
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
        
        filteredImage.isUserInteractionEnabled = true
        
        recognizer.addTarget(self, action: #selector(ViewController.screenHasbeenTapped))
        
        filteredImage.addGestureRecognizer(recognizer)
    }
    
    @objc func screenHasbeenTapped() {
        print("screen tapped")
        if recognizer.state == UIGestureRecognizerState.recognized {
            print(recognizer.location(in: filteredImage))
            
            var location = recognizer.location(in: filteredImage)
            var colour:UIColor = getPixelColorAtPoint(point: location, sourceView: filteredImage)
            print(colour)
            
            var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
            colour.getRed(&r, green: &g, blue: &b, alpha: &a)
            var red: Int = Int(r * 255.0)
            var green: Int = Int(g * 255.0)
            var blue: Int = Int(b * 255.0)
            let myString = "R: \(red) G: \(green) B: \(blue)"
            
            print(myString)
            
            self.showToast(message: myString as String)
        }
        
        
    }
    
    func getPixelColorAtPoint(point: CGPoint, sourceView: UIView) -> UIColor {
        let pixel = UnsafeMutablePointer<CUnsignedChar>.allocate(capacity: 4)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        let context = CGContext(data: pixel, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4, space: colorSpace, bitmapInfo: bitmapInfo.rawValue)
        
        context!.translateBy(x: -point.x, y: -point.y)
        
        sourceView.layer.render(in: context!)
        let color: UIColor = UIColor(red: CGFloat(pixel[0])/255.0,
                                     green: CGFloat(pixel[1])/255.0,
                                     blue: CGFloat(pixel[2])/255.0,
                                     alpha: CGFloat(pixel[3])/255.0)
        pixel.deallocate(capacity: 4)
        return color
    }
    
    func showToast(message : String) {
        
        let toastLabel = UILabel(frame: CGRect(x: self.view.frame.size.width/2 - 200, y: self.view.frame.size.height-100, width: 400, height: 35))
        toastLabel.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        toastLabel.textColor = UIColor.white
        toastLabel.textAlignment = .center;
        toastLabel.font = UIFont(name: "Montserrat-Light", size: 12.0)
        toastLabel.text = message
        toastLabel.alpha = 1.0
        toastLabel.layer.cornerRadius = 10;
        toastLabel.clipsToBounds  =  true
        self.view.addSubview(toastLabel)
        UIView.animate(withDuration: 4.0, delay: 0.1, options: .curveEaseOut, animations: {
            toastLabel.alpha = 0.0
        }, completion: {(isCompleted) in
            toastLabel.removeFromSuperview()
        })
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
    
    func convert(cmage:CIImage) -> UIImage
    {
        let context:CIContext = CIContext.init(options: nil)
        let cgImage:CGImage = context.createCGImage(cmage, from: cmage.extent)!
        let image:UIImage = UIImage.init(cgImage: cgImage)
        return image
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        connection.videoOrientation = orientation
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue.main)
        
        let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        let cameraImage = CIImage(cvImageBuffer: pixelBuffer!)
        
        let typeOfColourBlindness = ColourBlindType(rawValue: "deuteranomaly")
        
        /* Gets colour from a single pixel - currently 0,0 and converts it into the 'colour blind' version */
        
        //let filteredImage = self.applyFilter(cameraImage: cameraImage, colourBlindness: typeOfColourBlindness!)
        
        let captureImage = convert(cmage: cameraImage)
        
        let colour = captureImage.getPixelColour(pos: CGPoint(x: 0, y: 0))
        
        var redval: CGFloat = 0
        var greenval: CGFloat = 0
        var blueval: CGFloat = 0
        var alphaval: CGFloat = 0
        
        _ = colour.getRed(&redval, green: &greenval, blue: &blueval, alpha: &alphaval)
//        print("Colours are r: \(redval) g: \(greenval) b: \(blueval) a: \(alphaval)")
        let filteredColour = CBColourBlindTypes.getModifiedColour(.deuteranomaly, red: Float(redval), green: Float(greenval), blue: Float(blueval))
//        print(filteredColour)
        
        /* #################################################################################### */
        
        DispatchQueue.main.async {
            // placeholder for now
//            self.filteredImage.image = self.applyFilter(cameraImage: cameraImage, colourBlindness: typeOfColourBlindness!)
            self.filteredImage.image = UIImage(ciImage: cameraImage)
        }
    }
    
    lazy var optionLauncher: OptionLauncher = {
        let launcher = OptionLauncher()
        launcher.homeController = self
        return launcher
    }()

    func applyFilter(cameraImage: CIImage, colourBlindness: ColourBlindType) -> UIImage {

        //do stuff with pixels to render new image
        
        
        /*      Placeholder code for shifting the hue      */
        
        // Create a place to render the filtered image
        let context = CIContext(options: nil)

        // Create filter angle
        let filterAngle = 207 * Double.pi / 180

        // Create a random color to pass to a filter
        let randomColor = [kCIInputAngleKey: filterAngle]

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
