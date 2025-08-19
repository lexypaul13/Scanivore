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
        // Primary Red Colors (Stay consistent in both modes)
        static let primaryRed = Color(red: 196/255, green: 30/255, blue: 58/255) // #C41E3A
        static let primaryRedHover = Color(red: 169/255, green: 23/255, blue: 41/255) // #A91729
        static let primaryRedLight = Color(red: 232/255, green: 70/255, blue: 92/255) // #E8465C
        
        // Supporting Colors (Slightly adjusted for dark mode visibility)
        static let success = Color(red: 76/255, green: 175/255, blue: 80/255) // #4CAF50
        static let warning = Color(red: 255/255, green: 193/255, blue: 7/255) // #FFC107
        static let error = Color(red: 211/255, green: 47/255, blue: 47/255) // #D32F2F
        
        // Neutral Palette (Adaptive - automatically switches with system appearance)
        static let background = Color(UIColor.systemBackground) // White in light, Black in dark
        static let backgroundSecondary = Color(UIColor.secondarySystemBackground) // Light gray in light, Dark gray in dark
        static let backgroundTertiary = Color(UIColor.tertiarySystemBackground) // Very light gray in light, Darker gray in dark
        
        // Borders (Adaptive)
        static let border = Color(UIColor.separator) // Light border in light mode, Dark border in dark mode
        static let borderLight = Color(UIColor.opaqueSeparator) // Slightly stronger border
        
        // Text Colors (Adaptive)
        static let textPrimary = Color(UIColor.label) // Black in light, White in dark
        static let textSecondary = Color(UIColor.secondaryLabel) // Gray in light, Light gray in dark
        
        // Card shadows (Adaptive opacity)
        static let shadowLight = Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor.white.withAlphaComponent(0.05)
                : UIColor.black.withAlphaComponent(0.1)
        })
        static let shadowMedium = Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor.white.withAlphaComponent(0.08)
                : UIColor.black.withAlphaComponent(0.15)
        })
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
        
        // Helper function to create fonts with proper fallback
        private static func customFont(_ name: String, size: CGFloat, relativeTo textStyle: Font.TextStyle) -> Font {
            // Check if font exists, otherwise fallback to system font
            if UIFont(name: name, size: size) != nil {
                return Font.custom(name, size: size, relativeTo: textStyle)
            } else {
                // Fallback to system font with appropriate weight
                switch name {
                case cerealLight:
                    return Font.system(size: size, weight: .light, design: .default)
                case cerealBook:
                    return Font.system(size: size, weight: .regular, design: .default)
                case cerealMedium:
                    return Font.system(size: size, weight: .medium, design: .default)
                case cerealBold:
                    return Font.system(size: size, weight: .bold, design: .default)
                case cerealExtraBold:
                    return Font.system(size: size, weight: .heavy, design: .default)
                case cerealBlack:
                    return Font.system(size: size, weight: .black, design: .default)
                default:
                    return Font.system(size: size, weight: .regular, design: .default)
                }
            }
        }
        
        // Text Styles - Using Airbnb Cereal Fonts with fallbacks
        static let hero = customFont(cerealMedium, size: xxxxxl, relativeTo: .largeTitle)
        static let heading1 = customFont(cerealMedium, size: xxxl, relativeTo: .title)
        static let heading2 = customFont(cerealBook, size: xxl, relativeTo: .title2)
        static let heading3 = customFont(cerealMedium, size: lg, relativeTo: .title3)
        static let body = customFont(cerealBook, size: base, relativeTo: .body)
        static let bodyMedium = customFont(cerealMedium, size: base, relativeTo: .body)
        static let bodySemibold = customFont(cerealBold, size: base, relativeTo: .body)
        static let caption = customFont(cerealBook, size: sm, relativeTo: .caption)
        static let captionMedium = customFont(cerealMedium, size: sm, relativeTo: .caption)
        static let small = customFont(cerealBook, size: xs, relativeTo: .caption2)
        
        // Special styles for prices and emphasis
        static let price = customFont(cerealBold, size: base, relativeTo: .body)
        static let priceSmall = customFont(cerealMedium, size: sm, relativeTo: .caption)
        static let label = customFont(cerealMedium, size: xs, relativeTo: .caption2)
        static let buttonText = customFont(cerealMedium, size: base, relativeTo: .body)
        
        // Navigation and section styles
        static let navigationTitle = customFont(cerealMedium, size: md, relativeTo: .headline)
        static let sectionHeader = customFont(cerealBold, size: xs, relativeTo: .caption2)
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
        static let light = Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor.white.withAlphaComponent(0.05)
                : UIColor.black.withAlphaComponent(0.08)
        })
        static let medium = Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor.white.withAlphaComponent(0.08)
                : UIColor.black.withAlphaComponent(0.12)
        })
        static let heavy = Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor.white.withAlphaComponent(0.10)
                : UIColor.black.withAlphaComponent(0.16)
        })
        
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
    
    // Text modifier for proper line breaking with custom fonts
    func textLineBreaking() -> some View {
        self
            .fixedSize(horizontal: false, vertical: true)
            .allowsTightening(true)
            .minimumScaleFactor(0.9)
    }
}