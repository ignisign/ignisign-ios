//
//  Ignisign.swift
//  ignisign-ios
//
//  Created by Marc Nigdélian on 22/12/2023.
//

import Foundation
import UIKit
import WebKit

public class Ignisign: WKWebView, WKScriptMessageHandler, WKNavigationDelegate {
    var debug = false
    var ignisignClientSignUrlDefault = "https://sign.ignisign.io"
    var ignisignClientSignUrl: String?

    let IFRAME_MIN_HEIGHT: Int = 400
    let IFRAME_MIN_WIDTH: Int = 300

    var appId: String?
    var env: IgnisignApplicationEnv?
    var signerId: String?
    var signatureRequestId: String?
    var closeOnFinish: Bool = true
    var signerAuthToken: String?
    var sessionCallbacks: IgnisignJS_SignatureSession_Callbacks?
    var displayOptions: IgnisignJSSignatureSessionsDisplayOptions?
    var signatureSessionToken: String?
    var signatureAuthToken: String?
    var dimensions: IgnisignSignatureSessionDimensions?
    
    private static let ignisignRootDomain = "ignisign.io"
    
    private func debugPrint(_ message: String) {
        if debug {
            print(message)
        }
    }
    
    /// Serialized origin (scheme://host[:port]) as reported by `event.origin` / WKSecurityOrigin.
    private static func origin(scheme: String, host: String, port: Int?) -> String {
        let scheme = scheme.lowercased()
        let host = host.lowercased()
        if let port = port, port > 0, !((scheme == "https" && port == 443) || (scheme == "http" && port == 80)) {
            return "\(scheme)://\(host):\(port)"
        }
        return "\(scheme)://\(host)"
    }
    
    /// Origin of the configured sign URL (custom / self-hosted / local dev), if any.
    private var configuredSignOrigin: String? {
        guard let url = URL(string: ignisignClientSignUrl ?? ignisignClientSignUrlDefault),
              let scheme = url.scheme, let host = url.host else { return nil }
        return Ignisign.origin(scheme: scheme, host: host, port: url.port)
    }
    
    /// Trusted Ignisign origins: https on ignisign.io or any subdomain, plus the configured sign URL origin.
    private func isTrustedOrigin(scheme: String, host: String, port: Int?) -> Bool {
        let scheme = scheme.lowercased()
        let host = host.lowercased()
        if scheme == "https" && (host == Ignisign.ignisignRootDomain || host.hasSuffix("." + Ignisign.ignisignRootDomain)) {
            return true
        }
        return Ignisign.origin(scheme: scheme, host: host, port: port) == configuredSignOrigin
    }
    
    /// URLs the WebView may load itself at top level / via OPEN_URL: https on ignisign.io or any
    /// subdomain, or the configured sign URL origin (custom / self-hosted / local dev).
    /// Same rule as the Android SDK.
    private func isAllowedUrl(_ url: URL) -> Bool {
        guard let scheme = url.scheme?.lowercased(),
              scheme == "https" || scheme == "http",
              let host = url.host, !host.isEmpty else {
            return false
        }
        return isTrustedOrigin(scheme: scheme, host: host, port: url.port)
    }
    
    /// Hands an http(s) URL outside IgniSign domains to the system browser instead of loading it
    /// in the signing WebView. javascript:, data:, file: and other schemes are dropped.
    private func openExternally(_ url: URL) {
        guard let scheme = url.scheme?.lowercased(), scheme == "https" || scheme == "http" else {
            debugPrint("Dropped URL with unsupported scheme")
            return
        }
        debugPrint("Navigation outside IgniSign domains handed to external browser")
        DispatchQueue.main.async {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
    
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override public init(frame: CGRect, configuration: WKWebViewConfiguration) {
        super.init(frame: frame, configuration: configuration)
        initWebView(config: configuration)
    }
    
    func initWebView(config: WKWebViewConfiguration) {
        let contentController = config.userContentController
        contentController.add(self, name: "message")
        navigationDelegate = self
        translatesAutoresizingMaskIntoConstraints = false
    }
    
    public func setValues(appId: String, env: IgnisignApplicationEnv, ignisignClientSignUrl: String? = nil) {
        self.appId = appId
        self.env = env
        if let customUrl = ignisignClientSignUrl {
            self.ignisignClientSignUrl = customUrl
        } else {
            self.ignisignClientSignUrl = ignisignClientSignUrlDefault
        }
    }
    
    public func initSignatureSession(initParams: IgnisignInitParams) {
        debugPrint("trace ignisign ios - init Signature session called")
        signerId = initParams.signerId
        signatureRequestId = initParams.signatureRequestId
        closeOnFinish = initParams.closeInFinish
        displayOptions = initParams.displayOptions
        signerAuthToken = initParams.signerAuthToken
        signatureSessionToken = initParams.signatureSessionToken
        sessionCallbacks = initParams.sessionCallbacks
        dimensions = initParams.dimensions
        
        if let signatureRequestId = signatureRequestId,
           let signerId = signerId,
           let signatureSessionToken = signatureSessionToken,
            let signerAuthSecret = signerAuthToken,
            let displayOptions = displayOptions {
            let signatureSessionLink = getUrlSessionLink(signatureRequestId: signatureRequestId, signerId: signerId, signatureSessionToken: signatureSessionToken, signerAuthSecret: signerAuthSecret, displayOptions: displayOptions)
            debugPrint("trace ignisign ios - init Signature session called load webview")
            guard let sessionUrl = URL(string: signatureSessionLink) else {
                debugPrint("Failed to create URL from signature session link")
                return
            }
            load(URLRequest(url: sessionUrl))
        } else {
            debugPrint("trace ignisign ios - values nil")
        }
    }
    
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        let configuredOriginJson = configuredSignOrigin.map { "\"\($0)\"" } ?? "null"
        let jsCode = """
        (function() {
            var configuredOrigin = \(configuredOriginJson);
            function receiveMessage(event) {
                if (!/^https:\\/\\/([a-z0-9-]+\\.)*ignisign\\.io$/.test(event.origin) && event.origin !== configuredOrigin) {
                    return;
                }
                window.webkit.messageHandlers.message.postMessage(JSON.stringify(event.data));
            }
            window.addEventListener("message", receiveMessage, false);
        })()
        """
         debugPrint("trace webview didFinish")
        webView.evaluateJavaScript(jsCode, completionHandler: nil)
    }
    
    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        // Sub-frames (embedded viewers, identity providers, about:srcdoc, blob:) are not filtered here.
        if let targetFrame = navigationAction.targetFrame, !targetFrame.isMainFrame {
            decisionHandler(.allow)
            return
        }
        guard let url = navigationAction.request.url, let scheme = url.scheme?.lowercased() else {
            decisionHandler(.cancel)
            return
        }
        if navigationAction.targetFrame == nil {
            // target="_blank" / window.open: no uiDelegate opens new windows, so keep IgniSign
            // pages in this WebView and send everything else to the system browser.
            if isAllowedUrl(url) {
                load(navigationAction.request)
            } else {
                openExternally(url)
            }
            decisionHandler(.cancel)
            return
        }
        if scheme == "about" || scheme == "blob" || isAllowedUrl(url) {
            decisionHandler(.allow)
        } else {
            // Top-level navigation stays on IgniSign domains; other http(s) links open in Safari.
            openExternally(url)
            decisionHandler(.cancel)
        }
    }

   public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
       // The handler is exposed to every frame: only accept messages from a trusted main frame.
       let origin = message.frameInfo.securityOrigin
       guard message.frameInfo.isMainFrame,
             isTrustedOrigin(scheme: origin.`protocol`, host: origin.host, port: origin.port) else {
           debugPrint("Ignored bridge message from untrusted frame")
           return
       }
       if message.name == "message", let messageBody = message.body as? String {
           debugPrint("message received from WebView")
           handleEvent(message: messageBody)
       }
   }
    
    private func handleEvent(message: String) {
        debugPrint("Message received from JS")
        if let args = jsonToMap(json: message) {
            if let type = args["type"] as? String {
                if let data = args["data"] as? [String: Any] {
                    if type == IgnisignBroadcastableActions.needPrivateFileUrl.rawValue {
                        debugPrint("trace callback - need private file url")
                        
                        if let documentId = data["documentId"] as? String, let externalDocumentId = data["externalDocumentId"] as? String {
                            let data = IgnisignBroadcastableActionPrivateFileRequestDto.PrivateFileRequestData(
                                documentId: documentId,
                                externalDocumentId: externalDocumentId
                            )
                            
                            let actionPrivateFileDto = IgnisignBroadcastableActionPrivateFileRequestDto(
                                type: IgnisignBroadcastableActions.needPrivateFileUrl,
                                data: data
                            )
                            
                            managePrivateFileInfoProvisioning(action: actionPrivateFileDto)
                        }
                    } else if type == IgnisignBroadcastableActions.openUrl.rawValue {
                        if let url = data["url"] as? String {
                            if let validUrl = URL(string: url) {
                                if isAllowedUrl(validUrl) {
                                    load(URLRequest(url: validUrl))
                                } else {
                                    openExternally(validUrl)
                                }
                            } else {
                                debugPrint("Ignored OPEN_URL with invalid URL")
                            }
                        }
                    } else if type == IgnisignBroadcastableActions.signatureFinalized.rawValue {
                        debugPrint("trace callback - signature finalized")
                        if let signatureIds = data["signatureIds"] as? [String] {
                            let data = IgnisignBroadcastableActionSignatureFinalizedDto.SignatureFinalizedData(signatureIds: signatureIds)
                            let actionSignatureFinalizedDto = IgnisignBroadcastableActionSignatureFinalizedDto(type: IgnisignBroadcastableActions.signatureFinalized, data: data)
                            finalizeSignatureRequest(action: actionSignatureFinalizedDto)
                        }
                        
                    } else if type == IgnisignBroadcastableActions.signatureError.rawValue {
                        debugPrint("trace callback - signature error")
                        if let errorCode = data["errorCode"] as? String, let errorContext = data["errorContext"] {
                            let data = IgnisignBroadcastableActionSignatureErrorDto.SignatureErrorData(errorCode: errorCode, errorContext: errorContext)
                            let signatureErrorActionDto = IgnisignBroadcastableActionSignatureErrorDto(type: IgnisignBroadcastableActions.signatureError, data: data)
                            manageSignatureRequestError(action: signatureErrorActionDto)
                        }
                    }
                }
            } else if (args["type"] != nil && (args["data"] == nil || ((args["data"] as? [String: Any]) == nil))) {
               
           }
        }
    }
    
    private func managePrivateFileInfoProvisioning(action: IgnisignBroadcastableActionPrivateFileRequestDto) {
        
        let documentId = action.data.documentId
        let externalDocumentId = action.data.externalDocumentId
        
        if let signerId = signerId, let signatureRequestId = signatureRequestId {
            sessionCallbacks?.handlePrivateFileInfoProvisioning(documentId: documentId, externalDocumentId: externalDocumentId, signerId: signerId, signatureRequestId: signatureRequestId)
        }

        if closeOnFinish {
            closeIFrame()
        }
    }

    private func finalizeSignatureRequest(action: IgnisignBroadcastableActionSignatureFinalizedDto) {
        if let signerId = signerId, let signatureRequestId = signatureRequestId {
            sessionCallbacks?.handleSignatureSessionFinalized(signatureIds: action.data.signatureIds, signerId: signerId, signatureRequestId: signatureRequestId)
        }

        if closeOnFinish {
            closeIFrame()
        }
    }

    private func manageSignatureRequestError(action: IgnisignBroadcastableActionSignatureErrorDto) {
        let errorCode = action.data.errorCode
        let errorContext = action.data.errorContext
        
        debugPrint("signature request error occurred")

        if let signerId = signerId, let signatureRequestId = signatureRequestId {
            sessionCallbacks?.handleSignatureSessionError(errorCode: errorCode, errorContext: errorContext, signerId: signerId, signatureRequestId: signatureRequestId)
        }

        if closeOnFinish {
            closeIFrame()
        }
    }
    
    private func closeIFrame() {
        if let blankUrl = URL(string: "about:blank") {
            load(URLRequest(url: blankUrl))
        }
    }
    
    // SECURITY NOTE: This method constructs a URL with authentication tokens in query parameters.
    // While not ideal, these are short-lived session tokens required by the Ignisign web interface.
    // HTTPS is enforced via App Transport Security to protect tokens in transit.
    // Future improvement: Consider using POST with form data or fragment-based authentication.
    func getUrlSessionLink(signatureRequestId: String, signerId: String, signatureSessionToken: String, signerAuthSecret: String, displayOptions: IgnisignJSSignatureSessionsDisplayOptions) -> String {
            let baseUrl = ignisignClientSignUrl ?? ignisignClientSignUrlDefault
            return "\(baseUrl)/signature-requests/\(signatureRequestId)/signers/\(signerId)/sign?token=\(signatureSessionToken)&signerSecret=\(signerAuthSecret)&\(displayOptions.convertToQueryString())"
        }
    
    func jsonToMap(json: String) -> [String: Any]? {
        if let data = json.data(using: .utf8) {
            do {
                return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            } catch {
                debugPrint("Erreur lors de la conversion du JSON en map: \(error)")
            }
        }
        return nil
    }
}

public struct IgnisignJSSignatureSessionsDisplayOptions {
    var showTitle: Bool
    var showDescription: Bool
    var darkMode: Bool = false
    var forceLanguage = "FR"
    var forceShowDocumentInformations: Bool = false
    
    public init(showTitle: Bool, showDescription: Bool, darkMode: Bool = false, forceLanguage: String = "FR", forceShowDocumentInformations: Bool = false) {
        self.showTitle = showTitle
        self.showDescription = showDescription
        self.darkMode = darkMode
        self.forceLanguage = forceLanguage
        self.forceShowDocumentInformations = forceShowDocumentInformations
    }

    func convertToQueryString() -> String {
        let propertiesMap: [String: Any?] = [
            "showTitle": showTitle,
            "showDescription": showDescription,
            "darkMode": darkMode,
            "forceLanguage": forceLanguage,
            "forceShowDocumentInformations": forceShowDocumentInformations
        ]

        let queryString = propertiesMap.compactMap { key, value -> String? in
            guard let value = value else { return nil }
            return "\(key)=\(value)"
        }.joined(separator: "&")

        return queryString
    }
}

public struct IgnisignSignatureSessionDimensions {
    var width: String
    var height: String
    
    public init(width: String, height: String) {
        self.width = width
        self.height = height
    }
}

public struct IgnisignInitParams {
    var signatureRequestId: String
    var signerId: String
    var signatureSessionToken: String
    var signerAuthToken: String
    var sessionCallbacks: IgnisignJS_SignatureSession_Callbacks
    var closeInFinish: Bool
    var dimensions: IgnisignSignatureSessionDimensions
    var displayOptions: IgnisignJSSignatureSessionsDisplayOptions
    
    public init(signatureRequestId: String, signerId: String, signatureSessionToken: String, signerAuthToken: String, sessionCallbacks: IgnisignJS_SignatureSession_Callbacks, closeInFinish: Bool, dimensions: IgnisignSignatureSessionDimensions, displayOptions: IgnisignJSSignatureSessionsDisplayOptions) {
        self.signatureRequestId = signatureRequestId
        self.signerId = signerId
        self.signatureSessionToken = signatureSessionToken
        self.signerAuthToken = signerAuthToken
        self.sessionCallbacks = sessionCallbacks
        self.closeInFinish = closeInFinish
        self.dimensions = dimensions
        self.displayOptions = displayOptions
    }
}
