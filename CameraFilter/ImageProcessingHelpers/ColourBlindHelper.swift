//
//  ColourBlind.swift
//  CameraFilter
//
//  Created by Vitaliy Krynytskyy on 22/11/2017.
//  Copyright © 2017 Vitaliy Krynytskyy. All rights reserved.
//

import Foundation

enum ColourBlindType: String {
    case deuteranomaly = "deuteranomaly"
    case protanopia = "protanopia"
    case deuteranopia = "deuteranopia"
    case protanomaly = "protanomaly"
}

class CBColourBlindTypes: NSObject {
   class func getModifiedColour(_ type: ColourBlindType, red: Float, green: Float, blue: Float) -> Array<Float> {
        switch type {
        case .deuteranomaly:
            return [(red*0.80)+(green*0.20)+(blue*0),
                    (red*0.25833)+(green*0.74167)+(blue*0),
                    (red*0)+(green*0.14167)+(blue*0.85833)]
        case .protanopia:
            return [(red*0.56667)+(green*0.43333)+(blue*0),
                    (red*0.55833)+(green*0.44167)+(blue*0),
                    (red*0)+(green*0.24167)+(blue*0.75833)]
        case .deuteranopia:
            return [(red*0.625)+(green*0.375)+(blue*0),
                    (red*0.7)+(green*0.3)+(blue*0),
                    (red*0)+(green*0.3)+(blue*0.7)]
        case .protanomaly:
            return [(red*0.81667)+(green*0.18333)+(blue*0.0),
                    (red*0.33333)+(green*0.66667)+(blue*0.0),
                    (red*0.0)+(green*0.125)+(blue*0.875)]
        }
        
    }
    
}




