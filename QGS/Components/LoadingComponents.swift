import SwiftUI

// MARK: - Advanced Loading Components
/// Sophisticated loading states and feedback mechanisms for better UX

// MARK: - Loading State Enum
// Using the LoadingState from Model/LoadingState.swift
// If you need the local version, rename it to ComponentLoadingState

// MARK: - Loading State View Container
struct LoadingStateView<Content: View>: View {
    let state: LoadingState
    let retryAction: (() -> Void)?
    let content: () -> Content
    
    init(
        state: LoadingState,
        retryAction: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.state = state
        self.retryAction = retryAction
        self.content = content
    }
    
    var body: some View {
        ZStack {
            content()
                .opacity(state == .idle ? 1.0 : 0.3)
                .disabled(state.isLoading)
            
            Group {
                switch state {
                case .idle:
                    EmptyView()
                case .loading:
                    LoadingView()
                case .success(let message):
                    SuccessView(message: message)
                case .failure(let message):
                    LoadingErrorView(message: message, retryAction: retryAction)
                }
            }
            .transition(.opacity.combined(with: .scale(scale: 0.9)))
        }
        .animation(DesignSystem.Animation.stateChange, value: state)
    }
}

// MARK: - Animated Loading View
struct LoadingView: View {
    @State private var isAnimating = false
    @State private var rotationAngle: Double = 0
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            ZStack {
                // Background circle
                Circle()
                    .stroke(Color.borderPrimary, lineWidth: 3)
                    .frame(width: 48, height: 48)
                
                // Animated arc
                Circle()
                    .trim(from: 0, to: 0.75)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.brandPrimary, Color.brandPrimary.opacity(0.3)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .frame(width: 48, height: 48)
                    .rotationEffect(.degrees(rotationAngle))
                    .animation(
                        .linear(duration: 1.0).repeatForever(autoreverses: false),
                        value: rotationAngle
                    )
                
                // Center dot
                Circle()
                    .fill(Color.brandPrimary)
                    .frame(width: 8, height: 8)
                    .scaleEffect(isAnimating ? 1.2 : 0.8)
                    .animation(
                        .easeInOut(duration: 0.6).repeatForever(autoreverses: true),
                        value: isAnimating
                    )
            }
            
            Text("Cargando...")
                .font(DesignSystem.Typography.bodyMedium)
                .foregroundColor(.textSecondary)
                .opacity(isAnimating ? 1.0 : 0.7)
                .animation(
                    .easeInOut(duration: 1.0).repeatForever(autoreverses: true),
                    value: isAnimating
                )
        }
        .padding(DesignSystem.Spacing.xl)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                .fill(Color(UIColor.secondarySystemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
        .onAppear {
            isAnimating = true
            rotationAngle = 360
        }
        .accessibilityLabel("Cargando contenido")
        .accessibilityAddTraits(.updatesFrequently)
    }
}

// MARK: - Success Feedback View
struct SuccessView: View {
    let message: String?
    @State private var isVisible = false
    @State private var checkmarkScale: CGFloat = 0
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            ZStack {
                Circle()
                    .fill(Color.success)
                    .frame(width: 60, height: 60)
                    .scaleEffect(isVisible ? 1.0 : 0.5)
                    .animation(DesignSystem.Animation.springNormal, value: isVisible)
                
                Image(systemName: "checkmark")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                    .scaleEffect(checkmarkScale)
                    .animation(
                        DesignSystem.Animation.springNormal.delay(0.2),
                        value: checkmarkScale
                    )
            }
            
            VStack(spacing: DesignSystem.Spacing.xs) {
                Text("¡Éxito!")
                    .font(DesignSystem.Typography.headline)
                    .foregroundColor(.textPrimary)
                
                if let message = message {
                    Text(message)
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)
                }
            }
            .opacity(isVisible ? 1.0 : 0)
            .animation(
                DesignSystem.Animation.easeOut.delay(0.3),
                value: isVisible
            )
        }
        .padding(DesignSystem.Spacing.xl)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                .fill(Color(UIColor.secondarySystemBackground))
                .shadow(color: Color.success.opacity(0.2), radius: 12, x: 0, y: 4)
        )
        .onAppear {
            isVisible = true
            checkmarkScale = 1.0
            
            // Trigger success haptic feedback
            HapticFeedback.success.trigger()
        }
        .accessibilityLabel("Operación completada exitosamente")
        .accessibilityHint(message ?? "")
    }
}

// MARK: - Error Feedback View
struct LoadingErrorView: View {
    let message: String
    let retryAction: (() -> Void)?
    @State private var isVisible = false
    @State private var shakeOffset: CGFloat = 0
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            VStack(spacing: DesignSystem.Spacing.md) {
                ZStack {
                    Circle()
                        .fill(Color.error)
                        .frame(width: 60, height: 60)
                        .scaleEffect(isVisible ? 1.0 : 0.5)
                        .animation(DesignSystem.Animation.springNormal, value: isVisible)
                    
                    Image(systemName: "exclamationmark")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                        .offset(x: shakeOffset)
                }
                
                VStack(spacing: DesignSystem.Spacing.xs) {
                    Text("¡Ups! Algo salió mal")
                        .font(DesignSystem.Typography.headline)
                        .foregroundColor(.textPrimary)
                    
                    Text(message)
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                }
                .opacity(isVisible ? 1.0 : 0)
                .animation(
                    DesignSystem.Animation.easeOut.delay(0.2),
                    value: isVisible
                )
            }
            
            if let retryAction = retryAction {
                Button(action: {
                    HapticFeedback.light.trigger()
                    retryAction()
                }) {
                    HStack(spacing: DesignSystem.Spacing.sm) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: DesignSystem.IconSize.buttonIcon, weight: .medium))
                        
                        Text("Reintentar")
                            .font(DesignSystem.Typography.buttonMedium)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                    .padding(.vertical, DesignSystem.Spacing.md)
                    .background(Color.error)
                    .cornerRadius(DesignSystem.CornerRadius.button)
                    .shadow(color: Color.error.opacity(0.3), radius: 4, x: 0, y: 2)
                }
                .scaleEffect(isVisible ? 1.0 : 0.8)
                .animation(
                    DesignSystem.Animation.springNormal.delay(0.4),
                    value: isVisible
                )
                .accessibilityLabel("Reintentar operación")
            }
        }
        .padding(DesignSystem.Spacing.xl)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                .fill(Color(UIColor.secondarySystemBackground))
                .shadow(color: Color.error.opacity(0.2), radius: 12, x: 0, y: 4)
        )
        .onAppear {
            isVisible = true
            
            // Shake animation
            withAnimation(.easeInOut(duration: 0.1).repeatCount(3, autoreverses: true)) {
                shakeOffset = 2
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                shakeOffset = 0
            }
            
            // Trigger error haptic feedback
            HapticFeedback.error.trigger()
        }
        .accessibilityLabel("Error: \(message)")
    }
}

// MARK: - Skeleton Loading Views
struct SkeletonView: View {
    @State private var isAnimating = false
    let cornerRadius: CGFloat
    
    init(cornerRadius: CGFloat = DesignSystem.CornerRadius.sm) {
        self.cornerRadius = cornerRadius
    }
    
    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(Color.borderPrimary.opacity(0.3))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.clear,
                                Color.white.opacity(0.6),
                                Color.clear
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .offset(x: isAnimating ? 100 : -100)
                    .animation(
                        .linear(duration: 1.5).repeatForever(autoreverses: false),
                        value: isAnimating
                    )
            )
            .clipped()
            .onAppear {
                isAnimating = true
            }
            .accessibilityLabel("Cargando contenido")
            .accessibilityAddTraits(.updatesFrequently)
    }
}

struct SkeletonCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            HStack(spacing: DesignSystem.Spacing.md) {
                SkeletonView()
                    .frame(width: 50, height: 50)
                    .cornerRadius(DesignSystem.CornerRadius.round)
                
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    SkeletonView()
                        .frame(height: 16)
                        .frame(maxWidth: .infinity)
                    
                    SkeletonView()
                        .frame(height: 12)
                        .frame(maxWidth: 120)
                }
            }
            
            SkeletonView()
                .frame(height: 10)
                .frame(maxWidth: .infinity)
            
            SkeletonView()
                .frame(height: 10)
                .frame(maxWidth: 200)
        }
        .padding(DesignSystem.Spacing.cardPadding)
        .cardStyle()
    }
}

struct SkeletonList: View {
    let itemCount: Int
    
    init(itemCount: Int = 5) {
        self.itemCount = itemCount
    }
    
    var body: some View {
        LazyVStack(spacing: DesignSystem.Spacing.md) {
            ForEach(0..<itemCount, id: \.self) { _ in
                SkeletonCard()
            }
        }
        .padding(DesignSystem.Spacing.md)
    }
}

// MARK: - Pull to Refresh Loading
struct PullToRefreshView: View {
    @Binding var isRefreshing: Bool
    let onRefresh: () -> Void
    
    @State private var offset: CGFloat = 0
    @State private var rotation: Double = 0
    
    private let threshold: CGFloat = 80
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            if isRefreshing {
                HStack(spacing: DesignSystem.Spacing.sm) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: DesignSystem.IconSize.md, weight: .medium))
                        .foregroundColor(.brandPrimary)
                        .rotationEffect(.degrees(rotation))
                        .animation(
                            .linear(duration: 1.0).repeatForever(autoreverses: false),
                            value: rotation
                        )
                    
                    Text("Actualizando...")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(.textSecondary)
                }
                .onAppear {
                    rotation = 360
                }
                .transition(.opacity.combined(with: .scale))
            } else if offset > 20 {
                VStack(spacing: DesignSystem.Spacing.xs) {
                    Image(systemName: "arrow.down")
                        .font(.system(size: DesignSystem.IconSize.md, weight: .medium))
                        .foregroundColor(.brandPrimary)
                        .scaleEffect(min(offset / threshold, 1.0))
                        .rotationEffect(.degrees(offset > threshold ? 180 : 0))
                        .animation(DesignSystem.Animation.springFast, value: offset)
                    
                    Text(offset > threshold ? "Suelta para actualizar" : "Desliza para actualizar")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(.textSecondary)
                }
                .transition(.opacity)
            }
        }
        .frame(height: max(0, offset))
        .clipped()
    }
}

// MARK: - Progress Indicators
struct ProgressBar: View {
    let progress: Double // 0.0 to 1.0
    let showPercentage: Bool
    let color: Color
    
    init(
        progress: Double,
        showPercentage: Bool = false,
        color: Color = .brandPrimary
    ) {
        self.progress = progress
        self.showPercentage = showPercentage
        self.color = color
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            if showPercentage {
                HStack {
                    Text("Progreso")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(.textSecondary)
                    
                    Spacer()
                    
                    Text("\(Int(progress * 100))%")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(.textPrimary)
                        .fontWeight(.medium)
                }
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xs)
                        .fill(Color.borderPrimary.opacity(0.3))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xs)
                        .fill(color)
                        .frame(width: max(0, geometry.size.width * CGFloat(progress)), height: 8)
                        .animation(DesignSystem.Animation.springNormal, value: progress)
                }
            }
            .frame(height: 8)
        }
        .accessibilityLabel("Progreso: \(Int(progress * 100)) por ciento")
        .accessibilityAddTraits(.updatesFrequently)
    }
}

// MARK: - Empty State View
struct EmptyStateView: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let actionTitle: String?
    let action: (() -> Void)?
    
    @State private var isVisible = false
    
    init(
        title: String,
        subtitle: String,
        systemImage: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.actionTitle = actionTitle
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.xl) {
            VStack(spacing: DesignSystem.Spacing.lg) {
                Image(systemName: systemImage)
                    .font(.system(size: 64, weight: .light))
                    .foregroundColor(.textTertiary)
                    .scaleEffect(isVisible ? 1.0 : 0.8)
                    .animation(DesignSystem.Animation.springNormal.delay(0.1), value: isVisible)
                
                VStack(spacing: DesignSystem.Spacing.sm) {
                    Text(title)
                        .font(DesignSystem.Typography.title)
                        .fontWeight(.semibold)
                        .foregroundColor(.textPrimary)
                        .multilineTextAlignment(.center)
                    
                    Text(subtitle)
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                }
                .opacity(isVisible ? 1.0 : 0)
                .animation(DesignSystem.Animation.easeOut.delay(0.3), value: isVisible)
            }
            
            if let actionTitle = actionTitle, let action = action {
                Button(action: {
                    HapticFeedback.light.trigger()
                    action()
                }) {
                    HStack(spacing: DesignSystem.Spacing.sm) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: DesignSystem.IconSize.buttonIcon, weight: .medium))
                        
                        Text(actionTitle)
                            .font(DesignSystem.Typography.buttonMedium)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                    .padding(.vertical, DesignSystem.Spacing.md)
                    .background(Color.brandPrimary)
                    .cornerRadius(DesignSystem.CornerRadius.button)
                    .shadow(color: Color.brandPrimary.opacity(0.3), radius: 4, x: 0, y: 2)
                }
                .scaleEffect(isVisible ? 1.0 : 0.8)
                .animation(DesignSystem.Animation.springNormal.delay(0.5), value: isVisible)
                .accessibilityLabel(actionTitle)
            }
        }
        .padding(DesignSystem.Spacing.xl)
        .onAppear {
            isVisible = true
        }
    }
}

// MARK: - Card Component
struct Card<Content: View>: View {
    let content: () -> Content
    let padding: CGFloat
    let cornerRadius: CGFloat
    let shadowRadius: CGFloat
    
    init(
        padding: CGFloat = DesignSystem.Spacing.lg,
        cornerRadius: CGFloat = DesignSystem.CornerRadius.lg,
        shadowRadius: CGFloat = 8,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.content = content
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.shadowRadius = shadowRadius
    }
    
    var body: some View {
        content()
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color(UIColor.secondarySystemBackground))
                    .shadow(
                        color: Color.gray.opacity(0.1),
                        radius: shadowRadius,
                        x: 0,
                        y: 2
                    )
            )
    }
}