import SwiftUI
import UIKit

// MARK: - Accessibility System for QGS
/// Comprehensive accessibility support for better inclusion and VoiceOver experience

// MARK: - Accessibility Configuration
struct AccessibilityConfig {
    static let shared = AccessibilityConfig()
    
    let isVoiceOverEnabled: Bool
    let isReduceMotionEnabled: Bool
    let isHighContrastEnabled: Bool
    let preferredContentSizeCategory: ContentSizeCategory
    
    private init() {
        self.isVoiceOverEnabled = UIAccessibility.isVoiceOverRunning
        self.isReduceMotionEnabled = UIAccessibility.isReduceMotionEnabled
        self.isHighContrastEnabled = UIAccessibility.isDarkerSystemColorsEnabled
        
        // Convert UIContentSizeCategory to SwiftUI ContentSizeCategory
        switch UIApplication.shared.preferredContentSizeCategory {
        case .extraSmall:
            self.preferredContentSizeCategory = .extraSmall
        case .small:
            self.preferredContentSizeCategory = .small
        case .medium:
            self.preferredContentSizeCategory = .medium
        case .large:
            self.preferredContentSizeCategory = .large
        case .extraLarge:
            self.preferredContentSizeCategory = .extraLarge
        case .extraExtraLarge:
            self.preferredContentSizeCategory = .extraExtraLarge
        case .extraExtraExtraLarge:
            self.preferredContentSizeCategory = .extraExtraExtraLarge
        case .accessibilityMedium:
            self.preferredContentSizeCategory = .accessibilityMedium
        case .accessibilityLarge:
            self.preferredContentSizeCategory = .accessibilityLarge
        case .accessibilityExtraLarge:
            self.preferredContentSizeCategory = .accessibilityExtraLarge
        case .accessibilityExtraExtraLarge:
            self.preferredContentSizeCategory = .accessibilityExtraExtraLarge
        case .accessibilityExtraExtraExtraLarge:
            self.preferredContentSizeCategory = .accessibilityExtraExtraExtraLarge
        default:
            self.preferredContentSizeCategory = .large
        }
    }
}

// MARK: - Accessibility Traits
enum AccessibilityTraits {
    case button
    case textField
    case header
    case status
    case summary
    case navigation
    case tab
    case image
    case link
    case searchField
    case keyboardKey
    case adjustable
    
    var systemTraits: SwiftUI.AccessibilityTraits {
        switch self {
        case .button:
            return .isButton
        case .textField:
            return .isKeyboardKey
        case .header:
            return .isHeader
        case .status:
            return .updatesFrequently
        case .summary:
            return .isSummaryElement
        case .navigation:
            return .allowsDirectInteraction
        case .tab:
            return .isSelected
        case .image:
            return .isImage
        case .link:
            return .isLink
        case .searchField:
            return .isSearchField
        case .keyboardKey:
            return .isKeyboardKey
        case .adjustable:
            return .allowsDirectInteraction
        }
    }
}

// MARK: - View Extensions for Accessibility
extension View {
    
    // MARK: - Basic Accessibility
    @ViewBuilder
    func accessibilitySetup(
        label: String,
        hint: String? = nil,
        value: String? = nil,
        traits: AccessibilityTraits? = nil,
        hidden: Bool = false
    ) -> some View {
        let baseView = self
            .accessibilityLabel(label)
            .accessibilityHidden(hidden)

        if let hint = hint, let value = value, let traits = traits {
            baseView
                .accessibilityHint(hint)
                .accessibilityValue(value)
                .accessibilityAddTraits(traits.systemTraits)
        } else if let hint = hint, let value = value {
            baseView
                .accessibilityHint(hint)
                .accessibilityValue(value)
        } else if let hint = hint, let traits = traits {
            baseView
                .accessibilityHint(hint)
                .accessibilityAddTraits(traits.systemTraits)
        } else if let value = value, let traits = traits {
            baseView
                .accessibilityValue(value)
                .accessibilityAddTraits(traits.systemTraits)
        } else if let hint = hint {
            baseView.accessibilityHint(hint)
        } else if let value = value {
            baseView.accessibilityValue(value)
        } else if let traits = traits {
            baseView.accessibilityAddTraits(traits.systemTraits)
        } else {
            baseView
        }
    }
    
    // MARK: - Interactive Elements
    func accessibilityButton(
        label: String,
        hint: String? = nil,
        value: String? = nil
    ) -> some View {
        self.accessibilitySetup(
            label: label,
            hint: hint ?? "Toca dos veces para activar",
            value: value,
            traits: .button
        )
    }
    
    func accessibilityTextField(
        label: String,
        hint: String? = nil,
        value: String? = nil
    ) -> some View {
        self.accessibilitySetup(
            label: label,
            hint: hint ?? "Campo de texto editable",
            value: value,
            traits: .textField
        )
    }
    
    func accessibilityHeader(
        label: String,
        level: Int = 1
    ) -> some View {
        self.accessibilitySetup(
            label: label,
            traits: .header
        )
        .accessibilityHeading(.h1) // Could be parameterized based on level
    }
    
    // MARK: - Status and Information
    func accessibilityStatus(
        label: String,
        value: String? = nil
    ) -> some View {
        self.accessibilitySetup(
            label: label,
            value: value,
            traits: .status
        )
    }
    
    @ViewBuilder
    func accessibilityLoadingState(
        isLoading: Bool,
        loadingLabel: String = "Cargando",
        completedLabel: String = "Carga completada"
    ) -> some View {
        if isLoading {
            self
                .accessibilityLabel(loadingLabel)
                .accessibilityAddTraits(.updatesFrequently)
        } else {
            self
                .accessibilityLabel(completedLabel)
        }
    }
    
    // MARK: - Navigation and Lists
    func accessibilityListItem(
        label: String,
        hint: String? = nil,
        position: (Int, Int)? = nil
    ) -> some View {
        var accessibilityLabel = label
        
        if let position = position {
            accessibilityLabel += ". Elemento \(position.0) de \(position.1)"
        }
        
        return self.accessibilitySetup(
            label: accessibilityLabel,
            hint: hint ?? "Toca dos veces para seleccionar",
            traits: .button
        )
    }
    
    func accessibilityTabItem(
        label: String,
        isSelected: Bool,
        position: (Int, Int)? = nil
    ) -> some View {
        var accessibilityLabel = label
        
        if isSelected {
            accessibilityLabel += ", seleccionado"
        }
        
        if let position = position {
            accessibilityLabel += ". Pestaña \(position.0) de \(position.1)"
        }
        
        return self.accessibilitySetup(
            label: accessibilityLabel,
            hint: isSelected ? "Pestaña actual" : "Toca dos veces para cambiar de pestaña",
            traits: .tab
        )
    }
    
    // MARK: - Form Elements
    func accessibilityFormField(
        label: String,
        value: String,
        isRequired: Bool = false,
        isValid: Bool = true,
        errorMessage: String? = nil
    ) -> some View {
        var accessibilityLabel = label
        
        if isRequired {
            accessibilityLabel += ", requerido"
        }
        
        if !isValid, let errorMessage = errorMessage {
            accessibilityLabel += ", error: \(errorMessage)"
        }
        
        return self.accessibilitySetup(
            label: accessibilityLabel,
            hint: "Campo de texto editable",
            value: value.isEmpty ? "vacío" : value,
            traits: .textField
        )
    }
    
    // MARK: - Time and Records
    func accessibilityTimeRecord(
        type: String,
        time: String,
        project: String,
        location: String? = nil
    ) -> some View {
        let typeText = type == "e" ? "Entrada" : "Salida"
        var label = "\(typeText) registrada a las \(time) en proyecto \(project)"
        
        if let location = location {
            label += ", ubicación: \(location)"
        }
        
        return self.accessibilitySetup(
            label: label,
            hint: "Toca dos veces para ver detalles",
            traits: .button
        )
    }
    
    func accessibilityRecordButton(
        type: String,
        isEnabled: Bool,
        location: String? = nil
    ) -> some View {
        let typeText = type == "e" ? "Entrada" : "Salida"
        var label = "Registrar \(typeText.lowercased())"
        
        if !isEnabled {
            label += ", no disponible"
        }
        
        if let location = location {
            label += ", ubicación actual: \(location)"
        }
        
        return self.accessibilitySetup(
            label: label,
            hint: isEnabled ? "Toca dos veces para registrar" : "No disponible en este momento",
            traits: .button
        )
    }
    
    // MARK: - Progress and Status
    func accessibilityProgress(
        value: Double,
        total: Double,
        description: String
    ) -> some View {
        let percentage = Int((value / total) * 100)
        
        return self.accessibilitySetup(
            label: "\(description), \(percentage) por ciento completado",
            value: "\(percentage)%",
            traits: .adjustable
        )
    }
    
    // MARK: - Reduce Motion Support
    func accessibilityReduceMotion<T: Equatable>(
        _ value: T,
        normalAnimation: Animation = DesignSystem.Animation.springNormal,
        reducedAnimation: Animation = .easeInOut(duration: 0.1)
    ) -> some View {
        let animation = AccessibilityConfig.shared.isReduceMotionEnabled ? reducedAnimation : normalAnimation
        return self.animation(animation, value: value)
    }
    
    // MARK: - High Contrast Support
    func accessibilityHighContrast(
        normalColor: Color,
        highContrastColor: Color
    ) -> some View {
        let color = AccessibilityConfig.shared.isHighContrastEnabled ? highContrastColor : normalColor
        return self.foregroundColor(color)
    }
}

// MARK: - Accessible Custom Components

// MARK: - Accessible Custom Text Field
struct AccessibleCustomTextField: View {
    let label: String
    let hint: String
    let systemImage: String?
    let isSecure: Bool
    let isRequired: Bool
    @Binding var text: String
    @State private var isEditing = false
    @State private var showSecureText = false
    
    // Validation
    let validator: ((String) -> Bool)?
    let errorMessage: String?
    
    init(
        label: String,
        hint: String,
        systemImage: String? = nil,
        isSecure: Bool = false,
        isRequired: Bool = false,
        text: Binding<String>,
        validator: ((String) -> Bool)? = nil,
        errorMessage: String? = nil
    ) {
        self.label = label
        self.hint = hint
        self.systemImage = systemImage
        self.isSecure = isSecure
        self.isRequired = isRequired
        self._text = text
        self.validator = validator
        self.errorMessage = errorMessage
    }
    
    private var isValid: Bool {
        guard let validator = validator else { return true }
        return validator(text)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            // Label
            Text(label + (isRequired ? " *" : ""))
                .font(DesignSystem.Typography.caption)
                .foregroundColor(.textSecondary)
                .accessibilityHidden(true) // Hidden because it's included in the field label
            
            // Input Field
            HStack(spacing: DesignSystem.Spacing.sm) {
                if let systemImage = systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: DesignSystem.IconSize.md))
                        .foregroundColor(isEditing ? .brandPrimary : .textTertiary)
                        .frame(width: 20)
                        .accessibilityHidden(true)
                }
                
                Group {
                    if isSecure && !showSecureText {
                        SecureField(hint, text: $text)
                    } else {
                        TextField(hint, text: $text)
                    }
                }
                .textFieldStyle(PlainTextFieldStyle())
                .onFocus { focused in
                    isEditing = focused
                }
                .accessibilityFormField(
                    label: label,
                    value: text,
                    isRequired: isRequired,
                    isValid: isValid,
                    errorMessage: isValid ? nil : errorMessage
                )
                
                if isSecure {
                    Button(action: {
                        showSecureText.toggle()
                        HapticFeedback.light.trigger()
                    }) {
                        Image(systemName: showSecureText ? "eye.slash" : "eye")
                            .font(.system(size: DesignSystem.IconSize.md))
                            .foregroundColor(.textTertiary)
                    }
                    .accessibilityButton(
                        label: showSecureText ? "Ocultar contraseña" : "Mostrar contraseña"
                    )
                }
            }
            .padding(DesignSystem.Spacing.md)
            .background(Color.inputBackground)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.input)
                    .stroke(
                        isEditing ? Color.brandPrimary : 
                        (!isValid ? Color.error : Color.inputBorder),
                        lineWidth: isEditing ? 2 : 1
                    )
            )
            .cornerRadius(DesignSystem.CornerRadius.input)
            
            // Error Message
            if !isValid, let errorMessage = errorMessage {
                Label {
                    Text(errorMessage)
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(.error)
                } icon: {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.error)
                }
                .accessibilityStatus(label: "Error: \(errorMessage)")
            }
        }
    }
}

// MARK: - Accessible Button Component
struct AccessibleButton: View {
    let title: String
    let subtitle: String?
    let systemImage: String?
    let style: ButtonStyle
    let isEnabled: Bool
    let isLoading: Bool
    let action: () -> Void
    
    @State private var isPressed = false
    
    enum ButtonStyle {
        case primary, secondary, destructive, ghost
        
        var backgroundColor: Color {
            switch self {
            case .primary: return .buttonPrimary
            case .secondary: return .buttonSecondary
            case .destructive: return .buttonDestructive
            case .ghost: return .clear
            }
        }
        
        var foregroundColor: Color {
            switch self {
            case .primary, .destructive: return .white
            case .secondary, .ghost: return .textPrimary
            }
        }
        
        var accessibilityRole: String {
            switch self {
            case .destructive: return "botón destructivo"
            default: return "botón"
            }
        }
    }
    
    init(
        title: String,
        subtitle: String? = nil,
        systemImage: String? = nil,
        style: ButtonStyle = .primary,
        isEnabled: Bool = true,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.style = style
        self.isEnabled = isEnabled
        self.isLoading = isLoading
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            guard isEnabled && !isLoading else { return }
            
            withAnimation(DesignSystem.Animation.buttonPress) {
                isPressed = true
            }
            
            HapticFeedback.light.trigger()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(DesignSystem.Animation.buttonPress) {
                    isPressed = false
                }
                action()
            }
        }) {
            HStack(spacing: DesignSystem.Spacing.sm) {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .progressViewStyle(CircularProgressViewStyle(tint: style.foregroundColor))
                } else if let systemImage = systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: DesignSystem.IconSize.buttonIcon, weight: .medium))
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(DesignSystem.Typography.buttonMedium)
                        .fontWeight(.medium)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(DesignSystem.Typography.caption)
                            .opacity(0.8)
                    }
                }
            }
            .foregroundColor(style.foregroundColor)
            .padding(.horizontal, DesignSystem.Spacing.lg)
            .padding(.vertical, DesignSystem.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button)
                    .fill(style.backgroundColor)
                    .shadow(
                        color: isEnabled ? style.backgroundColor.opacity(0.3) : Color.clear,
                        radius: isPressed ? 2 : 4,
                        x: 0,
                        y: isPressed ? 1 : 2
                    )
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .opacity(isEnabled ? 1.0 : 0.6)
        }
        .disabled(!isEnabled || isLoading)
        .buttonStyle(PlainButtonStyle())
        .accessibilityButton(
            label: buildAccessibilityLabel(),
            hint: buildAccessibilityHint()
        )
        .accessibilityReduceMotion(isPressed)
    }
    
    private func buildAccessibilityLabel() -> String {
        var label = "\(style.accessibilityRole), \(title)"
        
        if let subtitle = subtitle {
            label += ", \(subtitle)"
        }
        
        if isLoading {
            label += ", cargando"
        } else if !isEnabled {
            label += ", no disponible"
        }
        
        return label
    }
    
    private func buildAccessibilityHint() -> String {
        if isLoading {
            return "Procesando solicitud"
        } else if !isEnabled {
            return "No disponible en este momento"
        } else {
            return "Toca dos veces para activar"
        }
    }
}

// MARK: - Focus State Extension
extension View {
    func onFocus(perform action: @escaping (Bool) -> Void) -> some View {
        self.onReceive(NotificationCenter.default.publisher(for: UITextField.textDidBeginEditingNotification)) { _ in
            action(true)
        }
        .onReceive(NotificationCenter.default.publisher(for: UITextField.textDidEndEditingNotification)) { _ in
            action(false)
        }
    }
}

// MARK: - VoiceOver Announcements
struct VoiceOverAnnouncement {
    static func announce(_ message: String) {
        guard AccessibilityConfig.shared.isVoiceOverEnabled else { return }
        
        DispatchQueue.main.async {
            UIAccessibility.post(notification: .announcement, argument: message)
        }
    }
    
    static func announceScreenChange(to element: Any? = nil) {
        guard AccessibilityConfig.shared.isVoiceOverEnabled else { return }
        
        DispatchQueue.main.async {
            UIAccessibility.post(notification: .screenChanged, argument: element)
        }
    }
    
    static func announceLayoutChange(to element: Any? = nil) {
        guard AccessibilityConfig.shared.isVoiceOverEnabled else { return }
        
        DispatchQueue.main.async {
            UIAccessibility.post(notification: .layoutChanged, argument: element)
        }
    }
}