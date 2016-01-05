## MBPhotoPicker

Easy and quick in implementation Photo Picker, based on Slack's picker.

![picture alt](https://github.com/mbutan/MBPhotoPicker/blob/master/Assets/screenshot.png "MBPhotoPicker")

## Requirements
* iOS 8.0+
* Swift 1.0+
* ARC
* To happy full functionality, expand your Xcode's captabilities of iCloud entitlement (see at the attached example, or read more about [here](https://developer.apple.com/library/mac/documentation/IDEs/Conceptual/AppDistributionGuide/AddingCapabilities/AddingCapabilities.html))

## Installation

MBPhotoPicker is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "MBPhotoPicker"
```

## Usage

To run the example project, clone the repo, and run `pod install` from the Example directory first.

For a quick start see the code below.
```
var photo: MBPhotoPicker? = MBPhotoPicker()
photo?.photoCompletionHandler = { (image: UIImage!) -> Void in
print("Selected image")
}
photo?.cancelCompletionHandler = {
print("Cancel Pressed")
}
photo?.errorCompletionHandler = { (error: MBPhotoPicker.ErrorPhotoPicker!) -> Void in
print("Error: \(error.rawValue)")
}
photo?.present(self)
```

To disable import image from external apps, just type code:
```photo?.disableEntitlements = true```

Library supports bunch of localizated strings, to override translations just use one of available variables:
```
alertTitle
alertMessage
actionTitleCancel
actionTitleTakePhoto
actionTitleLastPhoto
actionTitleOther
actionTitleLibrary
```

## Author

Marcin Butanowicz, m.butan@gmail.com

## License

MBPhotoPicker is available under the MIT license. See the LICENSE file for more info.
