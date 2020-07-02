//
//  UXKit.swift
//  SwiftyRuler
//
//  Created by Fatih Balsoy on 6/22/20.
//  Copyright (c) 2020 Fatih Balsoy. All rights reserved.
//
//  Lightweight implementation of cross-platform classes and functions
//

#if os(OSX)

import Cocoa
public typealias UIView = NSView
public typealias UIColor = NSColor
public typealias UIEvent = NSEvent
public typealias UIFont = NSFont
public typealias UITouch = NSTouch
public typealias UIScreen = NSScreen

internal func UIRectFill(_ rect: CGRect) {
    rect.fill()
}

internal func UIGraphicsGetCurrentContext() -> CGContext? {
    return NSGraphicsContext.current?.cgContext
}

extension UIView {
    public var backgroundColor: NSColor {
        get {
            let black = NSColor.black
            return NSColor(cgColor: self.layer?.backgroundColor ?? black.cgColor) ?? black
        }
        set {
            self.layer?.backgroundColor = newValue.cgColor
        }
    }
    
    func setNeedsDisplay() {
        self.setNeedsDisplay(self.frame)
    }
}

extension NSLayoutConstraint {
   public enum Axis : Int {
        case horizontal = 0
        case vertical = 1
    }
}

#endif


