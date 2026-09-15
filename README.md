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

## Security Best Practices

This SDK implements several security measures to protect sensitive data:

### App Transport Security (ATS)
- **HTTPS enforced by default**: All network connections must use HTTPS with strong TLS
- **Localhost exception only**: The example app includes an ATS exception only for `localhost` to enable local development
- **⚠️ Production apps**: Remove localhost exception and ensure all endpoints use HTTPS

### WebView Security
- **Origin validation**: PostMessage events are validated to only accept messages from trusted Ignisign domains
- **Default trusted origin**: `https://sign.ignisign.io`
- **Custom origins**: When using `setValues(ignisignClientSignUrl:)`, the origin is automatically added to the allowlist

### Secure Logging
- **Debug logging disabled by default**: The `debug` flag is set to `false` in production
- **No sensitive data in logs**: Authentication tokens, secrets, and personal data are never logged
- **⚠️ Development**: Only enable debug logging during development, never in production builds

### Token Handling
- **Short-lived tokens**: Session tokens are designed to be ephemeral and request-specific
- **HTTPS required**: ATS enforcement protects tokens in transit
- **⚠️ Storage**: Never store authentication tokens in UserDefaults. Use iOS Keychain for persistent credential storage

### Implementation Checklist for Integrators

When integrating this SDK in your app:

- [ ] Ensure your Info.plist does NOT include `NSAllowsArbitraryLoads` set to `true`
- [ ] Only add ATS exceptions for specific domains that absolutely require them
- [ ] Never hardcode API keys or secrets in your app
- [ ] Store sensitive credentials in iOS Keychain, not UserDefaults
- [ ] Implement certificate pinning for high-security applications
- [ ] Disable debug logging in production builds
- [ ] Review and test your ATS configuration with `nscurl --ats-diagnostics <your-url>`
- [ ] Consider implementing additional authentication layers (biometrics, etc.)

### Reporting Security Issues

If you discover a security vulnerability, please email security@ignisign.io instead of using the public issue tracker.

