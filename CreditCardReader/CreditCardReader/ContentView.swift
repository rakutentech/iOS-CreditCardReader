//
//  ContentView.swift
//  CreditCardReader
//
//  Created by Wong, Kevin a on 2021/04/19.
//

import SwiftUI

struct ContentView: View {
    @State private var showCardReader = false
    @State private var showCardReaderNoRetry = false
    @State private var showCardReaderCustom = false
    @State private var showUIKitCardReader = false
    @State private var creditCard: CreditCard?
    
    var body: some View {
        VStack {
            Button("Read Card") {
                showCardReader = true
            }
            .sheet(isPresented: $showCardReader) {
                CreditCardReaderView { card, _ in
                    creditCard = card
                }
            }
            
            Button("Read Card No Retry") {
                showCardReaderNoRetry = true
            }
            .sheet(isPresented: $showCardReaderNoRetry) {
                CreditCardReaderView(defaultUIControls: .init(isRetryEnabled: false)) { card, _ in
                    creditCard = card
                }
            }
            
            Button("Read Card Custom") {
                showCardReaderCustom = true
            }
            .sheet(isPresented: $showCardReaderCustom) {
                ZStack(alignment: .top) {
                    CreditCardReaderView(
                        defaultNavigationBar: nil,
                        defaultUIControls: nil) { card, _ in
                        creditCard = card
                    }
                    
                    Button("Custom Close") {
                        showCardReaderCustom = false
                    }
                }
            }
            
            Button("Read UIKit Card") {
                showUIKitCardReader = true
            }
            .sheet(isPresented: $showUIKitCardReader) {
                CreditCardReaderViewControllerRep { card in
                    creditCard = card
                } onClose: {
                    showUIKitCardReader = false
                }
                .edgesIgnoringSafeArea(.bottom)
            }
            
            if let creditCard = creditCard {
                Text("\(creditCard.cardNumberDisplayString)\n\(creditCard.expirationDateDisplayString ?? "")")
            }
        }
    }
}

@available(iOS 13, *)
struct CreditCardReaderViewControllerRep: UIViewControllerRepresentable {
    var onSuccess: (CreditCard) -> Void
    var onClose: () -> Void
    
    func makeUIViewController(context: Self.Context) -> CreditCardReaderViewController {
        CreditCardReaderViewController { card, _ in
            onSuccess(card)
        } onControllerClosed: {
            onClose()
        }
    }
    func updateUIViewController(_ uiViewController: CreditCardReaderViewController, context: Context) {
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
