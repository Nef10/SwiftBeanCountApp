//
//  LoadingView.swift
//  SwiftBeanCountApp
//
//  Created by Steffen Kötte on 2024-03-31.
//

import SwiftUI

struct LoadingView: View {
    var body: some View {
        Spacer()
        HStack {
            Spacer()
            ProgressView()
            Spacer()
        }
        Spacer()
    }
}

#Preview {
    LoadingView()
}
