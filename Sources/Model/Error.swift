//
//  Error.swift
//  CreditCardReader
//
//  Created by Wong, Kevin a on 2021/04/19.
//

import Foundation
import AVFoundation

/// When the camera fails to initialize
public struct CameraInitializationError: Error {}

/// When permission to camera is denied or restricted
public struct CameraPermissionError: Error {
    let authorizationStatus: AVAuthorizationStatus
}
