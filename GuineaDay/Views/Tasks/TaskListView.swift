import SwiftUI
import SwiftData

struct TaskListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TaskItem.dueDate) private var tasks: [TaskItem]
    @State private var showingAddTask = false

    var pending:   [TaskItem] { tasks.filter { !$0.isCompleted } }
    var completed: [TaskItem] { tasks.filter {  $0.isCompleted } }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.wallGray.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Section: Pending
                        VStack(alignment: .leading, spacing: 12) {
                            ChiikawaSectionHeader(title: "To-Do (\(pending.count))", color: .usagiYellow, icon: "clock.fill")
                            if pending.isEmpty {
                                emptyState(icon: "checkmark.circle", message: "All done — great job! 🎉")
                            } else {
                                ForEach(pending) { task in
                                    TaskRow(task: task, onDelete: { deleteTask(task) })
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        // Section: Completed
                        if !completed.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                ChiikawaSectionHeader(title: "Done (\(completed.count))", color: .mintGreen, icon: "checkmark.circle.fill")
                                ForEach(completed) { task in
                                    TaskRow(task: task, onDelete: { deleteTask(task) })
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        Spacer().frame(height: 90) // tab bar clearance
                    }
                    .padding(.horizontal)
                    .padding(.top, 16)
                }
            }
            .navigationTitle("Duties")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingAddTask = true }) {
                        ZStack {
                            Circle().fill(Color.usagiYellow).frame(width: 34, height: 34)
                                .overlay(Circle().stroke(Color.inkBrown, lineWidth: 2))
                                .shadow(color: Color.inkBrown.opacity(0.4), radius: 0, x: 1, y: 2)
                            Image(systemName: "plus").fontWeight(.black).foregroundColor(.inkBrown)
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAddTask) { AddTaskView() }
        }
    }

    private func deleteTask(_ task: TaskItem) {
        withAnimation { modelContext.delete(task) }
    }

    @ViewBuilder
    func emptyState(icon: String, message: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon).font(.system(size: 40)).foregroundStyle(Color.inkBrown.opacity(0.3))
            Text(message).font(.system(size: 14, design: .rounded)).foregroundStyle(Color.inkBrown.opacity(0.5))
        }
        .frame(maxWidth: .infinity).padding(.vertical, 32)
        .chiikawaCard(color: .chiikawaWhite, radius: 20)
    }
}

// MARK: - Task Row
struct TaskRow: View {
    @Bindable var task: TaskItem
    let onDelete: () -> Void

    var stripeColor: Color {
        task.isCompleted ? .mintGreen :
        (task.priority.lowercased() == "high" ? .blushPink :
         task.priority.lowercased() == "medium" ? .usagiYellow : .hachiwareBlue)
    }

    var body: some View {
        HStack(spacing: 0) {
            // Colored left stripe
            Rectangle()
                .fill(stripeColor)
                .frame(width: 6)
                .clipShape(RoundedRectangle(cornerRadius: 3))
                .padding(.vertical, 2)

            HStack(spacing: 12) {
                // Completion toggle
                Button(action: {
                    withAnimation(.spring()) {
                        task.isCompleted.toggle()
                        task.completedAt = task.isCompleted ? Date() : nil
                    }
                }) {
                    Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(task.isCompleted ? Color.mintGreen : Color.inkBrown.opacity(0.4))
                }
                .buttonStyle(.plain)

                VStack(alignment: .leading, spacing: 3) {
                    Text(task.title)
                        .strikethrough(task.isCompleted, color: .inkBrown.opacity(0.5))
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(task.isCompleted ? Color.inkBrown.opacity(0.45) : Color.inkBrown)
                    HStack(spacing: 4) {
                        Text(task.dueDate, style: .date)
                        Text("·")
                        Text(task.category.capitalized)
                    }
                    .font(.system(size: 11, design: .rounded))
                    .foregroundStyle(Color.inkBrown.opacity(0.5))
                }

                Spacer()

                PriorityBadge(priority: task.priority)
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 13))
                        .foregroundColor(Color.blushPink)
                }
                .buttonStyle(.plain)
                .padding(.leading, 6)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
        }
        .background(Color.chiikawaWhite)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.inkBrown, lineWidth: 2.5))
        .shadow(color: Color.inkBrown.opacity(0.4), radius: 0, x: 2, y: 3)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

// MARK: - Priority Badge
struct PriorityBadge: View {
    let priority: String

    var color: Color {
        switch priority.lowercased() {
        case "high":   return .blushPink
        case "medium": return .usagiYellow
        default:       return .hachiwareBlue
        }
    }

    var body: some View {
        Text(priority.capitalized)
            .font(.system(size: 10, weight: .bold, design: .rounded))
            .foregroundColor(.inkBrown)
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(color)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Color.inkBrown, lineWidth: 1.5))
    }
}

#Preview {
    TaskListView().modelContainer(for: TaskItem.self, inMemory: true)
}
