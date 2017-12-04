//
//  ByteImage.swift
//  CameraFilter
//
//  Created by Vitaliy Krynytskyy on 04/12/2017.
//  Copyright © 2017 Vitaliy Krynytskyy. All rights reserved.
//

import UIKit

public struct BytePixel {
    private var value: UInt8
    
    public init(value : UInt8) {
        self.value = value
    }
    
    //red
    public var C: UInt8 {
        get { return value }
        set {
            let v = max(min(newValue, 255), 0)
            value = v
        }
    }
    
    public var Cf: Double {
        get { return Double(self.C) / 255.0 }
        set { self.C = UInt8(max(min(newValue, 1.0), 0.0) * 255.0) }
    }
}

public struct ByteImage {
    public var pixels: UnsafeMutableBufferPointer<BytePixel>
    public var width: Int
    public var height: Int
    
    public init?(image: UIImage) {
        guard let cgImage = image.cgImage else {
            return nil
        }
        
        width = Int(image.size.width)
        height = Int(image.size.height)
        
        let bytesPerRow = width * 1
        let imageData = UnsafeMutablePointer<BytePixel>.allocate(capacity: width * height)
        
        let colorSpace = CGColorSpaceCreateDeviceGray()
        
        let bitmapInfo: UInt32 = CGBitmapInfo().rawValue
        
        guard let imageContext = CGContext(data: imageData, width: width, height: height, bitsPerComponent: 8, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo) else {
            return nil
        }
        
        imageContext.draw(cgImage, in: CGRect(origin: .zero, size: image.size))
        
        pixels = UnsafeMutableBufferPointer<BytePixel>(start: imageData, count: width * height)
    }
    
    
    public init(width: Int, height: Int) {
        let image = ByteImage.newUIImage(width: width, height: height)
        self.init(image: image)!
    }
    
    public func clone() -> ByteImage {
        let cloneImage = ByteImage(width: self.width, height: self.height)
        for y in 0..<height {
            for x in 0..<width {
                let index = y * width + x
                cloneImage.pixels[index] = self.pixels[index]
            }
        }
        return cloneImage
    }
    
    public func toUIImage() -> UIImage? {
        let colorSpace = CGColorSpaceCreateDeviceGray()
        let bitmapInfo: UInt32 = CGBitmapInfo().rawValue
        let bytesPerRow = width * 1
        
        
        guard let imageContext = CGContext(data: pixels.baseAddress, width: width, height: height, bitsPerComponent: 8, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo, releaseCallback: nil, releaseInfo: nil) else {
            return nil
        }
        guard let cgImage = imageContext.makeImage() else {
            return nil
        }
        
        let image = UIImage(cgImage: cgImage)
        return image
    }
    
    public func pixel(x : Int, _ y : Int) -> BytePixel? {
        guard x >= 0 && x < width && y >= 0 && y < height else {
            return nil
        }
        
        let address = y * width + x
        return pixels[address]
    }
    
    public mutating func pixel(x : Int, _ y : Int, _ pixel: BytePixel) {
        guard x >= 0 && x < width && y >= 0 && y < height else {
            return
        }
        
        let address = y * width + x
        pixels[address] = pixel
    }
    
    public mutating func process( functor : ((BytePixel) -> BytePixel) ) {
        for y in 0..<height {
            for x in 0..<width {
                let index = y * width + x
                pixels[index] = functor(pixels[index])
            }
        }
    }
    
    private static func newUIImage(width: Int, height: Int) -> UIImage {
        let size = CGSize(width: CGFloat(width), height: CGFloat(height));
        UIGraphicsBeginImageContextWithOptions(size, true, 0);
        UIColor.black.setFill()
        UIRectFill(CGRect(x: 0, y: 0, width: size.width, height: size.height))
        let image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        return image!
    }
}

extension UInt8 {
    public func toBytePixel() -> BytePixel {
        return BytePixel(value: self)
    }
}



