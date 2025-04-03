import SwiftUI
import CoreData

// MARK: - Theme System

/// Theme protocol defining all colors needed in the app
protocol AppTheme {
    // Background colors
    var backgroundPrimary: Color { get }
    var backgroundSecondary: Color { get }
    var backgroundElevated: Color { get }
    
    // Text colors
    var textPrimary: Color { get }
    var textSecondary: Color { get }
    var textTertiary: Color { get }
    var textInverted: Color { get }
    
    // Tab colors
    var routinesTab: Color { get }
    var tasksTab: Color { get }
    var templateTab: Color { get }
    var summaryTab: Color { get }
    var dataTab: Color { get }
    var criticalColor: Color { get } // New color for critical tasks
    
    // UI Element colors
    var progressBackground: Color { get }
    var progressLow: Color { get }
    var progressMedium: Color { get }
    var progressHigh: Color { get }
    var divider: Color { get }
    var shadow: Color { get }
    
    // Task states
    var taskBackgroundComplete: Color { get }
    var taskBackgroundPartial: Color { get }
    var taskBackgroundIncomplete: Color { get }
    var taskHighlight: Color { get }
}

/// Light theme implementation
struct LightTheme: AppTheme {
    // Background colors
    var backgroundPrimary = Color(UIColor.systemBackground)
    var backgroundSecondary = Color(UIColor.secondarySystemBackground)
    var backgroundElevated = Color.white
    
    // Text colors
    var textPrimary = Color(UIColor.label)
    var textSecondary = Color(UIColor.secondaryLabel)
    var textTertiary = Color(UIColor.tertiaryLabel)
    var textInverted = Color.white
    
    // Tab colors
    var routinesTab = Color("InversionGreen")
    var tasksTab = Color("InversionBlue")
    var templateTab = Color("lighterYellowInversion")
    var summaryTab = Color(red: 0.7, green: 0.6, blue: 0.5)
    var dataTab = Color(red: 0.8, green: 0.5, blue: 0.4)
    var criticalColor = Color(red: 0.85, green: 0.45, blue: 0.2) // Richer, more cohesive orange
    
    // UI Element colors
    var progressBackground = Color(UIColor.systemGray5)
    var progressLow = Color.yellow
    var progressMedium = Color(red: 0.5, green: 0.8, blue: 0.2)
    var progressHigh = Color.green
    var divider = Color(UIColor.separator)
    var shadow = Color.black.opacity(0.1)
    
    // Task states
    var taskBackgroundComplete = Color("InversionGreen").opacity(0.4)
    var taskBackgroundPartial = Color("InversionGreen").opacity(0.2)
    var taskBackgroundIncomplete = Color.clear
    var taskHighlight = Color("InversionGreen").opacity(0.5)
}

/// Dark theme implementation
struct DarkTheme: AppTheme {
    // Background colors
    var backgroundPrimary = Color(UIColor.systemBackground)
    var backgroundSecondary = Color(UIColor.secondarySystemBackground)
    var backgroundElevated = Color(UIColor.secondarySystemBackground)
    
    // Text colors
    var textPrimary = Color(UIColor.label)
    var textSecondary = Color(UIColor.secondaryLabel)
    var textTertiary = Color(UIColor.tertiaryLabel)
    var textInverted = Color.white
    
    // Tab colors
    var routinesTab = Color("InversionGreen")
    var tasksTab = Color("InversionBlue")
    var templateTab = Color("lighterYellowInversion")
    var summaryTab = Color(red: 0.4, green: 0.5, blue: 0.6)
    var dataTab = Color(red: 0.45, green: 0.6, blue: 0.7)
    var criticalColor = Color(red: 0.7, green: 0.35, blue: 0.15).opacity(0.95) // Darker orange for dark mode
    
    // UI Element colors
    var progressBackground = Color(UIColor.systemGray6)
    var progressLow = Color.yellow.opacity(0.9)
    var progressMedium = Color(red: 0.6, green: 0.9, blue: 0.3)
    var progressHigh = Color.green.opacity(0.9)
    var divider = Color(UIColor.separator)
    var shadow = Color.black.opacity(0.3)
    
    // Task states
    var taskBackgroundComplete = Color("InversionGreen").opacity(0.6)
    var taskBackgroundPartial = Color("InversionGreen").opacity(0.3)
    var taskBackgroundIncomplete = Color(UIColor.systemGray6).opacity(0.3)
    var taskHighlight = Color("InversionGreen").opacity(0.7)
}

/// Theme manager class to handle theme switching
class ThemeManager: ObservableObject {
    @Published var currentTheme: AppTheme
    @Published var colorScheme: ColorScheme?
    
    init(colorScheme: ColorScheme? = nil) {
        // Force check system dark mode directly through UIKit API
        let systemIsDark = UITraitCollection.current.userInterfaceStyle == .dark
        
        // Always initialize with system dark mode status
        self.currentTheme = systemIsDark ? DarkTheme() : LightTheme()
        
        // Store the passed color scheme for manual override
        self.colorScheme = colorScheme
    }
    
    /// Set theme based on color scheme
    func setTheme(_ colorScheme: ColorScheme?) {
        self.colorScheme = colorScheme
        if let colorScheme = colorScheme {
            withAnimation(.easeInOut(duration: 0.3)) {
                self.currentTheme = colorScheme == .dark ? DarkTheme() : LightTheme()
            }
        }
    }
    
    /// Toggle between light and dark mode
    func toggleTheme() {
        if colorScheme == .dark {
            setTheme(.light)
        } else {
            setTheme(.dark)
        }
    }
    
    /// Check if currently using dark mode
    var isDarkMode: Bool {
        return colorScheme == .dark
    }
    
    /// Follow system setting
    func useSystemTheme(_ currentSystemColorScheme: ColorScheme? = nil) {
        self.colorScheme = nil
        
        // If we have the current system scheme, update immediately
        if let systemScheme = currentSystemColorScheme {
            self.currentTheme = systemScheme == .dark ? DarkTheme() : LightTheme()
        }
    }
    
    /// Update theme based on system color scheme
    func updateForSystemColorScheme(_ systemColorScheme: ColorScheme) {
        // Only update if we're following system settings
        if self.colorScheme == nil {
            withAnimation(.easeInOut(duration: 0.3)) {
                self.currentTheme = systemColorScheme == .dark ? DarkTheme() : LightTheme()
            }
        }
    }
}

// MARK: - Environment Key for Theme

struct ThemeKey: EnvironmentKey {
    static let defaultValue: AppTheme = LightTheme()
}

extension EnvironmentValues {
    var theme: AppTheme {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
}

// MARK: - Helper Extensions for UI

// Style extension for common UI elements
extension View {
    // Apply standard button style for circular action buttons with dark mode support
    func circleButton(color: Color, size: CGFloat = 32) -> some View {
        self
            .font(.system(size: size * 0.5, weight: .bold))
            .foregroundColor(Color(.systemBackground))
            .frame(width: size, height: size)
            .background(Circle().fill(color))
            .contentShape(Circle())
    }
    
    // Theme-aware circle button
    func themeCircleButton(color: Color, textColor: Color? = nil, size: CGFloat = 32) -> some View {
        self
            .font(.system(size: size * 0.5, weight: .heavy)) // Increased weight for better readability
            .foregroundColor(textColor ?? Color(.systemBackground))
            .frame(width: size, height: size)
            .background(
                Circle()
                    .fill(color)
                    .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1) // Added subtle shadow
            )
            .contentShape(Circle())
    }
    
    // Apply common text styling with dark mode support
    func captionText() -> some View {
        self
            .font(.system(size: 12))
            .foregroundColor(.secondary)
    }
    
    // Theme-aware caption text
    func themeCaptionText(foregroundColor: Color) -> some View {
        self
            .font(.system(size: 12))
            .foregroundColor(foregroundColor)
    }
    
    // Apply common animation
    func standardAnimation() -> some View {
        self.animation(.easeInOut(duration: Constants.Animation.standard), value: UUID())
    }
}

// MARK: - CoreData Extensions

extension NSManagedObject {
    // Generate a stable ID string from an object
    var idString: String {
        self.objectID.uriRepresentation().absoluteString
    }
}

// MARK: - Notification Helpers

extension NotificationCenter {
    func postPointsUpdate(_ points: Int) {
        self.post(
            name: Constants.Notifications.updatePointsDisplay,
            object: nil,
            userInfo: ["points": points]
        )
    }
}

// MARK: - Date Formatting Helper

extension Date {
    // Format a date with common settings
    func formatted(style: DateFormatter.Style = .medium) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = style
        formatter.timeStyle = .none
        return formatter.string(from: self)
    }
    
    // Get start of day
    var startOfDay: Date {
        return Calendar.current.startOfDay(for: self)
    }
}