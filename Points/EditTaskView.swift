import SwiftUI
import CoreData

struct EditTaskView: View {
    @ObservedObject var task: CoreDataTask
    @Binding var isExpanded: Bool
    @Binding var isEditMode: Bool
    
    // Callbacks
    var onSave: ([String: Any]) -> Void
    var onCancel: () -> Void
    var onDelete: (() -> Void)?
    var onCopyToTemplate: (() -> Void)?
    
    var body: some View {
        // Use our common TaskFormView in edit mode
        TaskFormView(
            mode: .edit,
            task: task,
            isPresented: $isExpanded,
            onSave: onSave,
            onCancel: onCancel,
            onDelete: onDelete,
            onCopyToTemplate: onCopyToTemplate
        )
    }
}