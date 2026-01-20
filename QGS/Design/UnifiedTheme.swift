import SwiftUI

// MARK: - Unified Theme System
/// Central theme management for all app targets (QGS, FriendlyCheckInOut, MCS)
/// Ensures consistent UI experience across all three applications

protocol ThemeProtocol {
    // Colors
    var primaryColor: Color { get }
    var secondaryColor: Color { get }
    var accentColor: Color { get }
    var backgroundColor: Color { get }
    var surfaceColor: Color { get }
    var errorColor: Color { get }
    var successColor: Color { get }
    var warningColor: Color { get }
    
    // Typography
    var primaryFont: String { get }
    var monospacedFont: String { get }
    
    // Styling
    var cornerRadius: CornerRadiusStyle { get }
    var shadowStyle: ShadowStyle { get }
    var animationStyle: AnimationStyle { get }
}

// MARK: - Style Definitions
struct CornerRadiusStyle {
    let small: CGFloat
    let medium: CGFloat
    let large: CGFloat
    let extraLarge: CGFloat
}

struct ShadowStyle {
    let light: (radius: CGFloat, opacity: Double)
    let medium: (radius: CGFloat, opacity: Double)
    let heavy: (radius: CGFloat, opacity: Double)
}

struct AnimationStyle {
    let quick: Double
    let standard: Double
    let slow: Double
}

// MARK: - Base Theme
class BaseTheme: ThemeProtocol {
    // Default colors that adapt to dark/light mode
    var primaryColor: Color { Color("myPrimaries") }
    var secondaryColor: Color { Color("secondaryColor") }
    var accentColor: Color { Color.accentColor }
    var backgroundColor: Color { Color(.systemBackground) }
    var surfaceColor: Color { Color(.secondarySystemBackground) }
    var errorColor: Color { Color(.systemRed) }
    var successColor: Color { Color(.systemGreen) }
    var warningColor: Color { Color(.systemOrange) }
    
    // Typography
    var primaryFont: String { "System" }
    var monospacedFont: String { "Menlo" }
    
    // Consistent styling across all apps
    var cornerRadius = CornerRadiusStyle(
        small: 8,
        medium: 12,
        large: 16,
        extraLarge: 24
    )
    
    var shadowStyle = ShadowStyle(
        light: (radius: 2, opacity: 0.1),
        medium: (radius: 4, opacity: 0.15),
        heavy: (radius: 8, opacity: 0.2)
    )
    
    var animationStyle = AnimationStyle(
        quick: 0.2,
        standard: 0.3,
        slow: 0.5
    )
}

// MARK: - QGS Theme
class QGSTheme: BaseTheme {
    override var primaryColor: Color { 
        Color(red: 0.0, green: 0.478, blue: 1.0) // QGS Blue
    }
    
    override var accentColor: Color {
        Color(red: 0.0, green: 0.478, blue: 1.0)
    }
}

// MARK: - FriendlyCheckInOut Theme
class FriendlyTheme: BaseTheme {
    override var primaryColor: Color {
        Color(red: 0.2, green: 0.7, blue: 0.3) // Friendly Green
    }
    
    override var accentColor: Color {
        Color(red: 0.2, green: 0.7, blue: 0.3)
    }
}

// MARK: - MCS Theme
class MCSTheme: BaseTheme {
    override var primaryColor: Color {
        Color(red: 1.0, green: 0.584, blue: 0.0) // MCS Orange
    }
    
    override var accentColor: Color {
        Color(red: 1.0, green: 0.584, blue: 0.0)
    }
}

// MARK: - Theme Manager
// ThemeManager has been moved to ThemeManager.swift for better organization

// MARK: - Theme Environment Key
struct ThemeEnvironmentKey: EnvironmentKey {
    static let defaultValue: ThemeProtocol = QGSTheme()
}

extension EnvironmentValues {
    var theme: ThemeProtocol {
        get { self[ThemeEnvironmentKey.self] }
        set { self[ThemeEnvironmentKey.self] = newValue }
    }
}

// MARK: - Themed View Modifiers
extension View {
    func themed() -> some View {
        self.environmentObject(ThemeManager.shared)
    }
    
    func themedCard() -> some View {
        self.modifier(ThemedCardModifier())
    }
    
    func themedButton(style: ThemedButtonStyle.ButtonType = .primary) -> some View {
        self.buttonStyle(ThemedButtonStyle(type: style))
    }
    
    func themedTextField() -> some View {
        self.modifier(ThemedTextFieldModifier())
    }
}

// MARK: - Card Modifier
struct ThemedCardModifier: ViewModifier {
    @EnvironmentObject var themeManager: ThemeManager
    
    func body(content: Content) -> some View {
        content
            .padding()
            .background(themeManager.currentTheme.surfaceColor)
            .cornerRadius(themeManager.currentTheme.cornerRadius.medium)
            .shadow(
                radius: themeManager.currentTheme.shadowStyle.medium.radius,
                y: 2
            )
    }
}

// MARK: - Button Style
struct ThemedButtonStyle: ButtonStyle {
    enum ButtonType {
        case primary
        case secondary
        case destructive
    }
    
    let type: ButtonType
    @EnvironmentObject var themeManager: ThemeManager
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(backgroundColor(for: configuration.isPressed))
            .foregroundColor(foregroundColor())
            .cornerRadius(themeManager.currentTheme.cornerRadius.medium)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: themeManager.currentTheme.animationStyle.quick), value: configuration.isPressed)
    }
    
    private func backgroundColor(for isPressed: Bool) -> Color {
        let opacity: Double = isPressed ? 0.8 : 1.0
        switch type {
        case .primary:
            return themeManager.currentTheme.primaryColor.opacity(opacity)
        case .secondary:
            return themeManager.currentTheme.secondaryColor.opacity(opacity)
        case .destructive:
            return themeManager.currentTheme.errorColor.opacity(opacity)
        }
    }
    
    private func foregroundColor() -> Color {
        switch type {
        case .primary, .destructive:
            return .white
        case .secondary:
            return themeManager.currentTheme.primaryColor
        }
    }
}

// MARK: - TextField Modifier
struct ThemedTextFieldModifier: ViewModifier {
    @EnvironmentObject var themeManager: ThemeManager
    
    func body(content: Content) -> some View {
        content
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(themeManager.currentTheme.cornerRadius.small)
            .overlay(
                RoundedRectangle(cornerRadius: themeManager.currentTheme.cornerRadius.small)
                    .stroke(themeManager.currentTheme.primaryColor.opacity(0.2), lineWidth: 1)
            )
    }
}

// MARK: - Common UI Components
struct ThemedNavigationBar: View {
    let title: String
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        HStack {
            Text(title)
                .font(.largeTitle)
                .bold()
                .foregroundColor(themeManager.currentTheme.primaryColor)
            Spacer()
        }
        .padding()
        .background(themeManager.currentTheme.backgroundColor)
    }
}

struct ThemedLoadingView: View {
    let message: String
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: themeManager.currentTheme.primaryColor))
                .scaleEffect(1.5)
            
            Text(message)
                .font(.body)
                .foregroundColor(themeManager.currentTheme.secondaryColor)
        }
        .padding(40)
        .background(themeManager.currentTheme.surfaceColor)
        .cornerRadius(themeManager.currentTheme.cornerRadius.large)
        .shadow(
            radius: themeManager.currentTheme.shadowStyle.medium.radius,
            y: 2
        )
    }
}

struct ThemedEmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var action: (() -> Void)? = nil
    var actionTitle: String = "Retry"
    
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: icon)
                .font(.system(size: 64))
                .foregroundColor(themeManager.currentTheme.secondaryColor)
            
            VStack(spacing: 12) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(message)
                    .font(.body)
                    .foregroundColor(themeManager.currentTheme.secondaryColor)
                    .multilineTextAlignment(.center)
            }
            
            if let action = action {
                Button(action: action) {
                    Text(actionTitle)
                }
                .themedButton(style: .primary)
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Theme-aware Color Extensions
extension Color {
    static var themedPrimary: Color {
        ThemeManager.shared.currentTheme.primaryColor
    }
    
    static var themedSecondary: Color {
        ThemeManager.shared.currentTheme.secondaryColor
    }
    
    static var themedAccent: Color {
        ThemeManager.shared.currentTheme.accentColor
    }
    
    static var themedBackground: Color {
        ThemeManager.shared.currentTheme.backgroundColor
    }
    
    static var themedSurface: Color {
        ThemeManager.shared.currentTheme.surfaceColor
    }
    
    static var themedError: Color {
        ThemeManager.shared.currentTheme.errorColor
    }
    
    static var themedSuccess: Color {
        ThemeManager.shared.currentTheme.successColor
    }
    
    static var themedWarning: Color {
        ThemeManager.shared.currentTheme.warningColor
    }
}