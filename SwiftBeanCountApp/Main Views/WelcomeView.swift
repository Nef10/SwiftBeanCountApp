//
//  WelcomeView.swift
//  SwiftBeanCountApp
//
//  Created by Steffen Kötte on 2024-02-17.
//

import SwiftUI

/// Used if there is either no tab or no ledger selected
struct WelcomeView<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack {
            Text("Welcome to SwiftBeanCount")
                .font(.largeTitle)
                .padding()
            Image("Icon")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: 400)
                .padding()
                .accessibilityLabel(Text("Logo of the SwiftBeanCount app"))
            content
            Spacer()
        }.padding()
    }
}

#Preview {
    WelcomeView {
        Text("To get started, select an option from the menu on the right.")
            .font(.title3)
    }
}
