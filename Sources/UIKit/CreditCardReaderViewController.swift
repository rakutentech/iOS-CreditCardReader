//
//  CreditCardReaderViewController.swift
//  CreditCardReader
//
//  Created by Wong, Kevin a on 2021/04/19.
//

import UIKit

/// View Controller that contains a camera output view and reads credit card information.
/// Use this to retrieve credit card information of a user selected result.
@available(iOS 13, *)
public class CreditCardReaderViewController: UIViewController {
    public typealias Retry = () -> Void
    public typealias Success = (CreditCard, Retry?) -> Void
    public typealias Failure = (Error) -> Void
    
    // MARK: Properties
    
    var cardCaptureView: CardCaptureView?
    var onSuccess: Success?
    var onFailure: Failure?
    var onControllerClosed: (() -> Void)?
    var navigationBar: CreditCardReaderDefaultNavigationBar? = .init()
    var uiControls: CreditCardReaderDefaultControls? = .init()
    
    private var bottomOverlayView: UIView?
    private let bottomViewTransitionOffset: CGFloat = 30
    private var detectedCard: CreditCard?
    private var retry: Retry?
    private var cardNumberLabel: UILabel?
    private var expirationLabel: UILabel?
    
    // MARK: Init
    
    /// Initializes a `CreditCardReaderViewController` with customizable controls.
    ///
    /// Navigation and Card Selection
    /// Controls can be customized by specifying `defaultNavigationBar` and
    /// `defaultUIControls` parameters. The customization type can be on of the
    /// following:
    /// - Completely customized: Pass `nil`
    /// - Content customized: Pass an instance with your configuration
    /// - Default: Use the default values
    ///
    /// - Parameters:
    ///   - defaultNavigationBar: Configuration for the navigation bar
    ///   - defaultUIControls: Configuration for Credit Card Selectino Controls
    ///   - onSuccess: Called when a card has been selected by the user, or as soon
    ///   as a card is recognized if `defaultUIControls` is `nil` or `defaultUIControls.isRetryEnabled` is `false.`
    ///   - onFailure: Called when there was an error initializing the view
    ///   - onControllerClosed: Called when this controller requests to be closed.
    ///   For example, this can happen when the 'Close' button is pressed if defining a
    ///   default navigation bar.
    public init(
        defaultNavigationBar: CreditCardReaderDefaultNavigationBar? = .init(),
        defaultUIControls: CreditCardReaderDefaultControls? = .init(),
        onSuccess: @escaping Success,
        onFailure: Failure? = nil,
        onControllerClosed: (() -> Void)? = nil) {
        self.onSuccess = onSuccess
        self.onFailure = onFailure
        self.onControllerClosed = onControllerClosed
        self.navigationBar = defaultNavigationBar
        self.uiControls = defaultUIControls
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    // MARK: Override
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .black
        
        let cardCaptureView = CardCaptureView { [weak self] card, retry in
            guard let `self` = self else { return }
            if let uiControls = self.uiControls {
                self.detectedCard = card
                self.retry = retry
                self.showBottomOverlayView()
                if !uiControls.isRetryEnabled {
                    DispatchQueue.main.asyncAfter(deadline: .now() + Double.cardReaderCloseTimeDelay) {
                        self.onSuccess?(card, retry)
                        self.closeView()
                    }
                }
            } else {
                self.onSuccess?(card, retry)
            }
        } onFailure: { [weak self] error in
            self?.onFailure?(error)
        }
        cardCaptureView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(cardCaptureView)
        cardCaptureView.edgesAnchorEqualTo(destinationView: view).activate()
        self.cardCaptureView = cardCaptureView
        
        if let topOverlayView = topOverlayView {
            view.addSubview(topOverlayView)
            [topOverlayView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
             topOverlayView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor),
             topOverlayView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor)].activate()
        }
        
        if let uiControls = uiControls {
            let instructionLabel = UILabel().noAutoresizingMask()
            instructionLabel.textAlignment = .center
            instructionLabel.textColor = .white
            instructionLabel.text = uiControls.instructionsText
            instructionLabel.numberOfLines = 0
            instructionLabel.shadowColor = UIColor(white: 1, alpha: 0.3)
            view.addSubview(instructionLabel)
            [instructionLabel.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 16),
             instructionLabel.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -16),
             instructionLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -40)].activate()
            
            let bottomOverlayView = bottomOverlayDefaultView(properties: uiControls)
            view.addSubview(bottomOverlayView)
            [bottomOverlayView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
             bottomOverlayView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor),
             bottomOverlayView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor)].activate()
            bottomOverlayView.transform = CGAffineTransform(translationX: 0, y: bottomViewTransitionOffset)
            bottomOverlayView.alpha = 0
            self.bottomOverlayView = bottomOverlayView
        }
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Delay camera start to prevent frozen frames while
        // the view is opening
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            self?.cardCaptureView?.startCapture()
        }
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        cardCaptureView?.stopCapture()
    }
    
    // MARK: Overlay Views
    
    var topOverlayView: UIView? {
        if let navigationBar = navigationBar {
            return topOverlayDefaultView(properties: navigationBar)
        } else {
            return nil
        }
    }
    
    func topOverlayDefaultView(properties: CreditCardReaderDefaultNavigationBar) -> UIView {
        let topView = UIView(frame: .zero).noAutoresizingMask()
        
        let closeButton = UIButton(frame: .zero).noAutoresizingMask()
        closeButton.setTitle(properties.closeText, for: .normal)
        closeButton.addTarget(self, action: #selector(closeView), for: .touchUpInside)
        closeButton.setTitleColor(.white, for: .normal)
        topView.addSubview(closeButton)
        [closeButton.leftAnchor.constraint(equalTo: topView.leftAnchor, constant: 10),
         closeButton.heightAnchor.constraint(equalToConstant: 44),
         closeButton.topAnchor.constraint(equalTo: topView.topAnchor),
         closeButton.bottomAnchor.constraint(equalTo: topView.bottomAnchor)].activate()
        
        let titleLabel = UILabel(frame: .zero).noAutoresizingMask()
        titleLabel.text = properties.titleText
        titleLabel.textColor = .white
        titleLabel.font = UIFont.preferredFont(forTextStyle: .headline)
        topView.addSubview(titleLabel)
        [titleLabel.centerYAnchor.constraint(equalTo: topView.centerYAnchor),
         titleLabel.centerXAnchor.constraint(equalTo: topView.centerXAnchor),
         titleLabel.leftAnchor.constraint(greaterThanOrEqualTo: closeButton.rightAnchor)].activate()
        
        return topView
    }
    
    func bottomOverlayDefaultView(properties: CreditCardReaderDefaultControls) -> UIView {
        let backgroundView = UIView().noAutoresizingMask()
        backgroundView.backgroundColor = .black
        
        let bottomView = UIStackView().noAutoresizingMask()
        bottomView.axis = .vertical
        bottomView.alignment = .center
        backgroundView.addSubview(bottomView)
        bottomView.edgesAnchorEqualTo(destinationView: backgroundView).activate()
        let spacer = UIView()
        bottomView.addArrangedSubview(spacer)
        bottomView.setCustomSpacing(4, after: spacer)
        
        // Labels
        
        let cardNumberLabel = UILabel().noAutoresizingMask()
        cardNumberLabel.textColor = .white
        cardNumberLabel.font = UIFont.preferredFont(forTextStyle: .title2)
        cardNumberLabel.textAlignment = .center
        bottomView.addArrangedSubview(cardNumberLabel)
        bottomView.setCustomSpacing(4, after: cardNumberLabel)
        self.cardNumberLabel = cardNumberLabel
        
        let expirationLabel = UILabel().noAutoresizingMask()
        expirationLabel.textColor = .white
        expirationLabel.font = UIFont.preferredFont(forTextStyle: .title3)
        expirationLabel.textAlignment = .center
        bottomView.addArrangedSubview(expirationLabel)
        bottomView.setCustomSpacing(.uiControlButtonSpacing, after: expirationLabel)
        self.expirationLabel = expirationLabel
        
        // Controls
        
        if properties.isRetryEnabled {
            let controlsView = UIStackView().noAutoresizingMask()
            controlsView.axis = .horizontal
            controlsView.spacing = .uiControlButtonSpacing
            controlsView.addArrangedSubview(UIView())
            bottomView.addArrangedSubview(controlsView)
            bottomView.setCustomSpacing(.uiControlButtonSpacing, after: controlsView)
            
            let retryButton = UIButton().noAutoresizingMask()
            retryButton.setTitle(properties.retryText, for: .normal)
            retryButton.setTitleColor(.white, for: .normal)
            retryButton.layer.borderWidth = 1
            retryButton.layer.borderColor = UIColor.white.cgColor
            retryButton.layer.cornerRadius = .uiControlButtonHeight / 2
            retryButton.addTarget(self, action: #selector(onRetryPressed), for: .touchUpInside)
            controlsView.addArrangedSubview(retryButton)
            retryButton.uiControlDimensionConstraints().activate()
            
            let confirmButton = UIButton().noAutoresizingMask()
            confirmButton.setTitle(properties.confirmText, for: .normal)
            confirmButton.setTitleColor(.black, for: .normal)
            confirmButton.backgroundColor = .white
            confirmButton.layer.cornerRadius = .uiControlButtonHeight / 2
            confirmButton.addTarget(self, action: #selector(onConfirmPressed), for: .touchUpInside)
            controlsView.addArrangedSubview(confirmButton)
            confirmButton.uiControlDimensionConstraints().activate()
            confirmButton.widthAnchor.constraint(equalTo: retryButton.widthAnchor).isActive = true
            
            controlsView.addArrangedSubview(UIView())
        }
        
        bottomView.addArrangedSubview(UIView())
        
        return backgroundView
    }
    
    // MARK: Private methods
    
    private func showBottomOverlayView() {
        cardNumberLabel?.text = detectedCard?.cardNumberDisplayString ?? ""
        expirationLabel?.text = detectedCard?.expirationDateDisplayString ?? ""
        UIView.animate(withDuration: 0.2) { [weak self] in
            self?.bottomOverlayView?.alpha = 1
            self?.bottomOverlayView?.transform = .identity
        }
    }
    
    private func hideBottomOverlayView() {
        UIView.animate(withDuration: 0.2) { [weak self] in
            guard let `self` = self else { return }
            self.bottomOverlayView?.alpha = 0
            self.bottomOverlayView?.transform = CGAffineTransform(translationX: 0, y: self.bottomViewTransitionOffset)
        }
    }
    
    @objc func closeView() {
        onControllerClosed?()
    }
    
    @objc func onRetryPressed() {
        hideBottomOverlayView()
        retry?()
    }
    
    @objc func onConfirmPressed() {
        if let detectedCard = detectedCard,
           let retry = retry {
            onSuccess?(detectedCard, retry)
            closeView()
        }
    }
}

extension UIView {
    func edgesAnchorEqualTo(destinationView: UIView) -> [NSLayoutConstraint] {
        [leftAnchor.constraint(equalTo: destinationView.leftAnchor),
                rightAnchor.constraint(equalTo: destinationView.rightAnchor),
                topAnchor.constraint(equalTo: destinationView.topAnchor),
                bottomAnchor.constraint(equalTo: destinationView.bottomAnchor)]
    }
    
    func noAutoresizingMask() -> Self {
        translatesAutoresizingMaskIntoConstraints = false
        return self
    }
    
    func uiControlDimensionConstraints() -> [NSLayoutConstraint] {
        [widthAnchor.constraint(greaterThanOrEqualToConstant: .uiControlButtonMinWidth),
         heightAnchor.constraint(equalToConstant: .uiControlButtonHeight)]
    }
}

extension Array where Element: NSLayoutConstraint {
    @discardableResult func activate() -> Array {
        forEach { $0.isActive = true }
        return self
    }
}
