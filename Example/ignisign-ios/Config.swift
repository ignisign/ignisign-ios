//
//  Config.swift
//  ignisign-ios_Example
//
//  Created by Marc Nigdélian on 22/12/2023.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import Foundation

class Config {
    static let shared = Config()
    let baseURL: String
    private init() {
        // SECURITY: Using HTTP for localhost development only.
        // In production, always use HTTPS. The Info.plist includes
        // an ATS exception specifically for localhost to allow local testing.
        self.baseURL = "http://localhost:4242"
    }
}
