//
//  OverlayDefaultViewParams.swift
//  CreditCardReader
//
//  Created by Wong, Kevin a on 2021/04/19.
//

import UIKit

public struct CreditCardReaderDefaultNavigationBar {
    public let titleText: String
    public let closeText: String
    
    public init(
        titleText: String = "Read Card",
        closeText: String = "Close") {
        self.titleText = titleText
        self.closeText = closeText
    }
}

public struct CreditCardReaderDefaultControls {
    public let instructionsText: String
    public let retryText: String
    public let confirmText: String
    public let isRetryEnabled: Bool
    public let navigatesBackOnDetection: Bool
    
    public init(
        instructionsText: String = "Align the card with the capture area.",
        retryText: String = "Retry",
        confirmText: String = "Confirm",
        isRetryEnabled: Bool = true,
        navigatesBackOnDetection: Bool = true) {
        self.instructionsText = instructionsText
        self.retryText = retryText
        self.confirmText = confirmText
        self.isRetryEnabled = isRetryEnabled
        self.navigatesBackOnDetection = navigatesBackOnDetection
    }
}
