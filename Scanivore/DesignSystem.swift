//
//  DesignSystem.swift
//  Scanivore
//
//  Created by Alex Paul on 6/28/25.
//

import SwiftUI

struct DesignSystem {
    
    // MARK: - Colors
    struct Colors {
        // Primary Red Colors
        static let primaryRed = Color(red: 196/255, green: 30/255, blue: 58/255) // #C41E3A
        static let primaryRedHover = Color(red: 169/255, green: 23/255, blue: 41/255) // #A91729
        static let primaryRedLight = Color(red: 232/255, green: 70/255, blue: 92/255) // #E8465C
        
        // Supporting Colors
        static let success = Color(red: 76/255, green: 175/255, blue: 80/255) // #4CAF50
        static let warning = Color(red: 255/255, green: 193/255, blue: 7/255) // #FFC107
        static let error = Color(red: 211/255, green: 47/255, blue: 47/255) // #D32F2F
        
        // Neutral Palette
        static let background = Color.white // #FFFFFF
        static let backgroundSecondary = Color(red: 245/255, green: 245/255, blue: 245/255) // #F5F5F5
        static let backgroundTertiary = Color(red: 250/255, green: 250/255, blue: 250/255) // #FAFAFA
        
        static let border = Color(red: 224/255, green: 224/255, blue: 224/255) // #E0E0E0
        static let borderLight = Color(red: 204/255, green: 204/255, blue: 204/255) // #CCCCCC
        
        static let textPrimary = Color(red: 33/255, green: 33/255, blue: 33/255) // #212121
        static let textSecondary = Color(red: 117/255, green: 117/255, blue: 117/255) // #757575
        
        // Card shadows
        static let shadowLight = Color.black.opacity(0.1)
        static let shadowMedium = Color.black.opacity(0.15)
    }
    
    // MARK: - Typography
    struct Typography {
        // Font Sizes - Matching Airbnb's hierarchy
        static let xs: CGFloat = 12
        static let sm: CGFloat = 14
        static let base: CGFloat = 16
        static let md: CGFloat = 18
        static let lg: CGFloat = 20
        static let xl: CGFloat = 22
        static let xxl: CGFloat = 24
        static let xxxl: CGFloat = 28
        static let xxxxl: CGFloat = 36
        static let xxxxxl: CGFloat = 44
        
        // Airbnb Cereal Font Names
        private static let cerealLight = "AirbnbCereal_W_Lt"
        private static let cerealBook = "AirbnbCereal_W_Bk"
        private static let cerealMedium = "AirbnbCereal_W_Md"
        private static let cerealBold = "AirbnbCereal_W_Bd"
        private static let cerealExtraBold = "AirbnbCereal_W_XBd"
        private static let cerealBlack = "AirbnbCereal_W_Blk"
        
        // Text Styles - Using Airbnb Cereal Fonts with fallbacks
        static let hero = Font.custom(cerealMedium, size: xxxxxl, relativeTo: .largeTitle)
        static let heading1 = Font.custom(cerealMedium, size: xxxl, relativeTo: .title)
        static let heading2 = Font.custom(cerealBook, size: xxl, relativeTo: .title2)
        static let heading3 = Font.custom(cerealMedium, size: lg, relativeTo: .title3)
        static let body = Font.custom(cerealBook, size: base, relativeTo: .body)
        static let bodyMedium = Font.custom(cerealMedium, size: base, relativeTo: .body)
        static let bodySemibold = Font.custom(cerealBold, size: base, relativeTo: .body)
        static let caption = Font.custom(cerealBook, size: sm, relativeTo: .caption)
        static let captionMedium = Font.custom(cerealMedium, size: sm, relativeTo: .caption)
        static let small = Font.custom(cerealBook, size: xs, relativeTo: .caption2)
        
        // Special styles for prices and emphasis
        static let price = Font.custom(cerealBold, size: base, relativeTo: .body)
        static let priceSmall = Font.custom(cerealMedium, size: sm, relativeTo: .caption)
        static let label = Font.custom(cerealMedium, size: xs, relativeTo: .caption2)
        static let buttonText = Font.custom(cerealMedium, size: base, relativeTo: .body)
        
        // Navigation and section styles
        static let navigationTitle = Font.custom(cerealMedium, size: md, relativeTo: .headline)
        static let sectionHeader = Font.custom(cerealBold, size: xs, relativeTo: .caption2)
    }
    
    // MARK: - Spacing
    struct Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let base: CGFloat = 16
        static let lg: CGFloat = 20
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
        static let xxxl: CGFloat = 40
        static let xxxxl: CGFloat = 48
        static let xxxxxl: CGFloat = 64
        
        // Component specific spacing
        static let cardPadding: CGFloat = 16
        static let buttonPadding: CGFloat = 16
        static let inputPadding: CGFloat = 12
        static let sectionSpacing: CGFloat = 24
        static let elementGap: CGFloat = 12
        static let iconTextGap: CGFloat = 8
        static let screenPadding: CGFloat = 16
    }
    
    // MARK: - Corner Radius
    struct CornerRadius {
        static let none: CGFloat = 0
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 24
        static let xxxl: CGFloat = 32
        static let full: CGFloat = 50
    }
    
    // MARK: - Shadows
    struct Shadow {
        static let light = Color.black.opacity(0.08)
        static let medium = Color.black.opacity(0.12)
        static let heavy = Color.black.opacity(0.16)
        
        static let offsetLight: CGSize = CGSize(width: 0, height: 2)
        static let offsetMedium: CGSize = CGSize(width: 0, height: 4)
        static let offsetHeavy: CGSize = CGSize(width: 0, height: 8)
        
        static let radiusLight: CGFloat = 4
        static let radiusMedium: CGFloat = 8
        static let radiusHeavy: CGFloat = 16
    }
    
    // MARK: - Component Styles
    struct Components {
        
        // Button Styles
        struct Button {
            static let primaryHeight: CGFloat = 48
            static let secondaryHeight: CGFloat = 40
            static let smallHeight: CGFloat = 32
            
            static let primaryCornerRadius: CGFloat = CornerRadius.xxl
            static let secondaryCornerRadius: CGFloat = CornerRadius.md
        }
        
        // Card Styles
        struct Card {
            static let backgroundColor = Colors.background
            static let cornerRadius: CGFloat = CornerRadius.md
            static let padding: CGFloat = Spacing.base
            static let shadow = Shadow.light
            static let shadowOffset = Shadow.offsetLight
            static let shadowRadius = Shadow.radiusLight
        }
        
        // Input Styles
        struct Input {
            static let height: CGFloat = 48
            static let cornerRadius: CGFloat = CornerRadius.md
            static let borderColor = Colors.border
            static let backgroundColor = Colors.background
            static let padding: CGFloat = Spacing.inputPadding
        }
        
        // Scanner Styles
        struct Scanner {
            static let buttonSize: CGFloat = 80
            static let progressSize: CGFloat = 120
            static let frameColor = Colors.background.opacity(0.8)
            static let scanColor = Colors.primaryRed
        }
    }
}

// MARK: - ViewModifiers
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DesignSystem.Typography.buttonText)
            .foregroundColor(.white)
            .frame(height: DesignSystem.Components.Button.primaryHeight)
            .frame(maxWidth: .infinity)
            .background(DesignSystem.Colors.primaryRed)
            .cornerRadius(DesignSystem.Components.Button.primaryCornerRadius)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DesignSystem.Typography.buttonText)
            .foregroundColor(DesignSystem.Colors.primaryRed)
            .frame(height: DesignSystem.Components.Button.secondaryHeight)
            .frame(maxWidth: .infinity)
            .background(DesignSystem.Colors.background)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.Components.Button.secondaryCornerRadius)
                    .stroke(DesignSystem.Colors.primaryRed, lineWidth: 1)
            )
            .cornerRadius(DesignSystem.Components.Button.secondaryCornerRadius)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
    }
}

struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(DesignSystem.Components.Card.padding)
            .background(DesignSystem.Components.Card.backgroundColor)
            .cornerRadius(DesignSystem.Components.Card.cornerRadius)
            .shadow(
                color: DesignSystem.Components.Card.shadow,
                radius: DesignSystem.Components.Card.shadowRadius,
                x: DesignSystem.Components.Card.shadowOffset.width,
                y: DesignSystem.Components.Card.shadowOffset.height
            )
    }
}

// MARK: - Navigation Title Modifier
struct NavigationTitleModifier: ViewModifier {
    let title: String
    
    func body(content: Content) -> some View {
        content
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(title)
                        .font(DesignSystem.Typography.navigationTitle)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                }
            }
    }
}

// MARK: - View Extensions
extension View {
    func cardStyle() -> some View {
        self.modifier(CardStyle())
    }
    
    func primaryButton() -> some View {
        self.buttonStyle(PrimaryButtonStyle())
    }
    
    func secondaryButton() -> some View {
        self.buttonStyle(SecondaryButtonStyle())
    }
    
    func customNavigationTitle(_ title: String) -> some View {
        self.modifier(NavigationTitleModifier(title: title))
    }
}