//
//  CardCaptureView.swift
//  CreditCardReader
//
//  Created by Wong, Kevin a on 2021/04/19.
//

import UIKit
import AVFoundation
import VideoToolbox

/// View that contains a camera and analyzes text results
@available(iOS 13, *)
class CardCaptureView: UIView {
    typealias Retry = () -> Void
    
    // MARK: Properties
    
    var focusStrokeColor: UIColor
    var focusStrokeWidth: CGFloat
    var isCapturePaused = false
    var onSuccess: (CreditCard, @escaping Retry) -> Void
    var onFailure: ((Error) -> Void)?
    
    // MARK: Private properties
    
    private let session = AVCaptureSession()
    private var videoLayer: AVCaptureVideoPreviewLayer? { layer as? AVCaptureVideoPreviewLayer }
    private let bufferQueue = DispatchQueue(label: "CreditCardReader.BufferQueue", qos: .default)
    private let dimLayer = CALayer()
    private let videoFocusLayer = CAShapeLayer()
    private let cardWidthToHeightRatio: CGFloat = 5398 / 8560 // ISO/IEC 7810 ID-1
    private let cardWidthToCornerRatio: CGFloat = 0.035 // ISO/IEC 7810 ID-1
    private let cardWidthRatio: CGFloat = 0.9
    private let cardImageAnalyzer = CreditCardImageAnalyzer()
    private var retryCount = 0
    private let retryLimit = 3
    private var isCaptureStopped = false
    
    // MARK: Init
    
    init(focusStrokeColor: UIColor = .white,
         focusStrokeWidth: CGFloat = 2,
         onSuccess: @escaping (CreditCard, @escaping Retry) -> Void,
         onFailure: ((Error) -> Void)?) {
        self.focusStrokeColor = focusStrokeColor
        self.focusStrokeWidth = focusStrokeWidth
        self.onSuccess = onSuccess
        self.onFailure = onFailure
        super.init(frame: .zero)
        
        setupFocusAreaView()
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Override
    
    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        updateVideoFocusArea()
    }
    
    // MARK: Internal Methods
    
    func startCapture() {
        let cameraAuthStatus = AVCaptureDevice.authorizationStatus(for: .video)
        switch cameraAuthStatus {
        case .authorized:
            startSession()
        case .notDetermined: // Not asked for camera permission yet
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    if granted {
                        self?.startSession()
                    } else {
                        self?.onFailure?(CameraPermissionError(authorizationStatus: .denied))
                    }
                }
            }
        case .denied, .restricted:
            onFailure?(CameraPermissionError(authorizationStatus: cameraAuthStatus))
        @unknown default:
            onFailure?(CameraPermissionError(authorizationStatus: cameraAuthStatus))
        }
    }
    
    func stopCapture() {
        isCaptureStopped = true
        session.stopRunning()
    }
    
    // MARK: Private methods
    
    private func startSession() {
        guard !isCaptureStopped else {
            isCaptureStopped = false
            session.startRunning()
            return
        }
        
        guard let device = AVCaptureDevice.default(for: .video),
            let input = try? AVCaptureDeviceInput(device: device) else {
            onFailure?(CameraInitializationError())
            return
        }
        
        let output = AVCaptureVideoDataOutput()
        output.alwaysDiscardsLateVideoFrames = true
        output.setSampleBufferDelegate(self, queue: bufferQueue)
        session.addInput(input)
        session.addOutput(output)
        session.sessionPreset = .photo
        for connection in session.connections {
            connection.videoOrientation = .portrait
        }
        
        videoLayer?.session = session
        videoLayer?.connection?.videoOrientation = .portrait
        
        session.startRunning()
    }
    
    private func setupFocusAreaView() {
        dimLayer.backgroundColor = UIColor(white: 0, alpha: 0.3).cgColor
        videoFocusLayer.strokeColor = focusStrokeColor.cgColor
        videoFocusLayer.fillColor = UIColor.clear.cgColor
        videoFocusLayer.lineWidth = focusStrokeWidth
        layer.addSublayer(dimLayer)
        layer.addSublayer(videoFocusLayer)
    }
    
    private func updateVideoFocusArea() {
        let videoFocusArea = focusArea(for: bounds)
        let cornerRadius = videoFocusArea.width * cardWidthToCornerRatio
        
        // Dim Layer
        
        let dimLayerMask = CAShapeLayer()
        let maskPath = UIBezierPath(roundedRect: videoFocusArea, cornerRadius: cornerRadius)
        maskPath.append(UIBezierPath(rect: bounds))
        dimLayerMask.path = maskPath.cgPath
        dimLayerMask.fillRule = .evenOdd
        dimLayer.mask = dimLayerMask
        dimLayer.frame = bounds
        
        // Focus Stroke Layer
        
        let strokeSideLength: CGFloat = 36
        let firstStrokeMaskRect = CGRect(
            x: 0,
            y: videoFocusArea.minY + strokeSideLength,
            width: bounds.width,
            height: videoFocusArea.height - (strokeSideLength * 2))
        let secondStrokeMaskRect = CGRect(
            x: videoFocusArea.minX + strokeSideLength,
            y: 0,
            width: videoFocusArea.width - (strokeSideLength * 2),
            height: bounds.height)
        
        let focusMaskLayer = CAShapeLayer()
        let focusMaskPath = UIBezierPath(rect: firstStrokeMaskRect)
        focusMaskPath.append(UIBezierPath(rect: secondStrokeMaskRect))
        focusMaskPath.append(UIBezierPath(rect: bounds))
        focusMaskLayer.path = focusMaskPath.cgPath
        focusMaskLayer.fillRule = .evenOdd
        
        let focusPath = UIBezierPath(roundedRect: videoFocusArea, cornerRadius: cornerRadius)
        videoFocusLayer.path = focusPath.cgPath
        videoFocusLayer.frame = bounds
        videoFocusLayer.mask = focusMaskLayer
    }
    
    private func focusArea(for frame: CGRect) -> CGRect {
        let areaWidth = frame.width * cardWidthRatio
        let areaHeight = areaWidth * cardWidthToHeightRatio
        let areaX = (frame.width - areaWidth) / 2
        let areaY = (frame.height - areaHeight) / 2
        
        return CGRect(x: areaX, y: areaY, width: areaWidth, height: areaHeight)
    }
}

@available(iOS 13, *)
extension CardCaptureView: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard !isCapturePaused,
              let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        var capturedImage: CGImage?
        VTCreateCGImageFromCVPixelBuffer(imageBuffer, options: nil, imageOut: &capturedImage)
        
        if let capturedImage = capturedImage,
           let focusedImage = capturedImage.cropping(to: imageFocusRect(image: capturedImage)) {
            cardImageAnalyzer.analyze(image: focusedImage) { [weak self] creditCard in
                guard let `self` = self else { return }
                
                // Sometimes expiration capture will fail, retry to get a more
                // accurate result.
                if creditCard.expirationYear == nil && self.retryCount < self.retryLimit {
                    self.retryCount += 1
                    return
                }
                
                self.retryCount = 0
                self.isCapturePaused = true
                DispatchQueue.main.async {
                    self.onSuccess(creditCard) { [weak self] in
                        // Retry
                        self?.isCapturePaused = false
                    }
                }
            }
        }
    }
    
    private func imageFocusRect(image: CGImage) -> CGRect {
        let width = CGFloat(image.width) * cardWidthRatio
        let height = width * cardWidthToHeightRatio
        let x = (CGFloat(image.width) - width) / 2
        let y = (CGFloat(image.height) - height) / 2
        return CGRect(x: x, y: y, width: width, height: height)
    }
}
