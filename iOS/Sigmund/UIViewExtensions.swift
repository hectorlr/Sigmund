

import CoreFoundation
import Foundation
import UIKit


extension UIView{
    var width: CGFloat { return frame.size.width }
    var height: CGFloat { return frame.size.height }
    var size: CGSize  { return frame.size}
    
    var origin: CGPoint { return frame.origin }
    var x: CGFloat { return frame.origin.x }
    var y: CGFloat { return frame.origin.y }
    var centerX: CGFloat { return center.x }
    var centerY: CGFloat { return center.y }
    
    var left: CGFloat { return frame.origin.x }
    var right: CGFloat { return frame.origin.x + frame.size.width }
    var top: CGFloat { return frame.origin.y }
    var bottom: CGFloat { return frame.origin.y + frame.size.height }
    
    func setWidth(width:CGFloat)
    {
        frame.size.width = width
    }
    
    func setHeight(height:CGFloat)
    {
        frame.size.height = height
    }
    
    func setSize(size:CGSize)
    {
        frame.size = size
    }
    
    func setOrigin(point:CGPoint)
    {
        frame.origin = point
    }
    
    func setOriginX(x:CGFloat)
    {
        frame.origin = CGPointMake(x, frame.origin.y)
    }
    
    func setOriginY(y:CGFloat)
    {
        frame.origin = CGPointMake(frame.origin.x, y)
    }
    
    func setCenterX(x:CGFloat)
    {
        center = CGPointMake(x, center.y)
    }
    
    func setCenterY(y:CGFloat)
    {
        center = CGPointMake(center.x, y)
    }
    
    func roundCorner(radius:CGFloat)
    {
        layer.cornerRadius = radius
    }
    
    func setTop(top:CGFloat)
    {
        frame.origin.y = top
    }
    
    func setLeft(left:CGFloat)
    {
        frame.origin.x = left
    }
    
    func setRight(right:CGFloat)
    {
        frame.origin.x = right - frame.size.width
    }
    
    func setBottom(bottom:CGFloat)
    {
        frame.origin.y = bottom - frame.size.height
    }
    
    @IBInspectable var cornerRadius: CGFloat {
        get {
            return layer.cornerRadius
        }
        set {
            layer.cornerRadius = newValue
            layer.masksToBounds = newValue > 0
        }
    }
    
    @IBInspectable var borderWidth: CGFloat {
        get {
            return layer.borderWidth
        }
        set {
            layer.borderWidth = newValue
        }
    }
    
    @IBInspectable var borderColor: UIColor? {
        get {
            return UIColor(CGColor: layer.borderColor)
        }
        set {
            layer.borderColor = newValue?.CGColor
        }
    }
}








