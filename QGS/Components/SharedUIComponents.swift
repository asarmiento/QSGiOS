import SwiftUI

// MARK: - Shared UI Components for All Targets
/// Reusable components that maintain consistency across QGS, FriendlyCheckInOut, and MCS

// MARK: - Unified Header Component
struct UnifiedHeaderView: View {
    let title: String
    let subtitle: String?
    var showBackButton: Bool = false
    var backAction: (() -> Void)?
    
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) var dismiss
    
    init(title: String, subtitle: String? = nil, showBackButton: Bool = false, backAction: (() -> Void)? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.showBackButton = showBackButton
        self.backAction = backAction
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                if showBackButton {
                    Button(action: {
                        if let backAction = backAction {
                            backAction()
                        } else {
                            dismiss()
                        }
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(themeManager.currentTheme.primaryColor)
                    }
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundColor(themeManager.currentTheme.secondaryColor)
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
        .background(themeManager.currentTheme.backgroundColor)
        .shadow(radius: themeManager.currentTheme.shadowStyle.light.radius, y: 1)
    }
}

// MARK: - Unified List Item Component
struct UnifiedListItemView: View {
    let icon: String?
    let title: String
    let subtitle: String?
    let value: String?
    let showChevron: Bool
    var action: (() -> Void)?
    
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        Button(action: {
            action?()
        }) {
            HStack(spacing: 12) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 22))
                        .foregroundColor(themeManager.currentTheme.primaryColor)
                        .frame(width: 32)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundColor(themeManager.currentTheme.secondaryColor)
                    }
                }
                
                Spacer()
                
                if let value = value {
                    Text(value)
                        .font(.body)
                        .foregroundColor(themeManager.currentTheme.secondaryColor)
                }
                
                if showChevron {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(.tertiaryLabel))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(themeManager.currentTheme.surfaceColor)
            .cornerRadius(themeManager.currentTheme.cornerRadius.medium)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Unified Status Badge
struct UnifiedStatusBadge: View {
    enum Status {
        case active, inactive, pending, error, success
        
        var color: Color {
            switch self {
            case .active, .success:
                return .green
            case .inactive:
                return .gray
            case .pending:
                return .orange
            case .error:
                return .red
            }
        }
        
        var text: String {
            switch self {
            case .active:
                return "Activo"
            case .inactive:
                return "Inactivo"
            case .pending:
                return "Pendiente"
            case .error:
                return "Error"
            case .success:
                return "Éxito"
            }
        }
    }
    
    let status: Status
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        Text(status.text)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(status.color)
            .cornerRadius(themeManager.currentTheme.cornerRadius.small)
    }
}

// MARK: - Unified Action Button
struct UnifiedActionButton: View {
    enum ButtonSize {
        case small, medium, large
        
        var padding: (horizontal: CGFloat, vertical: CGFloat) {
            switch self {
            case .small:
                return (12, 8)
            case .medium:
                return (20, 12)
            case .large:
                return (32, 16)
            }
        }
        
        var fontSize: Font {
            switch self {
            case .small:
                return .caption
            case .medium:
                return .body
            case .large:
                return .title3
            }
        }
    }
    
    let title: String
    let icon: String?
    let style: ThemedButtonStyle.ButtonType
    let size: ButtonSize
    let isLoading: Bool
    let action: () -> Void
    
    @EnvironmentObject var themeManager: ThemeManager
    
    init(
        title: String,
        icon: String? = nil,
        style: ThemedButtonStyle.ButtonType = .primary,
        size: ButtonSize = .medium,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.style = style
        self.size = size
        self.isLoading = isLoading
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(0.8)
                } else {
                    if let icon = icon {
                        Image(systemName: icon)
                            .font(size.fontSize)
                    }
                    Text(title)
                        .font(size.fontSize)
                        .fontWeight(.medium)
                }
            }
            .padding(.horizontal, size.padding.horizontal)
            .padding(.vertical, size.padding.vertical)
        }
        .disabled(isLoading)
        .themedButton(style: style)
    }
}

// MARK: - Unified Info Card
struct UnifiedInfoCard: View {
    let title: String
    let value: String
    let icon: String?
    let trend: Double?
    
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundColor(themeManager.currentTheme.primaryColor)
                }
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(themeManager.currentTheme.secondaryColor)
                
                Spacer()
                
                if let trend = trend {
                    HStack(spacing: 2) {
                        Image(systemName: trend > 0 ? "arrow.up.right" : "arrow.down.right")
                            .font(.caption)
                        Text("\(Int(abs(trend)))%")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(trend > 0 ? .green : .red)
                }
            }
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.primary)
        }
        .padding()
        .background(themeManager.currentTheme.surfaceColor)
        .cornerRadius(themeManager.currentTheme.cornerRadius.medium)
        .shadow(
            radius: themeManager.currentTheme.shadowStyle.light.radius,
            y: 1
        )
    }
}

// MARK: - Unified Tab Bar
struct UnifiedTabBar: View {
    @Binding var selectedTab: Int
    let tabs: [(icon: String, title: String)]
    
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<tabs.count, id: \.self) { index in
                Button(action: {
                    withAnimation(.easeInOut(duration: themeManager.currentTheme.animationStyle.quick)) {
                        selectedTab = index
                    }
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: tabs[index].icon)
                            .font(.system(size: 24))
                        
                        Text(tabs[index].title)
                            .font(.caption)
                    }
                    .foregroundColor(selectedTab == index ? themeManager.currentTheme.primaryColor : Color(.tertiaryLabel))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
            }
        }
        .background(themeManager.currentTheme.backgroundColor)
        .overlay(
            GeometryReader { geometry in
                Rectangle()
                    .fill(themeManager.currentTheme.primaryColor)
                    .frame(width: geometry.size.width / CGFloat(tabs.count), height: 2)
                    .offset(x: CGFloat(selectedTab) * (geometry.size.width / CGFloat(tabs.count)))
                    .animation(.easeInOut(duration: themeManager.currentTheme.animationStyle.standard), value: selectedTab)
            }
            .frame(height: 2),
            alignment: .top
        )
    }
}

// MARK: - Unified Search Bar
struct UnifiedSearchBar: View {
    @Binding var searchText: String
    var placeholder: String = "Buscar..."
    var onSearchSubmit: (() -> Void)?
    
    @EnvironmentObject var themeManager: ThemeManager
    @FocusState private var isFocused: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(themeManager.currentTheme.secondaryColor)
            
            TextField(placeholder, text: $searchText)
                .focused($isFocused)
                .onSubmit {
                    onSearchSubmit?()
                }
            
            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(themeManager.currentTheme.secondaryColor)
                }
            }
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(themeManager.currentTheme.cornerRadius.medium)
        .overlay(
            RoundedRectangle(cornerRadius: themeManager.currentTheme.cornerRadius.medium)
                .stroke(isFocused ? themeManager.currentTheme.primaryColor : Color.clear, lineWidth: 2)
        )
        .animation(.easeInOut(duration: themeManager.currentTheme.animationStyle.quick), value: isFocused)
    }
}

// MARK: - Unified Alert Dialog
struct UnifiedAlertDialog: View {
    let title: String
    let message: String
    let primaryButtonTitle: String
    let primaryButtonAction: () -> Void
    let secondaryButtonTitle: String?
    let secondaryButtonAction: (() -> Void)?
    
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 12) {
                Text(title)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(message)
                    .font(.body)
                    .foregroundColor(themeManager.currentTheme.secondaryColor)
                    .multilineTextAlignment(.center)
            }
            
            HStack(spacing: 12) {
                if let secondaryTitle = secondaryButtonTitle {
                    Button(action: {
                        secondaryButtonAction?()
                        dismiss()
                    }) {
                        Text(secondaryTitle)
                            .frame(maxWidth: .infinity)
                    }
                    .themedButton(style: .secondary)
                }
                
                Button(action: {
                    primaryButtonAction()
                    dismiss()
                }) {
                    Text(primaryButtonTitle)
                        .frame(maxWidth: .infinity)
                }
                .themedButton(style: .primary)
            }
        }
        .padding(24)
        .background(themeManager.currentTheme.backgroundColor)
        .cornerRadius(themeManager.currentTheme.cornerRadius.large)
        .shadow(radius: themeManager.currentTheme.shadowStyle.heavy.radius)
        .padding(.horizontal, 40)
    }
}

// MARK: - Unified Progress Indicator
struct UnifiedProgressIndicator: View {
    let progress: Double
    let title: String?
    let showPercentage: Bool
    
    @EnvironmentObject var themeManager: ThemeManager
    
    init(progress: Double, title: String? = nil, showPercentage: Bool = true) {
        self.progress = min(max(progress, 0), 1)
        self.title = title
        self.showPercentage = showPercentage
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let title = title {
                HStack {
                    Text(title)
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.secondaryColor)
                    
                    Spacer()
                    
                    if showPercentage {
                        Text("\(Int(progress * 100))%")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(themeManager.currentTheme.primaryColor)
                    }
                }
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .frame(height: 8)
                    
                    Rectangle()
                        .fill(themeManager.currentTheme.primaryColor)
                        .frame(width: geometry.size.width * progress, height: 8)
                        .animation(.easeInOut(duration: themeManager.currentTheme.animationStyle.standard), value: progress)
                }
                .cornerRadius(4)
            }
            .frame(height: 8)
        }
    }
}