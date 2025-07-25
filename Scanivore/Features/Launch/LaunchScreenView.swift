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
            
            Image("Scanivore_Logo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: 200)
        }
    }
}

#Preview {
    LaunchScreenView()
}