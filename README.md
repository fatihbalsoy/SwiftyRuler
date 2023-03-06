![Alt text](.readme/ruler-github.png?raw=true  "SwiftyRuler")

[![Swift](https://img.shields.io/badge/swift-5.2-orange)](https://github.com/apple/swift/tree/swift-5.2-branch)
[![build](https://img.shields.io/github/actions/workflow/status/fatihbalsoy/SwiftyRuler/.github/workflows/swift.yml)](https://github.com/fatihbalsoy/SwiftyRuler/actions)
[![License](https://img.shields.io/github/license/fatihbalsoy/SwiftyRuler?color=blue)](https://github.com/fatihbalsoy/SwiftyRuler/blob/master/LICENSE)
![iOS](https://img.shields.io/badge/iOS-8.0%2B-blue)
![macOS](https://img.shields.io/badge/macOS-10.12%2B-orange)
![tvOS](https://img.shields.io/badge/tvOS-9.0%2B-white)

SwiftyRuler is a very simple Swift package that implements an accurate ruler for any iOS device. Nothing more, nothing less.

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

Vertical|Horizontal|Document
:--:|:--:|:--:
![Alt text](.readme/ruler-vertical.png?raw=true  "Vertical") | ![Alt text](.readme/ruler-horizontal.png?raw=true  "Horizontal") | ![Alt text](.readme/ruler-document.png?raw=true  "Document")

## Installation

### Swift Package Manager

To integrate using Apple's [Swift Package Manager](https://swift.org/package-manager/), add the following as a dependency to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/fatihbalsoy/SwiftyRuler.git", from: "0.1.0")
]
```

Alternatively, navigate to your Xcode project, go to `File > Add Packages...` and search for `https://github.com/fatihbalsoy/SwiftyRuler`.

### Manually

If you prefer not to use any of the aforementioned dependency managers, you can integrate SwiftyRuler into your project manually. Simply drag the files in the `Sources` folder into your Xcode project.

## Usage

``` swift
import SwiftyRuler
import UIKit

class ViewController : UIViewController, RulerDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()

        let ruler = Ruler()
        ruler.delegate = self

        // Tick Lengths //
        ruler.longTickLength = 30
        ruler.shortTickLength = 10
        ruler.midTickLength = ruler.midLineLength(2)

        // Properties //
        ruler.pixelAccurate = true
        ruler.doubleUnits = true
        ruler.direction = .horizontal
        // ruler.doubleSided = false
        
        // Colors //
        ruler.backgroundColor = UIColor.label.withAlphaComponent(0.05)
        ruler.tickColor = .label
        ruler.labelColor = .label

        // Set Pixel Density //
        // ~ Useful for macOS and tvOS ~ //
        ruler.setPixelDensity(218.0)
        
        view.addSubview(ruler)
        // Setup Constraints //
    }
}
```

### RulerDelegate functions

```swift
@objc optional func ruler(didPressAccuracyWarning ruler: Ruler, using event: UIEvent)
```
Triggered when accuracy disclaimer is pressed. Can be used to implement a user interface claiming the inaccuracy of the ruler and giving the option to enter a custom pixel density.

<br>

```swift
@objc optional func ruler(didPressCustomizePixelDensity ruler: Ruler, currentDensity: CGFloat, using event: UIEvent)
```
Triggered when the edit button is pressed. Can be used to implement a user interface to adjust the pixel density of the ruler.

## Dependencies

- [GBDeviceInfo](https://github.com/lmirosevic/GBDeviceInfo)
  - Used to fetch PPI (Pixels per Inch) of iOS displays.

## License

SwiftyRuler is available under the AGPL license. See the LICENSE file for more info.
