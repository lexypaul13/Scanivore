
import SwiftUI

struct LaunchScreenView: View {
    var body: some View {
        ZStack {
            DesignSystem.Colors.background
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
