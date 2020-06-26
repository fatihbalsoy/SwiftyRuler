//
//  SwiftyRuler.swift
//  SwiftyRuler
//
//  Created by Fatih Balsoy on 6/12/20.
//  Copyright (c) 2020 Fatih Balsoy. All rights reserved.
//

import Foundation
import GBDeviceInfo
#if canImport(UIKit)
    import UIKit
#else
    import Cocoa
#endif

/// Backward-compatible enum for unit of measurement used by SwiftyRuler
///
/// Convert Apple-defined enum `UnitLength` (iOS 10) to `RulerUnit` by using:
/// ```
/// UnitLength.centimeters.rulerUnit()
/// ```
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

@available(iOS 10.0, macOS 10.12, tvOS 10.0, *)
public extension UnitLength {
    /// Converts `UnitLength` to SwiftyRuler compatible enum `RulerUnit`
    ///
    /// Only converts centimeters and inches,
    /// returns centimeters for anything else.
    ///
    /// Can be used to integrate app-defined variables with SwiftyRuler like the following:
    /// ```
    /// let unit = UnitLength.centimeters
    /// ruler.units = unit.rulerUnit()
    /// ```
    func rulerUnit() -> RulerUnit {
        switch self {
        case .centimeters:
            return .centimeters
        case .inches:
            return .inches
        default:
            return .centimeters
        }
    }
}

private class RulerMeasurements {
    var inchTickSpacing: CGFloat!
    var numberOfTicks: CGFloat!
}

// MARK: - Ruler Delegate

@objc public protocol RulerDelegate: AnyObject {
    /// Triggered when accuracy disclaimer is pressed. Can be used to implement a user interface claiming the inaccuracy of the ruler and giving the option to enter a custom pixel density.
    @objc optional func ruler(didPressAccuracyWarning ruler: Ruler, using event: UIEvent)
    /// Triggered when the edit button is pressed. Can be used to implement a user interface to adjust the pixel density of the ruler.
    @objc optional func ruler(didPressCustomizePixelDensity ruler: Ruler, currentDensity: CGFloat, using event: UIEvent)
}

// MARK: - Ruler
public typealias SwiftyRuler = Ruler
public typealias SwiftyRulerDelegate = RulerDelegate

/// UIView subclass, Ruler, renders all the required visual components like ticks and labels
public class Ruler: UIView {
    // MARK: - Tick Layout

    /// The direction in which the ticks are layed out on the ruler
    ///
    /// - Horizontal: |
    /// - Vertical: __
    public var direction: NSLayoutConstraint.Axis = .horizontal
    /// Space between each tick
    public var tickSpacing: CGFloat = 6

    /// Ticks per unit
    ///
    /// - Ticks per inch: 16
    /// - Ticks per centimeter: 10
    public var unitTicks: CGFloat = 10 // ticks per unit

    // MARK: - Length

    /// Length of each short tick
    public var shortTickLength: CGFloat = 15
    /// Length of each middle tick
    public var midTickLength: CGFloat = (30 + 15) / 2
    /// Length of each long tick
    public var longTickLength: CGFloat = 30

    // MARK: - Colors

    public var tickColor: UIColor = .black
    public var labelColor: UIColor = .black

    // MARK: - Booleans

    public var hasLabels: Bool = true
    /// If true, ruler will display accurate length of the specified unit on the screen.
    public var pixelAccurate: Bool = false
    /// Displays the same unit of length on both sides of the ruler if `doubleUnits` is `false` and or the alternative unit of length if `true`.
    public var doubleSided: Bool = false
    /// Displays the alternative unit of length.
    ///
    /// If `units` is `.centimeters` and `doubleUnits` is `true`, the opposite edge of the ruler will display `.inches`.
    public var doubleUnits: Bool = false

    // MARK: - Accuracy

    /// Text of label when the ruler cannot display accurate measurements.
    /// Override to localize, `"NOT ACCURATE"`, for other languages.
    public var accuracyLocale = "NOT ACCURATE"
    /// Text of label when the ruler allows user-defined pixel densities.
    /// Override to localize, `"EDIT"`, for other languages.
    public var customLocale = "EDIT"
    /// Include a disclaimer, at 0cm, warning the user that the ruler is not accurate based on an error.
    public var accuracyWarnings: Bool = true
    /// Include an edit button, at 0cm, so the user can modify the length of measurements based on pixel density.
    ///
    /// Set pixel density by using:
    /// ```
    /// ruler.setPixelDensity(227)
    /// ```
    /// Reset pixel density with `nil`:
    /// ```
    /// ruler.setPixelDensity(nil)
    /// ```
    public var usingCustomPPI: Bool = false

    private var isAccurate: Bool = false
    private var accuracyLabelFrame = CGRect()
    private var customPixelDensity: CGFloat?
    #if targetEnvironment(macCatalyst)
        private var customPPIMultiplier: CGFloat = 332 / 227
    #else
        private var customPPIMultiplier: CGFloat = 1
    #endif

    /// The unit of measurement displayed on the ruler.
    public var units: RulerUnit = .centimeters
    public weak var delegate: RulerDelegate?

    // MARK: - Draw

    public override func draw(_ rect: CGRect) {
        if pixelAccurate { generateForScreen() }

        layoutTicks(for: units, mirror: false)
        if doubleSided && doubleUnits || doubleUnits {
            layoutTicks(for: !units, mirror: true)
        } else if doubleSided {
            layoutTicks(for: units, mirror: true)
        }
    }

    // MARK: - Gestures

    @available(OSX 10.12.2, *)
    private func touchesBeganUX(_ touches: Set<UITouch>, with event: UIEvent?, type eventType: UIEvent.EventType) {
        guard let location = touches.first?.location(in: self) else { return }

        if accuracyLabelFrame.contains(location), let e = event, e.type == eventType {
            if usingCustomPPI {
                delegate?.ruler?(didPressCustomizePixelDensity: self, currentDensity: getPixelDensity(), using: e)
            } else {
                delegate?.ruler?(didPressAccuracyWarning: self, using: e)
            }
        }
    }

    #if canImport(UIKit)
        public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
            touchesBeganUX(touches, with: event, type: .touches)
        }
    #else
        @available(OSX 10.6, *)
        public override func touchesBegan(with event: NSEvent) {
            if #available(OSX 10.12.2, *) {
                touchesBeganUX(event.touches(for: self), with: event, type: .leftMouseUp)
            }
        }
    #endif

    // MARK: - Helpers

    /// Generate the length for each middle tick based on the lengths of long and short ticks.
    ///
    /// - Parameters:
    ///     - divided: The peak of the middle tick determined by the median of other ticks.
    public func midLineLength(_ divided: CGFloat = 2) -> CGFloat {
        return (longTickLength + shortTickLength) / divided
    }

    /// Set a custom pixel density to adjust the spacing of each tick. Set `nil` to reset pixel density.
    ///
    /// Can be entered by user if `usingCustomPPI` is `true` or programmatically when `false`.
    ///
    /// - Parameters:
    ///     - ppi: Pixel per Inch.
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

    /// Get the pixel density used by the ruler to measure the space between each tick.
    public func getPixelDensity() -> CGFloat {
        return (customPixelDensity ?? getPixelDensityPrivate()) / customPPIMultiplier
    }

    private func getPixelDensityPrivate() -> CGFloat {
        #if targetEnvironment(macCatalyst) || targetEnvironment(simulator) || os(macOS) || os(tvOS)
            #if os(macOS)
                var ppi: CGFloat = 2 * 144
            #else
                var ppi = UIScreen.main.nativeScale * 144
            #endif
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
        tickSpacing = getRuler(for: units).inchTickSpacing
        unitTicks = getRuler(for: units).numberOfTicks
    }

    private func layoutTicks(for unit: RulerUnit, mirror: Bool) {
        tickColor.setFill()
        var x: CGFloat = 0
        var y: CGFloat = 0

        let linesDist: CGFloat = pixelAccurate ? getRuler(for: unit).inchTickSpacing : tickSpacing

        var count: CGFloat = 0
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
        let length = isLong ? longTickLength : isMid ? midTickLength : shortTickLength

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
