# Swifty Pattern ViewController

[![Version](https://img.shields.io/cocoapods/v/SwiftyPatternLock.svg?style=flat)](https://cocoapods.org/pods/SwiftyPatternLock)
[![License](https://img.shields.io/cocoapods/l/SwiftyPatternLock.svg?style=flat)](https://cocoapods.org/pods/SwiftyPatternLock)
[![Platform](https://img.shields.io/cocoapods/p/SwiftyPatternLock.svg?style=flat)](https://cocoapods.org/pods/SwiftyPatternLock)

Swifty Pattern Lock is a simple Android-like Pattern Lock ViewController.

## Features

- [x] Autolayout
- [x] Animates views state
- [x] Interrumpible animations
- [x] Accepts any custom view
- [x] Any grid size > 2
- [x] Interpolates points on diagonals and lines
- [x] Create, view pattern, view pattern animated, check pattern functions

## Requirements

- iOS 9.0+
- Xcode 10.3+ (Should be compatible with lower versions)
- Swift 5 (Should be compatible with lower versions)

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Usage

### Init

- For simple usage, a helper function `addContainedChildViewController<T>(_ vc: T.Type, onView: UIView)` as it needs to be added to a container view and as a child of the current ViewController, please see the sample project. `SamplePatternDotView` or `SamplePatternSquareView` are sample views ready to be used.

- Alternatively, you can init it with `SwiftyPatternLock<TypeOfView>.init()` add to a container view and as a child of the host ViewController.

### Setup

Provide it with a `PatternViewConfig` with the `setup(_ config: PatternViewConfig)` function and provide it with a `PatternFunctionality` via it's `functionality` property.

## Installation

### CocoaPods

SwiftyPatternLock is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'SwiftyPatternLock'
```

### Manually

Add the `SwiftyPatternLock.swift` to the project.

## Author

jaume4, jaume4@gmail.com

## License

SwiftyPatternLock is available under the MIT license. See the LICENSE file for more info.
