import SwiftUI

// MARK: - Design System for QGS
/// Comprehensive design system providing consistent spacing, typography, colors, and animations
/// This replaces hardcoded values throughout the app for better maintainability

struct DesignSystem {
    
    // MARK: - Spacing System
    /// Consistent spacing values following 8pt grid system
    enum Spacing {
        static let xs: CGFloat = 4      // Extra small
        static let sm: CGFloat = 8      // Small
        static let md: CGFloat = 16     // Medium (base unit)
        static let lg: CGFloat = 24     // Large
        static let xl: CGFloat = 32     // Extra large
        static let xxl: CGFloat = 48    // Double extra large
        static let xxxl: CGFloat = 64   // Triple extra large
        
        // Semantic spacing
        static let cardPadding = md
        static let sectionSpacing = lg
        static let buttonPadding = md
        static let inputPadding = sm
    }
    
    // MARK: - Typography System
    /// Semantic typography scale for consistent text hierarchy
    enum Typography {
        // Display fonts
        static let display = Font.system(size: 32, weight: .bold, design: .default)
        
        // Title fonts
        static let largeTitle = Font.largeTitle.weight(.bold)
        static let title = Font.title.weight(.semibold)
        static let title2 = Font.title2.weight(.semibold)
        static let title3 = Font.title3.weight(.medium)
        
        // Body fonts
        static let headline = Font.headline.weight(.medium)
        static let subheadline = Font.subheadline.weight(.regular)
        static let body = Font.body.weight(.regular)
        static let bodyMedium = Font.body.weight(.medium)
        static let bodySemibold = Font.body.weight(.semibold)
        
        // Supporting fonts
        static let callout = Font.callout.weight(.regular)
        static let caption = Font.caption.weight(.regular)
        static let caption2 = Font.caption2.weight(.regular)
        static let footnote = Font.footnote.weight(.regular)
        
        // Button specific
        static let buttonLarge = Font.system(size: 18, weight: .semibold)
        static let buttonMedium = Font.system(size: 16, weight: .medium)
        static let buttonSmall = Font.system(size: 14, weight: .medium)
    }
    
    // MARK: - Border Radius System
    /// Consistent corner radius values
    enum CornerRadius {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 24
        static let round: CGFloat = 999  // For fully rounded elements
        
        // Semantic radius
        static let button = md
        static let card = lg
        static let input = sm
        static let badge = round
    }
    
    // MARK: - Shadow System
    /// Elevation system for consistent depth
    enum Shadow {
        static let light: CGFloat = 2
        static let medium: CGFloat = 4
        static let heavy: CGFloat = 8
        static let extraHeavy: CGFloat = 16
        
        // Semantic shadows
        static let card = medium
        static let button = light
        static let modal = heavy
        static let dropdown = medium
    }
    
    // MARK: - Animation System
    /// Consistent animation timing and easing
    enum Animation {
        // Duration
        static let fast: Double = 0.15
        static let normal: Double = 0.25
        static let slow: Double = 0.35
        
        // Spring animations
        static let springFast = SwiftUI.Animation.spring(response: 0.3, dampingFraction: 0.8)
        static let springNormal = SwiftUI.Animation.spring(response: 0.5, dampingFraction: 0.8)
        static let springSlow = SwiftUI.Animation.spring(response: 0.7, dampingFraction: 0.8)
        
        // Easing animations
        static let easeInOut = SwiftUI.Animation.easeInOut(duration: normal)
        static let easeOut = SwiftUI.Animation.easeOut(duration: normal)
        static let easeIn = SwiftUI.Animation.easeIn(duration: normal)
        
        // Interactive animations
        static let buttonPress = SwiftUI.Animation.easeInOut(duration: fast)
        static let stateChange = SwiftUI.Animation.easeInOut(duration: normal)
        static let pageTransition = springNormal
    }
    
    // MARK: - Icon System
    /// Consistent icon sizing
    enum IconSize {
        static let xs: CGFloat = 12
        static let sm: CGFloat = 16
        static let md: CGFloat = 20
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
        
        // Semantic sizes
        static let buttonIcon = sm
        static let tabIcon = lg
        static let headerIcon = xl
        static let featureIcon = xxl
    }
    
    // MARK: - Layout System
    /// Responsive layout constants
    enum Layout {
        static let maxContentWidth: CGFloat = 428  // iPhone 14 Pro Max width
        static let minTouchTarget: CGFloat = 44    // Minimum touch target
        static let tabBarHeight: CGFloat = 83      // Standard tab bar height
        static let navigationBarHeight: CGFloat = 44
        
        // Breakpoints
        static let compactWidth: CGFloat = 414     // iPhone Plus/Max width
        static let regularWidth: CGFloat = 768     // iPad width
    }
}

// MARK: - Enhanced Color System
extension Color {
    
    // MARK: - Brand Colors
    /// Primary brand colors that work in light and dark mode
    static var brandPrimary: Color {
        Color("BrandPrimary") // Define in Assets.xcassets
    }
    
    static var brandSecondary: Color {
        Color("BrandSecondary")
    }
    
    static var brandAccent: Color {
        Color("BrandAccent")
    }
    
    // MARK: - Semantic Colors
    /// Colors that convey meaning and adapt to color scheme
    static var success: Color {
        Color(.systemGreen)
    }
    
    static var warning: Color {
        Color(.systemOrange)
    }
    
    static var error: Color {
        Color(.systemRed)
    }
    
    static var info: Color {
        Color(.systemBlue)
    }
    
    // MARK: - Surface Colors
    /// Background colors that adapt to light/dark mode
    static var surfacePrimary: Color {
        Color(.systemBackground)
    }
    
    static var surfaceSecondary: Color {
        Color(.secondarySystemBackground)
    }
    
    static var surfaceTertiary: Color {
        Color(.tertiarySystemBackground)
    }
    
    static var surfaceGrouped: Color {
        Color(.systemGroupedBackground)
    }
    
    static var surfaceGroupedSecondary: Color {
        Color(.secondarySystemGroupedBackground)
    }
    
    // MARK: - Text Colors
    /// Text colors that provide proper contrast in all modes
    static var textPrimary: Color {
        Color(.label)
    }
    
    static var textSecondary: Color {
        Color(.secondaryLabel)
    }
    
    static var textTertiary: Color {
        Color(.tertiaryLabel)
    }
    
    static var textQuaternary: Color {
        Color(.quaternaryLabel)
    }
    
    // MARK: - Border Colors
    /// Separator and border colors
    static var borderPrimary: Color {
        Color(.separator)
    }
    
    static var borderSecondary: Color {
        Color(.opaqueSeparator)
    }
    
    // MARK: - Component Colors
    /// Specific component colors
    static var buttonPrimary: Color {
        brandPrimary
    }
    
    static var buttonSecondary: Color {
        Color(.systemGray5)
    }
    
    static var buttonDestructive: Color {
        error
    }
    
    static var inputBackground: Color {
        surfaceSecondary
    }
    
    static var inputBorder: Color {
        borderPrimary
    }
    
    static var cardBackground: Color {
        surfaceSecondary
    }
    
    // MARK: - Status Colors with Opacity
    static var successLight: Color {
        success.opacity(0.1)
    }
    
    static var warningLight: Color {
        warning.opacity(0.1)
    }
    
    static var errorLight: Color {
        error.opacity(0.1)
    }
    
    static var infoLight: Color {
        info.opacity(0.1)
    }
}

// MARK: - Design System Modifiers
extension View {
    
    // MARK: - Card Styling
    func cardStyle() -> some View {
        self
            .background(Color.cardBackground)
            .cornerRadius(DesignSystem.CornerRadius.card)
            .shadow(
                color: Color.black.opacity(0.1),
                radius: DesignSystem.Shadow.card,
                x: 0,
                y: 2
            )
    }
    
    func compactCardStyle() -> some View {
        self
            .background(Color.cardBackground)
            .cornerRadius(DesignSystem.CornerRadius.md)
            .shadow(
                color: Color.black.opacity(0.05),
                radius: DesignSystem.Shadow.light,
                x: 0,
                y: 1
            )
    }
    
    // MARK: - Button Styling
    func primaryButtonStyle() -> some View {
        self
            .foregroundColor(.white)
            .padding(.horizontal, DesignSystem.Spacing.lg)
            .padding(.vertical, DesignSystem.Spacing.md)
            .background(Color.buttonPrimary)
            .cornerRadius(DesignSystem.CornerRadius.button)
            .shadow(
                color: Color.buttonPrimary.opacity(0.3),
                radius: DesignSystem.Shadow.button,
                x: 0,
                y: 2
            )
    }
    
    func secondaryButtonStyle() -> some View {
        self
            .foregroundColor(.textPrimary)
            .padding(.horizontal, DesignSystem.Spacing.lg)
            .padding(.vertical, DesignSystem.Spacing.md)
            .background(Color.buttonSecondary)
            .cornerRadius(DesignSystem.CornerRadius.button)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button)
                    .stroke(Color.borderPrimary, lineWidth: 1)
            )
    }
    
    // MARK: - Input Styling
    func inputFieldStyle() -> some View {
        self
            .padding(DesignSystem.Spacing.md)
            .background(Color.inputBackground)
            .cornerRadius(DesignSystem.CornerRadius.input)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.input)
                    .stroke(Color.inputBorder, lineWidth: 1)
            )
    }
    
    // MARK: - Animation Helpers
    func pressAnimation() -> some View {
        self
            .scaleEffect(1.0)
            .animation(DesignSystem.Animation.buttonPress, value: UUID())
    }
    
    func stateAnimation<V: Equatable>(_ value: V) -> some View {
        self
            .animation(DesignSystem.Animation.stateChange, value: value)
    }
    
    // MARK: - Responsive Layout
    func responsivePadding() -> some View {
        GeometryReader { geometry in
            let isCompact = geometry.size.width < DesignSystem.Layout.compactWidth
            self.padding(.horizontal, isCompact ? DesignSystem.Spacing.md : DesignSystem.Spacing.lg)
        }
    }
    
    func contentMaxWidth() -> some View {
        self
            .frame(maxWidth: DesignSystem.Layout.maxContentWidth)
    }
    
    // MARK: - Loading States
    func loadingOverlay<LoadingView: View>(
        isLoading: Bool,
        @ViewBuilder loadingView: () -> LoadingView
    ) -> some View {
        self
            .overlay(
                Group {
                    if isLoading {
                        loadingView()
                            .transition(.opacity)
                    }
                }
            )
            .animation(DesignSystem.Animation.stateChange, value: isLoading)
    }
}

// MARK: - Typography Modifiers
extension Text {
    func displayStyle() -> some View {
        self.font(DesignSystem.Typography.display)
            .foregroundColor(.textPrimary)
    }
    
    func headlineStyle() -> some View {
        self.font(DesignSystem.Typography.headline)
            .foregroundColor(.textPrimary)
    }
    
    func bodyStyle() -> some View {
        self.font(DesignSystem.Typography.body)
            .foregroundColor(.textPrimary)
    }
    
    func captionStyle() -> some View {
        self.font(DesignSystem.Typography.caption)
            .foregroundColor(.textSecondary)
    }
    
    func secondaryStyle() -> some View {
        self.foregroundColor(.textSecondary)
    }
    
    func tertiaryStyle() -> some View {
        self.foregroundColor(.textTertiary)
    }
}

// MARK: - Haptic Feedback
enum HapticFeedback {
    case light
    case medium
    case heavy
    case success
    case warning
    case error
    
    func trigger() {
        switch self {
        case .light:
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case .medium:
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        case .heavy:
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        case .success:
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        case .warning:
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
        case .error:
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
    }
}

// MARK: - Environment Extensions for Design System
extension EnvironmentValues {
    var designSystem: DesignSystem.Type {
        get { self[DesignSystemKey.self] }
        set { self[DesignSystemKey.self] = newValue }
    }
}

struct DesignSystemKey: EnvironmentKey {
    static let defaultValue: DesignSystem.Type = DesignSystem.self
}