//
//  SettingsLauncher.swift
//  CameraFilter
//
//  Created by Vitaliy Krynytskyy on 14/11/2017.
//  Copyright © 2017 Vitaliy Krynytskyy. All rights reserved.
//

import UIKit

class Option: NSObject {
    let name: OptionName
    let imageName: String
    
    init(name: OptionName, imageName: String) {
        self.name = name
        self.imageName = imageName
    }
}

//type safe way to change label text
enum OptionName: String {
    case Cancel = "Cancel"
    case ColourPicker = "Colour Picker"
    case SetColourBlindnessMode = "Set Colour Blindness Mode"
    case FilterColours = "Filter Colours"
    case Settings = "Settings"
    case Dummy = "dummy"
    
}

class OptionLauncher: NSObject, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    let blackView = UIView()
    
    let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = UIColor.white 
        return cv
    }()
    
    let cellId = "cellId"
    let cellHeight: CGFloat = 50
    
    //construct option array
    let options: [Option] = {
        let colourPicker = Option(name: .ColourPicker, imageName: "colour-picker")
        let setColourBlindnessMode = Option(name: .SetColourBlindnessMode, imageName: "colour-blind-mode")
        let filterColours = Option(name: .FilterColours, imageName: "filter-colours")
        let settings = Option(name: .Settings, imageName: "settings")
        let cancelOption = Option(name: .Cancel, imageName: "cancel")
       
        return [colourPicker,
                setColourBlindnessMode,
                filterColours,
                settings,
                cancelOption]
    }()
    
    var homeController: ViewController?
    
    func showOptions() {
        if let window = UIApplication.shared.keyWindow {
            
            blackView.backgroundColor = UIColor(white: 0, alpha: 0.5)
            
            blackView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleDismiss)))
            
            window.addSubview(blackView)
            window.addSubview(collectionView)
            
            let height: CGFloat = CGFloat(options.count) * cellHeight
            let y = window.frame.height - height
            collectionView.frame = CGRect(origin: CGPoint(x: 0, y: window.frame.height), size: CGSize(width: window.frame.width, height: height))
            
            
            blackView.frame = window.frame
            blackView.alpha = 0
            
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
                self.blackView.alpha = 1
                
                self.collectionView.frame = CGRect(x: 0, y: y, width: self.collectionView.frame.width, height: self.collectionView.frame.height)
            }, completion: nil)
        }
    }
    
    @objc func handleDismiss(option: Option) {
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
            
            self.blackView.alpha = 0
            
            if let window = UIApplication.shared.keyWindow {
                self.collectionView.frame = CGRect(x: 0, y: window.frame.height, width: self.collectionView.frame.width, height: self.collectionView.frame.height)
            }
            
            print("dismissed")
            
            
        }) { (completed: Bool) in
            if option.name != .Cancel {

                print("show view for \(option.name)")
                self.homeController?.showControllerForOption(option: option)
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return options.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! OptionCell
        
        let option = options[indexPath.item]
        
        cell.option = option
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.width, height: cellHeight)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
         let option = self.options[indexPath.item]
        
        handleDismiss(option: option)
        
    }
    
    override init() {
        super.init()
        
        collectionView.dataSource = self
        collectionView.delegate = self
        
        //register cell
        collectionView.register(OptionCell.self, forCellWithReuseIdentifier: cellId)
    }
}
