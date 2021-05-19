//
//  CardCaptureController.swift
//  CreditCardReader
//
//  Created by Wong, Kevin a on 2021/04/20.
//

import Foundation

@available(iOS 13, *)
class CardCaptureController {
    weak var captureView: CardCaptureView?
    func startCapture() {
        captureView?.startCapture()
    }
    func stopCapture() {
        captureView?.stopCapture()
    }
}
