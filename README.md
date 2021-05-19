# Credit Card Reader

Camera based library for SwiftUI, AltSwiftUI and UIKit with lightweight and accurate credit card information detection, and fully customizable UI controls.

![logo](https://raw.githubusercontent.com/rakutentech/iOS-CreditCardReader/master/docResources/CreditCardReader1.png)
![logo](https://raw.githubusercontent.com/rakutentech/iOS-CreditCardReader/master/docResources/CreditCardReader2.png)

- [Features](#features)
- [Supported Version](#supported-version)
- [Installation](#installation)
- [Sample Usage](#sample-usage)
- [Get Involved](#get-involved)
- [License](#license)

## Features

- Captures through image analysis:
	- Traditional credit card number
	- [Visa Quick Read](https://usa.visa.com/dam/VCOM/download/merchants/New_VBM_Acq_Merchant_62714_v5.pdf) card number
	- Card expiration date
- Can discern correct information when card contains multiple dates and numbers
- UI controls are completely customizable
- Retry capture function before confirmation
- Provides SwiftUI, AltSwiftUI and UIKit interfaces

## Supported Version

- Use version: iOS 13
- Min. deployment version: iOS 11.
_Note_: You can import into iOS 11 projects, but can only use in iOS13+ devices.

## Installation

Installation can be done by either Swift Package Manager or Cocoa Pods. Depending on the UI framework you wish to support, you must select the specific dependency. __Warning__: Installing just the base 'CreditCardReader' pod won't produce a usable library.

### SwiftUI

```ruby
pod 'CreditCardReader/SwiftUI'
```
SPM: CreditCardReader-SwiftUI

### AltSwiftUI

```ruby
pod 'CreditCardReader/AltSwiftUI'
```
SPM: CreditCardReader-AltSwiftUI

### UIKit

```ruby
pod 'CreditCardReader/UIKit'
```
SPM: CreditCardReader-UIKit

## Sample Usage

Using the credit card reader view is straightforward. You can add it directly to your view hierarchy:

```swift
var body: some View {
	...
	CreditCardReaderView { card, _ in
       // Do something with the card
    }
	...
}
```

Or present it in as modal:

```swift
var body: some View {
	...
	MyView()
		.sheet(isPresented: $showCardReader) {
            CreditCardReaderView { card, _ in
                // Do something with the card
            }
        }
	...
}
```

### Customizing Navigation and UI Controls

Basic Customization

```swift
CreditCardReaderView(
	defaultNavigationBar: .init(
		titleText: "Read Card",
		closeText: "Close"),
	defaultUIControls: .init(
		instructionsText: "Align your card with the camera",
		isRetryEnabled: false)
) { card, _ in
	// Do something with the card
}
```

Full Customization

```swift
ZStack {
	CreditCardReaderView(
		defaultNavigationBar: nil,
		defaultUIControls: nil
	) { card, retry in
		// Do something with the card
		// or call retry if your UI supports retry
	}
	MyOverlayView()
}
```

### AltSwiftUI

In AltSwiftUI, the reader view is named `CreditCardReadView`, in order to prevent Cocoa Pods submission conflicts.

```swift
CreditCardReadView { card, _ in
    // Do something with the card
}
```

### UIKit

When using the UIKit interface, you'd instantiate the card controller this way:

```swift
CreditCardReaderViewController { card, _ in
	// Do something with the card
} onControllerClosed: {
	// Close controller if pushed or presented
}
```

Likewise, you have access to all UI customization options through the initializer.

## Get Involved

### Code Structure

Image text recognition is handled by Vision and AVFoundation frameworks.
The core components for detection in dependency order are as follows:

```
CardCaptureView -> CreditCardImageAnalyzer
```

Each supported UI framework has a separate public interface with its own UI. In general, the dependency flows are the following:

```
CreditCardReaderView (SwiftUI target) -> CardCaptureView -> CreditCardImageAnalyzer
```
```
CreditCardReaderView (AltSwiftUI target) -> CardCaptureView -> CreditCardImageAnalyzer
```

### Contributing

If you find any issues or ideas of new features/improvements, you can submit an issue in GitHub.

We also welcome you to contribute by submitting a pull request.

For more information, see [CONTRIBUTING](https://github.com/rakutentech/iOS-CreditCardReader/blob/master/CONTRIBUTING.md).

## License

MIT license. You can read the [LICENSE](https://github.com/rakutentech/iOS-CreditCardReader/blob/master/LICENSE) for more details.
