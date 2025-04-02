import SwiftUI

struct ProgressBarView: View {
    @Binding var progress: Float
    @Environment(\.theme) var theme
    @Environment(\.managedObjectContext) private var context
    @State private var dailyTarget: Int = 100 // Default target
    @State private var isEditingTarget: Bool = false // Track if target is being edited
    @State private var editableTarget: String = "100" // For editing with keyboard
    
    // Custom dark green color for target marker
    private let darkGreenColor = Color(red: 0.05, green: 0.35, blue: 0.15) // Darker green shade for target
    
    init(progress: Binding<Float> = .constant(0)) {
        self._progress = progress
    }
    
    var body: some View {
        // Progress bar with increased spacing to avoid overlap
        VStack(spacing: 0) {
            // Add more spacer to push the bar down significantly
            Spacer().frame(height: 15)
            
            // Full-width rectangular progress bar with target indicator
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Calculate target position - use a safer position
                    let targetRatio = CGFloat(dailyTarget) / 150.0
                    let targetPosition = min(geometry.size.width * 0.75, geometry.size.width * targetRatio)
                    
                    // Background - full width rectangle with minimal rounding
                    Rectangle()
                        .fill(theme.progressBackground)
                        .cornerRadius(2)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                    
                    // Calculate if we're over target
                    let progressWidth = geometry.size.width * CGFloat(progress)
                    let isOverTarget = progressWidth > targetPosition
                    
                    Group {
                        // Progress fill up to target - gold color
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        theme.templateTab,
                                        theme.templateTab.opacity(0.85)
                                    ]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(2)
                            .frame(width: min(progressWidth, targetPosition), height: geometry.size.height)
                        
                        // Additional progress beyond target - data tab color
                        if isOverTarget {
                            Rectangle()
                                .fill(theme.dataTab)
                                .cornerRadius(2)
                                .frame(width: progressWidth - targetPosition, height: geometry.size.height)
                                .offset(x: targetPosition)
                        }
                    }
                    
                    // Target marker/indicator
                    ZStack {
                        // Target decoration
                        Rectangle()
                            .fill(darkGreenColor)
                            .frame(width: 3, height: geometry.size.height + 10)
                        
                        // Clickable target value badge
                        Button(action: {
                            // Initialize editable target with current value
                            editableTarget = "\(dailyTarget)"
                            isEditingTarget = true
                        }) {
                            ZStack {
                                // Background pill
                                Capsule()
                                    .fill(darkGreenColor)
                                    .frame(width: 48, height: 24)
                                    .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 1)
                                
                                // Target number
                                Text("\(dailyTarget)")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                        .buttonStyle(PlainButtonStyle()) // Remove button styling
                        .offset(y: -24) // Position higher above progress bar
                    }
                    .position(x: targetPosition, y: geometry.size.height / 2)
                }
            }
            .frame(height: 24) // Maintain taller progress bar
            
            // Add spacer after progress bar to avoid tabs overlap
            Spacer().frame(height: 10)
        }
        .padding(.horizontal, 0) // No horizontal padding - truly full width
        .onAppear {
            // Get daily target from CoreData
            loadDailyTarget()
        }
        // Present numeric keyboard when editing target
        .sheet(isPresented: $isEditingTarget) {
            // Numeric keyboard for editing target
            VStack {
                Text("Set Daily Target")
                    .font(.headline)
                    .padding()
                
                Text(editableTarget.isEmpty ? "0" : editableTarget)
                    .font(.system(size: 36, weight: .bold))
                    .padding()
                
                // Custom numeric keypad
                VStack(spacing: 10) {
                    // Number rows
                    ForEach(0..<3) { row in
                        HStack(spacing: 20) {
                            ForEach(1...3, id: \.self) { col in
                                let number = row * 3 + col
                                Button(action: {
                                    // Append digit
                                    editableTarget += "\(number)"
                                }) {
                                    Text("\(number)")
                                        .font(.system(size: 24, weight: .medium))
                                        .frame(width: 60, height: 60)
                                        .background(Color.gray.opacity(0.2))
                                        .cornerRadius(30)
                                }
                            }
                        }
                    }
                    
                    // Last row with 0, clear, done
                    HStack(spacing: 20) {
                        // Clear button
                        Button(action: {
                            editableTarget = ""
                        }) {
                            Image(systemName: "delete.left")
                                .font(.system(size: 24))
                                .frame(width: 60, height: 60)
                                .background(Color.red.opacity(0.2))
                                .cornerRadius(30)
                        }
                        
                        // 0 button
                        Button(action: {
                            editableTarget += "0"
                        }) {
                            Text("0")
                                .font(.system(size: 24, weight: .medium))
                                .frame(width: 60, height: 60)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(30)
                        }
                        
                        // Done button
                        Button(action: {
                            // Save the target and trigger recalculation of progress bar
                            if let newTarget = Int(editableTarget), newTarget > 0 {
                                // Using withAnimation to smoothly update the UI
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    dailyTarget = newTarget
                                    saveDailyTarget(newTarget)
                                    
                                    // Notify that target has changed
                                    NotificationCenter.default.post(
                                        name: Constants.Notifications.taskListChanged,
                                        object: nil
                                    )
                                }
                            }
                            isEditingTarget = false
                        }) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 24))
                                .frame(width: 60, height: 60)
                                .background(Color.green.opacity(0.2))
                                .cornerRadius(30)
                        }
                    }
                }
                .padding()
                
                Spacer()
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }
    
    // Load the daily target from CoreData
    private func loadDailyTarget() {
        // Default to 100 if not set
        dailyTarget = 100
        
        // In a real implementation, you would load this from CoreData
        // For now, we'll use the default value
    }
    
    // Save the daily target to CoreData
    private func saveDailyTarget(_ target: Int) {
        // In a real implementation, you would save this to CoreData
        // For now, we just update the state
        dailyTarget = target
    }
    
    // Update progress with optional animation
    func updateProgress(_ newProgress: Float, animated: Bool = true) {
        let clampedProgress = max(0, min(newProgress, 1.0))
        if animated {
            withAnimation(.easeInOut(duration: Constants.Animation.standard)) {
                progress = clampedProgress
            }
        } else {
            progress = clampedProgress
        }
    }
}

struct ProgressBarView_Previews: PreviewProvider {
    static var previews: some View {
        ProgressBarView(progress: .constant(0.7))
            .frame(width: 300, height: 20)
            .previewLayout(.sizeThatFits)
            .padding()
    }
}
