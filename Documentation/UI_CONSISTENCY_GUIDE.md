# UI Consistency Guide for QGS Multi-Target Application

## Overview
This guide ensures consistent user experience across all three app targets:
- **QGS** (Main application)
- **FriendlyCheckInOut** (Alternate branding)
- **MCS** (Martinez Construction Services)

## Theme System Architecture

### 1. Unified Theme (`UnifiedTheme.swift`)
The central theme management system that provides:
- **ThemeProtocol**: Interface for all theme implementations
- **BaseTheme**: Default styling shared by all apps
- **QGSTheme**: Blue theme for QGS app
- **FriendlyTheme**: Green theme for FriendlyCheckInOut
- **MCSTheme**: Orange theme for MCS

### 2. Shared UI Components (`SharedUIComponents.swift`)
Reusable components that automatically adapt to the active theme:

#### Core Components:
- `UnifiedHeaderView`: Consistent navigation headers
- `UnifiedListItemView`: Standard list items with icons
- `UnifiedStatusBadge`: Status indicators
- `UnifiedActionButton`: Themed buttons with loading states
- `UnifiedInfoCard`: Information display cards
- `UnifiedTabBar`: Bottom navigation
- `UnifiedSearchBar`: Search input fields
- `UnifiedAlertDialog`: Modal alerts
- `UnifiedProgressIndicator`: Progress bars

#### Specialized Components:
- `ThemedLoadingView`: Loading states
- `ThemedEmptyStateView`: Empty/error states
- `WorkEntryCard`: Time entry displays
- `WeeklyTotalCard`: Weekly hour summaries

## Implementation Guidelines

### 1. Color Usage
```swift
// ✅ DO: Use theme colors
themeManager.currentTheme.primaryColor
themeManager.currentTheme.secondaryColor
themeManager.currentTheme.errorColor

// ❌ DON'T: Use hardcoded colors
Color.blue
Color.red
UIColor.systemBlue
```

### 2. Component Usage
```swift
// ✅ DO: Use unified components
UnifiedHeaderView(title: "Title", subtitle: "Subtitle")
UnifiedActionButton(title: "Save", style: .primary) { }

// ❌ DON'T: Create custom implementations
Text("Title").font(.title).foregroundColor(.blue)
Button("Save") { }.buttonStyle(.borderedProminent)
```

### 3. Theme Integration
```swift
// In your views, always inject the theme manager:
@StateObject private var themeManager = ThemeManager.shared

// Pass to child views:
.environmentObject(themeManager)
```

## Target-Specific Configuration

### Build Settings
Each target should define its build flag:
- QGS: `-D QGS_TARGET`
- FriendlyCheckInOut: `-D FRIENDLY_TARGET`  
- MCS: `-D MCS_TARGET`

### Asset Management
Each target maintains its own Assets.xcassets with:
- App icons specific to the brand
- Launch screens
- Brand-specific images

### Shared Resources
Place in the main QGS folder:
- Common icons (system SF Symbols preferred)
- Shared images used across all targets

## Best Practices

### 1. Consistency Checklist
- [ ] All text uses theme typography
- [ ] All colors come from theme
- [ ] Spacing follows theme standards
- [ ] Animations use theme timing
- [ ] Shadows use theme elevation
- [ ] Corner radius follows theme specs

### 2. Testing Across Targets
```bash
# Test each target's UI:
xcodebuild -scheme QGS -destination 'platform=iOS Simulator'
xcodebuild -scheme FriendlyCheckInOut -destination 'platform=iOS Simulator'
xcodebuild -scheme MCS -destination 'platform=iOS Simulator'
```

### 3. Adding New Components
1. Create in `SharedUIComponents.swift`
2. Use `ThemeProtocol` for styling
3. Test with all three themes
4. Document usage examples

### 4. Modifying Themes
1. Update in `UnifiedTheme.swift`
2. Test across all screens
3. Verify accessibility (contrast ratios)
4. Update this documentation

## Theme Properties Reference

```swift
protocol ThemeProtocol {
    // Core Colors
    var primaryColor: Color
    var secondaryColor: Color
    var accentColor: Color
    var backgroundColor: Color
    var surfaceColor: Color
    
    // Semantic Colors
    var errorColor: Color
    var successColor: Color
    var warningColor: Color
    
    // Typography
    var primaryFont: String
    var monospacedFont: String
    
    // Styling
    var cornerRadius: CornerRadiusStyle
    var shadowStyle: ShadowStyle
    var animationStyle: AnimationStyle
}
```

## Migration Guide

### Converting Existing Views
1. Replace hardcoded colors with theme colors
2. Replace custom components with unified components
3. Add theme manager as @StateObject
4. Pass theme via environmentObject
5. Test with all three themes

### Example Migration:
```swift
// Before:
Text("Title")
    .foregroundColor(.blue)
    .font(.title)

// After:
Text("Title")
    .foregroundColor(themeManager.currentTheme.primaryColor)
    .font(.title)
```

## Troubleshooting

### Common Issues:
1. **Colors not updating**: Ensure ThemeManager is properly injected
2. **Components look different**: Check if using unified components
3. **Build errors**: Verify target-specific build flags are set
4. **Missing assets**: Ensure assets are in correct target folder

## Maintenance

### Regular Tasks:
- Review new components for theme compliance
- Update shared components with new features
- Test theme changes across all targets
- Keep documentation updated with changes

### Code Review Checklist:
- [ ] Uses theme colors exclusively
- [ ] Follows spacing guidelines
- [ ] Uses unified components
- [ ] Tested on all three targets
- [ ] Accessibility verified

## Contact
For questions about UI consistency, contact the development team or refer to the design system documentation.