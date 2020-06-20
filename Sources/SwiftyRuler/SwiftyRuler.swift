//
//  Ruler.swift
//  Ink
//
//  Created by Fatih Balsoy on 6/12/20.
//  Published by Fatih Balsoy on 6/20/20.
//
//  Copyright © 2020 BITS Laboratory. All rights reserved.
//

import Foundation
import GBDeviceInfo
import UIKit

public enum RulerUnit {
    case centimeters
    case inches

    static prefix func ! (lhs: RulerUnit) -> RulerUnit {
        if lhs == .centimeters {
            return .inches
        } else {
            return .centimeters
        }
    }
}

private class RulerMeasurements {
    var inchTickSpacing: CGFloat!
    var numberOfTicks: CGFloat!
}

@objc public protocol RulerDelegate: AnyObject {
    @objc optional func ruler(didPressAccuracyWarning ruler: Ruler, using event: UIEvent)
    @objc optional func ruler(didPressCustomizePixelDensity ruler: Ruler, currentDensity: CGFloat, using event: UIEvent)
}

public class Ruler: UIView {
    public var direction: NSLayoutConstraint.Axis = .horizontal
    public var offset: CGFloat = 0
    public var lineSpacing: CGFloat = 6
    public var unitTicks: CGFloat = 10 // ticks per unit

    public var shortLine: CGFloat = 15
    public var midLine: CGFloat = (30 + 15) / 2
    public var longLine: CGFloat = 30

    public var tickColor: UIColor = .black
    public var labelColor: UIColor = .black
    public var hasLabels: Bool = true
    public var pixelAccurate: Bool = false
    public var doubleSided: Bool = false
    public var doubleUnits: Bool = false

    public var accuracyLocale = "NOT ACCURATE"
    public var customLocale = "EDIT"
    public var accuracyWarnings: Bool = true
    private var isAccurate: Bool = false
    private var accuracyLabelFrame = CGRect()
    private var usingCustomPPI: Bool = false
    private var customPixelDensity: CGFloat?
    private var customPPIMultiplier: CGFloat = 332 / 227

    public var units: RulerUnit = .centimeters
    public weak var delegate: RulerDelegate?

    public override func draw(_ rect: CGRect) {
        backgroundColor = .clear
        if pixelAccurate { generateForScreen() }

        layoutTicks(for: units, mirror: false)
        if doubleSided && doubleUnits || doubleUnits {
            layoutTicks(for: !units, mirror: true)
        } else if doubleSided {
            layoutTicks(for: units, mirror: true)
        }
    }

    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let location = touches.first?.location(in: self) else { return }
        if accuracyLabelFrame.contains(location), let e = event, e.type == .touches {
            if usingCustomPPI {
                delegate?.ruler?(didPressCustomizePixelDensity: self, currentDensity: getPixelDensity(), using: e)
            } else {
                delegate?.ruler?(didPressAccuracyWarning: self, using: e)
            }
        }
    }

    public func midLineLength(_ divided: CGFloat = 2) -> CGFloat {
        return (longLine + shortLine) / divided
    }

    public func setPixelDensity(_ ppi: CGFloat?) {
        if let p = ppi {
            if p < 1 { customPixelDensity = 1 } else {
                customPixelDensity = p * customPPIMultiplier
            }
        } else {
            usingCustomPPI = false
            customPixelDensity = nil
        }
        setNeedsDisplay()
    }

    public func getPixelDensity() -> CGFloat {
        return (customPixelDensity ?? customPPIMultiplier) / customPPIMultiplier
    }

    private func getPixelDensityPrivate() -> CGFloat {
        #if targetEnvironment(macCatalyst) || targetEnvironment(simulator)
            var ppi = UIScreen.main.nativeScale * 144
            if let p = customPixelDensity {
                ppi = p
                usingCustomPPI = true
            }
            return ppi
        #else
            isAccurate = true
            return GBDeviceInfo().displayInfo.pixelsPerInch
        #endif
    }

    private func getRuler(for unit: RulerUnit) -> RulerMeasurements {
        let ruler = RulerMeasurements()
        let dividend: CGFloat = unit == .centimeters ? 25.4 : 16
        ruler.inchTickSpacing = getPixelDensityPrivate() / dividend / 2
        ruler.numberOfTicks = unit == .centimeters ? 10 : 16
        return ruler
    }

    private func generateForScreen() {
        lineSpacing = getRuler(for: units).inchTickSpacing
        unitTicks = getRuler(for: units).numberOfTicks
    }

    private func layoutTicks(for unit: RulerUnit, mirror: Bool) {
        tickColor.setFill()
        var x: CGFloat = 0
        var y: CGFloat = 0

        let linesDist: CGFloat = pixelAccurate ? getRuler(for: unit).inchTickSpacing : lineSpacing

        var count = 0 + offset
        let vertical = direction == .vertical
        while (vertical && y <= bounds.size.height) || (!vertical && x <= bounds.size.width) {
            let tick = vertical ? y : x

            generateTick(for: unit, tick: tick, count: count, mirror: mirror)
            if vertical {
                y += linesDist
            } else {
                x += linesDist
            }
            count += 1
        }
    }

    private func generateTick(for unit: RulerUnit, tick: CGFloat, count: CGFloat, mirror: Bool) {
        let vertical = direction == .vertical
        let numberOfTicks = getRuler(for: unit).numberOfTicks ?? unitTicks
        let isLong = count.truncatingRemainder(dividingBy: numberOfTicks) == 0
        let isMid = count.truncatingRemainder(dividingBy: numberOfTicks / 2) == 0
        let length = isLong ? longLine : isMid ? midLine : shortLine

        let vX = mirror ? bounds.width - length : 0
        let vY = mirror ? bounds.height - length : 0

        let tickRect = CGRect(
            x: vertical ? vX : tick,
            y: vertical ? tick : vY,
            width: vertical ? length : 1,
            height: vertical ? 1 : length)

        if isLong && hasLabels {
            let labelStyle = NSMutableParagraphStyle()
            labelStyle.alignment = .center
            let attributes: [NSAttributedString.Key: Any] = [
                .paragraphStyle: labelStyle,
                .font: UIFont.systemFont(ofSize: 12),
                .foregroundColor: labelColor,
            ]

            let measurement = count == 0
                ? unit == .centimeters
                ? "cm"
                : "in"
                : String(Int(count / numberOfTicks))
            let text = measurement
            let attributedString = NSAttributedString(string: text, attributes: attributes)

            let multiplier: CGFloat = mirror ? -1 : 1
            let offset: CGFloat = mirror ? (vertical ? -5 : 0) : (vertical ? 18 : 15)
            let padding: CGFloat = offset - 10

            let labelSize = (text as NSString).size(withAttributes: attributes)
            let labelOffsetX = count == 0 ? -5 : (vertical ? labelSize.height : labelSize.width) / 2
            let labelOffsetY = (length + padding) * multiplier

            let textRect = CGPoint(
                x: vertical ? vX + labelOffsetY : tick - labelOffsetX,
                y: vertical ? tick - labelOffsetX : vY + labelOffsetY
            )

            attributedString.draw(at: textRect)
        }

        if (accuracyWarnings || usingCustomPPI) && !isAccurate && count == 0 && !mirror {
            let warningStyle = NSMutableParagraphStyle()
            warningStyle.alignment = .left
            let attributes: [NSAttributedString.Key: Any] = [
                .paragraphStyle: warningStyle,
                .font: UIFont.boldSystemFont(ofSize: 12),
                .foregroundColor: usingCustomPPI ? UIColor.systemBlue : UIColor.systemRed,
            ]
            let text: NSString = (usingCustomPPI ? customLocale : accuracyLocale) as NSString
            let attributedString = NSAttributedString(string: text as String, attributes: attributes)
            let labelSize = text.size(withAttributes: attributes)

            let wX = vertical ? bounds.midX : 5
            let wY = vertical ? 10 + (labelSize.width / 2) : bounds.midY - (labelSize.height / 2)
            let warningRect = CGPoint(x: wX, y: wY)

            let touchInset: CGFloat = 10
            accuracyLabelFrame = CGRect(
                x: (vertical ? wX - (labelSize.height / 2) : wX) - touchInset,
                y: (vertical ? wY - (labelSize.width / 2) : wY) - touchInset,
                width: (vertical ? labelSize.height : labelSize.width) + touchInset * 2,
                height: (vertical ? labelSize.width : labelSize.height) + touchInset * 2)

            if vertical {
                text.drawWithBasePoint(basePoint: warningRect, angle: 90.radians(), attributes: attributes)
            } else {
                attributedString.draw(at: warningRect)
            }
        }

        tickColor.setFill()
        UIRectFill(tickRect)
    }
}

fileprivate extension Int {
    func radians() -> CGFloat {
        return CGFloat.pi * CGFloat(truncating: NSNumber(value: self)) / 180.0
    }
}

fileprivate extension NSString {
    func drawWithBasePoint(basePoint: CGPoint, angle: CGFloat, attributes: [NSAttributedString.Key: Any]) {
        let textSize: CGSize = size(withAttributes: attributes)

        // sizeWithAttributes is only effective with single line NSString text
        // use boundingRectWithSize for multi line text

        guard let context: CGContext = UIGraphicsGetCurrentContext() else { return }

        let t: CGAffineTransform = CGAffineTransform(translationX: basePoint.x, y: basePoint.y)
        let r: CGAffineTransform = CGAffineTransform(rotationAngle: angle)

        context.concatenate(t)
        context.concatenate(r)

        draw(at: CGPoint(x: -1 * textSize.width / 2, y: -1 * textSize.height / 2), withAttributes: attributes)

        context.concatenate(r.inverted())
        context.concatenate(t.inverted())
    }
}
