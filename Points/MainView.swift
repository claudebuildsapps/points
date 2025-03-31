import SwiftUI
import CoreData

struct MainView: View {
    @Environment(\.managedObjectContext) private var context
    @State private var selectedTab = 0
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Main content (fills entire screen except for tab bar)
            VStack(spacing: 0) {
                if selectedTab == 0 {
                    TaskNavigationView()
                        .environment(\.managedObjectContext, context)
                } else if selectedTab == 1 {
                    Text("Stats Coming Soon")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                } else {
                    Text("Settings Coming Soon")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                }
                
                Spacer(minLength: 60) // Space for tab bar
            }
            
            // Tab bar at the bottom
            VStack(spacing: 0) {
                Spacer()
                TabBarView(onTabSelected: { index in
                    selectedTab = index
                })
                .frame(height: 60)
            }
            .ignoresSafeArea(edges: .bottom)
        }
    }
}

struct TaskNavigationView: View {
    @Environment(\.managedObjectContext) private var context
    @State private var currentDate = Calendar.current.startOfDay(for: Date())
    @State private var currentDateEntity: CoreDataDate?
    @State private var progress: Float = 0
    
    // Initialize dateHelper using the environment context
    private var dateHelper: DateHelper {
        DateHelper(context: context)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Date navigation at the top
            DateNavigationView(onDateChange: { dateEntity in
                self.currentDateEntity = dateEntity
                if let dateValue = dateEntity.date {
                    self.currentDate = dateValue
                    
                    // Update points display when date changes
                    if let points = dateEntity.points as? NSDecimalNumber {
                        NotificationCenter.default.post(
                            name: Constants.Notifications.updatePointsDisplay,
                            object: nil,
                            userInfo: ["points": points.intValue]
                        )
                    }
                }
            })
            .environment(\.managedObjectContext, context)
            .frame(height: 50)
            
            // Progress bar
            ProgressBarView(progress: $progress)
                .frame(height: 18)
                .padding(.vertical, 5)
            
            // Task list
            if let dateEntity = currentDateEntity {
                TaskListWithControls(
                    currentDateEntity: dateEntity,
                    onProgressUpdated: { newProgress in
                        // Update the progress binding with animation
                        withAnimation(.easeInOut(duration: Constants.Animation.standard)) {
                            self.progress = newProgress
                        }
                    }
                )
                .environment(\.managedObjectContext, context)
                // Add an ID to force complete redraw when date entity changes
                .id("taskList-\(dateEntity.objectID.uriRepresentation().absoluteString)")
            } else {
                Text("Loading...")
                    .font(.title)
                    .foregroundColor(.secondary)
            }
        }
        .onAppear {
            initializeForToday()
        }
    }
    
    private func initializeForToday() {
        if let dateEntity = dateHelper.getTodayEntity() {
            self.currentDateEntity = dateEntity
            self.currentDate = dateEntity.date ?? Date()
            
            // Ensure we have tasks for today
            dateHelper.ensureTasksExist(for: dateEntity)
            
            // Update points display
            if let points = dateEntity.points as? NSDecimalNumber {
                NotificationCenter.default.post(
                    name: Constants.Notifications.updatePointsDisplay,
                    object: nil,
                    userInfo: ["points": points.intValue]
                )
            }
        }
    }
}