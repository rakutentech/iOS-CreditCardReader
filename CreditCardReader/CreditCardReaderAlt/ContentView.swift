//
//  ContentView.swift
//  CreditCardReaderAlt
//
//  Created by Wong, Kevin a on 2021/04/20.
//

import AltSwiftUI

struct ContentView: View {
    var viewStore = ViewValues()

    @State private var showCardReader = false
    @State private var creditCard: CreditCard?

    var body: View {
        VStack {
            Button("Read Card") {
                showCardReader = true
            }
            if let creditCard = creditCard {
                Text("\(creditCard.cardNumberDisplayString)\n\(creditCard.expirationDateDisplayString ?? "")")
            }
        }
        .sheet(isPresented: $showCardReader) {
            CreditCardReadView { card, _ in
                creditCard = card
            }
        }
    }
}
