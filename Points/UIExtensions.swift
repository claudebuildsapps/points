import SwiftUI
import CoreData

// MARK: - Helper Extensions for UI

// Style extension for common UI elements
extension View {
    // Apply standard button style for circular action buttons
    func circleButton(color: Color, size: CGFloat = 32) -> some View {
        self
            .font(.system(size: size * 0.5, weight: .bold))
            .foregroundColor(.white)
            .frame(width: size, height: size)
            .background(Circle().fill(color))
    }
    
    // Apply common text styling
    func captionText() -> some View {
        self
            .font(.system(size: 12))
            .foregroundColor(.secondary)
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