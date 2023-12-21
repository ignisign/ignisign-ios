//
//  SessionCallbackProtocol.swift
//  ignisign-ios
//
//  Created by Marc Nigdélian on 19/12/2023.
//

import Foundation

protocol IgnisignJS_SignatureSession_Callbacks {
    func handlePrivateFileInfoProvisioning(documentId: String, externalDocumentId: String, signerId: String, signatureRequestId: String) //-> Promise<IgnisignDocument_PrivateFileDto>
    func handleSignatureSessionError(errorCode: String, errorContext: Any, signerId: String, signatureRequestId: String) //-> Promise<Void>
    func handleSignatureSessionFinalized(signatureIds: [String], signerId: String, signatureRequestId: String) //-> Promise<Void>
}
