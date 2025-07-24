//
//  LaunchScreenView.swift
//  Scanivore
//
//  Launch screen that appears every time the app opens
//

import SwiftUI

struct LaunchScreenView: View {
    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()
            
            Image("Scanivore@2x")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: 200)
        }
    }
}

#Preview {
    LaunchScreenView()
}