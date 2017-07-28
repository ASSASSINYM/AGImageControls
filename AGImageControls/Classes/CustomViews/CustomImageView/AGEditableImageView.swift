//
//  AGEditableImageView.swift
//  AGPosterSnap
//
//  Created by Michael Liptuga on 17.07.17.
//  Copyright © 2017 Agilie. All rights reserved.
//

import UIKit


protocol AGEditableImageViewDelegate : class {
    func imageDidTouch (imageView : AGEditableImageView)
    func startMoving (imageView : AGEditableImageView)
    func endMoving (imageView : AGEditableImageView, touchLocation : CGPoint)
}

internal struct AGPositionStruct {
    
    var centerPoint     : CGPoint
    var scale           : CGFloat
    var rotateAngle     : CGFloat
    
    init(center : CGPoint, scale: CGFloat, angle : CGFloat) {
        self.centerPoint = center
        self.scale = scale
        self.rotateAngle = angle
    }
}

class AGEditableImageView: UIImageView, UIGestureRecognizerDelegate {

    weak var delegate : AGEditableImageViewDelegate?

    var maskColor : AGColorEditorItem = AGColorEditorItem()
    {
        didSet {
            self.image = self.image!.withRenderingMode(.alwaysTemplate)
            self.tintColor = maskColor.color
            self.alpha = CGFloat(maskColor.currentValue / 100.0)
        }
    }

    var lastMaskColor : AGColorEditorItem? = nil
    
    var lastPosition : AGPositionStruct? = nil
    
    var newPosition : AGPositionStruct? = nil
    {
        didSet
        {
            self.transform = CGAffineTransform.identity.rotated(by: self.newPosition?.rotateAngle ?? 0).scaledBy(x: self.newPosition?.scale ?? 1, y: self.newPosition?.scale ?? 1)
        }
    }
    
    var isActive : Bool = true
//    {
//        didSet {
//            self.backgroundColor = isActive ? UIColor.init(white: 0, alpha: 0.5) : .clear
//        }
//    }
    
    var imageName : String = ""
    
    var type : AGImageEditorTypes = .icons
   
    var settingsType : AGSettingMenuItemTypes {
        get {
            switch self.type {
            case .icons:
                return .iconsAdjustment
            case .shapes:
                return .shapesMaskAdjustment
            default:
                return .textAdjustment
            }
        }
    }

    let imageDefaultSize : CGSize = CGSize(width : 50, height : 50)
    
    func updateImage (scale: CGFloat = 1.0)
    {
        let screenSize = UIScreen.main.bounds.size
        
        let maxScale = max(screenSize.width / self.imageDefaultSize.width, screenSize.height / self.imageDefaultSize.height)
        let currentScale = max(self.frame.size.width / self.imageDefaultSize.width, self.frame.size.height / self.imageDefaultSize.height)
        
        let scale2 = min(maxScale, currentScale)
        let tempMask = self.maskColor
        self.image = UIImage.fromPDF(filename: self.imageName, size: imageDefaultSize, scale: scale2)
        self.maskColor = tempMask
    }
    
    func changeColor (colorItem : AGColorEditorItem)
    {
        self.maskColor = colorItem
    }
    
    class func createWithImage (imageName : String, type : AGImageEditorTypes, tag : Int, size : CGSize = CGSize(width: 78.0, height: 100), center : CGPoint = CGPoint(x: 59.0, y: 154.0), scale : CGFloat = 1.0, color : UIColor = .white) -> AGEditableImageView
    {
        let newImageView = AGEditableImageView()
        
        newImageView.image = UIImage.fromPDF(filename: imageName + "_pdf", size: newImageView.imageDefaultSize, scale: max(size.width / newImageView.imageDefaultSize.width, size.height / newImageView.imageDefaultSize.height))

        newImageView.imageName = imageName + "_pdf"
        newImageView.contentMode = .scaleAspectFit
        newImageView.maskColor = AGColorEditorItem.createWithColor(color: .white)
        newImageView.type = type
        newImageView.frame.size = size
        newImageView.center = center
        newImageView.newPosition = AGPositionStruct.init(center: center, scale: 1.0, angle: 0.0)
        newImageView.tag = tag
        
        newImageView.isUserInteractionEnabled = true

        let tapGesture = UITapGestureRecognizer.init(target: newImageView, action:  #selector(AGEditableImageView.showHideGesture))
            newImageView.addGestureRecognizer(tapGesture)
        
        let panGesture = UIPanGestureRecognizer.init(target: newImageView, action:  #selector(AGEditableImageView.moveEditableImageView(_:)))
            newImageView.addGestureRecognizer(panGesture)

        
        newImageView.becomeFirstResponder()
        
        return newImageView
    }
    
    func showHideGesture ()
    {
        self.delegate?.imageDidTouch(imageView: self)
    }
    
    func moveEditableImageView (_ gestureRecognizer : UIPanGestureRecognizer)
    {
        if (!self.isActive) { return }
        
        let touchLocation = gestureRecognizer.location(in: self.superview)
        
        switch gestureRecognizer.state {
        case .began:
            self.delegate?.startMoving(imageView: self)
        case .changed:
            self.center = touchLocation
            self.newPosition?.centerPoint = touchLocation
        case .ended:
            self.delegate?.endMoving(imageView: self, touchLocation: touchLocation)
        default:
            return
        }
    }
    
    func undoImageChanges () {
        if (self.lastPosition == nil)
        {
            self.removeFromSuperview()
            return
        }
        self.newPosition = self.lastPosition
        self.maskColor = self.lastMaskColor ?? AGColorEditorItem()
        self.center = self.newPosition?.centerPoint ?? CGPoint.zero
        self.updateImage()
    }
    
    func updateLastPosition() {
        self.lastPosition = self.newPosition
        self.lastMaskColor = self.maskColor
    }

}
