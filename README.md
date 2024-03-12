# ignisign-ios

[![CI Status](https://img.shields.io/travis/Nigdelian/ignisign-ios.svg?style=flat)](https://travis-ci.org/Nigdelian/ignisign-ios)
[![Version](https://img.shields.io/cocoapods/v/ignisign-ios.svg?style=flat)](https://cocoapods.org/pods/ignisign-ios)
[![License](https://img.shields.io/cocoapods/l/ignisign-ios.svg?style=flat)](https://cocoapods.org/pods/ignisign-ios)
[![Platform](https://img.shields.io/cocoapods/p/ignisign-ios.svg?style=flat)](https://cocoapods.org/pods/ignisign-ios)

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

## Installation

ignisign-ios is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'ignisign-ios'
```


Main class: `Pods/Development Pods/Ignisign`

- Contains structs for various initialization parameters.
- debugPrint function for conditional display.
- To use Ignisign from a ViewController (example in SignContractViewController):
  1. Define an instance of Ignisign as a webview
  2. Define an instance of WKWebViewConfiguration, which will allow listening inside the webview.
  3. Define an instance of IgnisignSignatureSessionDimensions
  4. Define an instance of IgnisignJSSignatureSessionsDisplayOptions
  5. Define an instance of IgnisignInitParams
  6. Call setValues
  7. Call initSignatureSession
  8. The ViewController must extend IgnisignJS_SignatureSession_Callbacks to implement the session callbacks.

Retrieving contracts: 
- IgnisignAPI class for fetching.
- The base URL is defined in Config.
- Display is done in the ListContractsViewController view
- A detail if the view is modified, all views added to the "cell" must be on self.contentView and not on self.view, otherwise interactions do not work.
- A pull to refresh allows updating the list with potential new contracts.

