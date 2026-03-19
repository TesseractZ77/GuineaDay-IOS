import SwiftUI
import SwiftData

struct AddTaskView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var firestore: FirestoreService
    
    @State private var title = ""
    @State private var dueDate = Date()
    @State private var category = "feeding"
    @State private var priority = "medium"
    
    let categories = ["feeding", "cleaning", "health", "play", "other"]
    let priorities = ["low", "medium", "high"]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.wallGray.ignoresSafeArea()
                
                Form {
                    Section(header: Text("Task Details").foregroundStyle(Color.inkBrown)) {
                        TextField("Title", text: $title)
                        DatePicker("Due Date", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                    }
                    .listRowBackground(Color.chiikawaWhite)
                    
                    Section(header: Text("Categorization").foregroundStyle(Color.inkBrown)) {
                        Picker("Category", selection: $category) {
                            ForEach(categories, id: \.self) {
                                Text($0.capitalized)
                            }
                        }
                        
                        Picker("Priority", selection: $priority) {
                            ForEach(priorities, id: \.self) {
                                Text($0.capitalized)
                            }
                        }
                    }
                    .listRowBackground(Color.chiikawaWhite)
                }
                .scrollContentBackground(.hidden)
                // Chiikawa touches inside Form:
                .tint(Color.inkBrown)
            }
            .navigationTitle("New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(Color.inkBrown)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveTask()
                    }
                    .foregroundStyle(Color.inkBrown)
                    .disabled(title.isEmpty)
                }
            }
        }
    }
    
    private func saveTask() {
        let newTask = TaskItem(
            title: title,
            dueDate: dueDate,
            category: category,
            priority: priority
        )
        modelContext.insert(newTask)
        Task { try? await firestore.addTask(newTask) }  // ← Firestore sync
        dismiss()
    }
}

#Preview {
    AddTaskView()
}
