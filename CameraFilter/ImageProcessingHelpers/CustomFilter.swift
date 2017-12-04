//
//  CustomFilter.swift
//  CameraFilter
//
//  Created by Vitaliy Krynytskyy on 20/11/2017.
//  Copyright © 2017 Vitaliy Krynytskyy. All rights reserved.
//

import CoreImage
import UIKit

class CustomFilter: CIFilter {
    @objc dynamic var inputImage : CIImage?
    
    override public var outputImage: CIImage! {
        get {
            if let inputImage = self.inputImage {
                let args = [inputImage as AnyObject]
                return createCustomKernel().apply(extent: inputImage.extent, arguments: args)
            } else {
                return nil
            }
        }
    }
    
    func createCustomKernel() -> CIColorKernel {
        let kernelString =
            "kernel vec4 chromaKey( __sample s) { \n" +
                "  vec4 newPixel = s.rgba;" +
                "  newPixel[0] = 1.0;" +
                "  newPixel[2] = newPixel[2] / 2.0;" +
                "  return newPixel;\n" +
        "}"
        
        return CIColorKernel(source: kernelString)!
    }
}

