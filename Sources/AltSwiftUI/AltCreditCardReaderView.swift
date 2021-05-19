//
//  AltCreditCardReaderView.swift
//  CreditCardReaderAlt
//
//  Created by Wong, Kevin a on 2021/04/20.
//

import Foundation
import AltSwiftUI

/// View that contains a camera output view and reads credit card information.
/// Use this to retrieve credit card information of a user selected result.
@available(iOS 13, *)
public struct CreditCardReaderView: View {
    public var viewStore = ViewValues()
    
    public typealias Retry = () -> Void
    public typealias Success = (CreditCard, Retry?) -> Void
    public typealias Failure = (Error) -> Void
    
    var defaultNavigationBar: CreditCardReaderDefaultNavigationBar?
    var defaultUIControls: CreditCardReaderDefaultControls?
    var onSuccess: Success
    var onFailure: Failure?
    
    @Environment(\.presentationMode) private var presentationMode
    @State private var cardController = CardCaptureController()
    @State private var creditCard: CreditCard?
    @State private var retryCapture: Retry?
    
    /// Initializes a `CreditCardReaderView` with customizable controls.
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
    public init(
        defaultNavigationBar: CreditCardReaderDefaultNavigationBar? = CreditCardReaderDefaultNavigationBar(),
        defaultUIControls: CreditCardReaderDefaultControls? = CreditCardReaderDefaultControls(),
        onSuccess: @escaping Success,
        onFailure: Failure? = nil) {
        self.defaultNavigationBar = defaultNavigationBar
        self.defaultUIControls = defaultUIControls
        self.onSuccess = onSuccess
        self.onFailure = onFailure
    }
}

@available(iOS 13, *)
extension CreditCardReaderView {
    public var body: View {
        ZStack {
            CardCaptureRepresentableView(
                cardController: cardController,
                onSuccess: { card, retry in
                    if let defaultUIControls = defaultUIControls {
                        retryCapture = retry
                        creditCard = card
                        if !defaultUIControls.isRetryEnabled {
                            DispatchQueue.main.asyncAfter(deadline: .now() + Double.cardReaderCloseTimeDelay) {
                                onSuccess(card, retry)
                                if defaultUIControls.navigatesBackOnDetection {
                                    presentationMode.wrappedValue.dismiss()
                                }
                            }
                        }
                    } else {
                        onSuccess(card, retry)
                    }
                },
                onFailure: onFailure)
                .background(Color.black)
                .edgesIgnoringSafeArea(.all)
                .onAppear {
                    // Delay camera start to prevent frozen frames while
                    // the view is opening
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        cardController.startCapture()
                    }
                }
                .onDisappear {
                    cardController.stopCapture()
                }
            
            if let defaultUIControls = defaultUIControls {
                controlsOverlayView(defaultUIControls: defaultUIControls)
            }
        }
    }
    
    private func controlsOverlayView(defaultUIControls: CreditCardReaderDefaultControls) -> View {
        VStack(spacing: 0) {
            if let defaultNavigationBar = defaultNavigationBar {
                topControlsView(defaultNavigationBar: defaultNavigationBar)
            }
            Spacer()
            ZStack(alignment: .bottom) {
                Text(defaultUIControls.instructionsText)
                    .foregroundColor(.white)
                    .shadow(radius: 2)
                    .padding(.bottom, 40)
                    .padding(.horizontal, 16)
                    .frame(maxWidth: .infinity)
                    .background(Color.black)
                if let creditCard = creditCard {
                    bottomControlsView(creditCard: creditCard, defaultUIControls: defaultUIControls)
                }
            }
        }
    }
    
    private func topControlsView(defaultNavigationBar: CreditCardReaderDefaultNavigationBar) -> View {
        HStack() {
            Button(defaultNavigationBar.closeText) {
                presentationMode.wrappedValue.dismiss()
            }
            .accentColor(.white)
            .frame(width: 80)
            
            Text(defaultNavigationBar.titleText)
                .font(.headline)
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .frame(maxWidth: .infinity)
            
            Text("")
                .frame(width: 80)
        }
        .frame(height: 44)
    }
    
    private func bottomControlsView(creditCard: CreditCard, defaultUIControls: CreditCardReaderDefaultControls) -> View {
        VStack(spacing: 0) {
            Text(verbatim: creditCard.cardNumberDisplayString)
                .font(.title2)
                .foregroundColor(.white)
            
            if let expirationDate = creditCard.expirationDateDisplayString {
                Text(verbatim: expirationDate)
                    .font(.title3)
                    .foregroundColor(.white)
                    .padding(.top, 4)
            }
            if defaultUIControls.isRetryEnabled  {
                HStack(spacing: .uiControlButtonSpacing) {
                    Button(action: {
                        withAnimation {
                            self.creditCard = nil
                        }
                        retryCapture?()
                        retryCapture = nil
                    }, label: {
                        Text(defaultUIControls.retryText)
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .frame(height: .uiControlButtonHeight)
                            .frame(minWidth: .uiControlButtonMinWidth)
                            .cornerRadius(.uiControlButtonHeight / 2)
                            .border(.white, width:  1)
                    })
                    
                    Button(action: {
                        onSuccess(creditCard, nil)
                        if defaultUIControls.navigatesBackOnDetection {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }, label: {
                        Text(defaultUIControls.confirmText)
                            .font(.headline)
                            .foregroundColor(.black)
                            .padding(.horizontal, 10)
                            .frame(height: .uiControlButtonHeight)
                            .frame(minWidth: .uiControlButtonMinWidth)
                            .background(Color.white)
                            .cornerRadius(.uiControlButtonHeight / 2)
                    })
                }
                .padding(.top, .uiControlButtonSpacing)
            }
            Spacer()
                .frame(height: .uiControlButtonSpacing)
        }
        .padding(.top, 10)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
        .background(Color.black)
        .transition(AnyTransition
            .opacity
            .combined(with: .offset(y: 30))
            .animation(.easeInOut(duration: 0.2)))
    }
}

@available(iOS 13, *)
struct CardCaptureRepresentableView: UIViewRepresentable {
    var viewStore = ViewValues()
    
    var cardController: CardCaptureController
    var onSuccess: (CreditCard, @escaping CardCaptureView.Retry) -> Void
    var onFailure: ((Error) -> Void)?
    
    func makeUIView(context: UIContext) -> CardCaptureView {
        let view = CardCaptureView(onSuccess: onSuccess, onFailure: onFailure)
        cardController.captureView = view
        return view
    }
    
    func updateUIView(_ uiView: CardCaptureView, context: UIContext) {
    }
}
