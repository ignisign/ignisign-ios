//
//  ViewController.swift
//  ExampleIgnisigniOS
//
//  Created by Marc Nigdélian on 20/12/2023.
//

import UIKit
import WebKit

class ViewController: UIViewController, IgnisignJS_SignatureSession_Callbacks {
    
    var ignisign : IgnisigniOS!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let config = WKWebViewConfiguration()
        ignisign = IgnisigniOS(frame: .zero, configuration: config)
        view.addSubview(ignisign)

        NSLayoutConstraint.activate([
            ignisign.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            ignisign.leftAnchor.constraint(equalTo: view.leftAnchor),
            ignisign.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            ignisign.rightAnchor.constraint(equalTo: view.rightAnchor)
        ])
        
        let signatureRequestId = "658461beaace53001cece1dc"
        let signerId = "6582fc68ef3841001b92e413"
        let signatureSessionToken = "lUmBcyioSB6NDHT7xQQSVCx7D2rArkeMrSAPoDwOKvZZho0kbSf9IIotfESgG8zZZU"//"6582c681e11636001dfeda77"
        let signerAuthSecret = "ffbdae8b-8ead-4fed-a601-d4ea62dcda50"//"fd2b2d0c-1cc6-4dd8-8c99-6b6551e84fdd"
        
        let dimensins = IgnisignSignatureSessionDimensions(width: "400", height: "300")
        let displayOptions = IgnisignJSSignatureSessionsDisplayOptions(showTitle: true, showDescription: true)
        let initParams = IgnisignInitParams(signatureRequestId: signatureRequestId, signerId: signerId, signatureSessionToken: signatureSessionToken, signerAuthToken: signerAuthSecret, sessionCallbacks: self, closeInFinish: true, dimensions: dimensins, displayOptions: displayOptions)
        
        ignisign.setValues(appId: "com.ignisign.ignisign_ios", env: IgnisignApplicationEnv.DEVELOPMENT, ignisignClientSignUrl: "https://sign.ignisign.io")
        ignisign.initSignatureSession(initParams: initParams)
    }
    
    func handlePrivateFileInfoProvisioning(documentId: String, externalDocumentId: String, signerId: String, signatureRequestId: String) {
        print("trace handlePrivateFileInfoProvisioning : documentId : \(documentId) externalDocumentId : \(externalDocumentId) signatureRequestId : \(signatureRequestId)")
    }
    
    func handleSignatureSessionError(errorCode: String, errorContext: Any, signerId: String, signatureRequestId: String) {
        print("trace handleSignatureSessionError : errorCode : \(errorCode) errorContext : \(errorContext) signerId : \(signerId) signatureRequestId : \(signatureRequestId)")
    }
    
    func handleSignatureSessionFinalized(signatureIds: [String], signerId: String, signatureRequestId: String) {
        print("handleSignatureSessionFinalized signatureIds : \(signatureIds) signerId : \(signerId) signatureRequestId : \(signatureRequestId)")
    }
}
