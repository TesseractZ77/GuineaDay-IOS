import SwiftUI
import SwiftData

struct TaskListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TaskItem.dueDate) private var tasks: [TaskItem]
    @EnvironmentObject var firestore: FirestoreService
    @EnvironmentObject var lang: LanguageManager
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
                            ChiikawaSectionHeader(title: lang.todoBadge(pending.count), color: .usagiYellow, icon: "clock.fill")
                            if pending.isEmpty {
                                emptyState(icon: "checkmark.circle", message: lang.allDoneEmpty)
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
                                ChiikawaSectionHeader(title: lang.doneBadge(completed.count), color: .mintGreen, icon: "checkmark.circle.fill")
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
            .navigationTitle(lang.dutiestitle)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    ChiikawaAddButton(color: .usagiYellow) { showingAddTask = true }
                }
            }
            .sheet(isPresented: $showingAddTask) { AddTaskView() }
        }
    }

    private func deleteTask(_ task: TaskItem) {
        NotificationService.shared.cancel(for: task)   // cancel reminder before deleting
        let id = task.id
        withAnimation { modelContext.delete(task) }
        Task { try? await firestore.deleteTask(id: id) }
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
    @EnvironmentObject var firestore: FirestoreService
    @EnvironmentObject var lang: LanguageManager
    let onDelete: () -> Void

    @State private var recurringFlash = false

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
                    if task.isRecurring {
                        // ── Recurring: local flash only, task stays in To-Do ──
                        // Never sets isCompleted — task never moves to Done section
                        withAnimation(.spring(dampingFraction: 0.5)) { recurringFlash = true }
                        NotificationService.shared.cancel(for: task)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                            withAnimation(.easeInOut(duration: 0.4)) {
                                recurringFlash = false
                                resetForNextOccurrence()  // bumps dueDate in-place
                            }
                        }
                    } else {
                        // ── Normal: plain toggle ──
                        let completing = !task.isCompleted
                        if completing { NotificationService.shared.cancel(for: task) }
                        withAnimation(.spring()) {
                            task.isCompleted.toggle()
                            task.completedAt = task.isCompleted ? Date() : nil
                        }
                        Task { try? await firestore.updateTask(task) }
                    }
                }) {
                    Image(systemName: (recurringFlash || task.isCompleted) ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(
                            recurringFlash ? Color.mintGreen :
                            task.isCompleted ? Color.mintGreen : Color.inkBrown.opacity(0.4)
                        )
                        .scaleEffect(recurringFlash ? 1.2 : 1.0)
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
                        Text(lang.localizedCategory(task.category))
                        if task.isRecurring {
                            Text("·")
                            Image(systemName: "arrow.trianglehead.2.clockwise")
                                .font(.system(size: 9))
                            Text(lang.localizedRecurrence(task.recurrenceRule))
                        }
                        if task.reminderEnabled {
                            Text("·")
                            Image(systemName: "bell.fill")
                                .font(.system(size: 9))
                        }
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
                Label(lang.delete, systemImage: "trash")
            }
        }
    }

    // MARK: - Reset recurring task in-place (no copy spawned)
    private func resetForNextOccurrence() {
        let cal = Calendar.current
        let nextDue: Date
        switch task.recurrenceRule {
        case "daily":   nextDue = cal.date(byAdding: .day,   value: 1, to: task.dueDate) ?? task.dueDate
        case "weekly":  nextDue = cal.date(byAdding: .day,   value: 7, to: task.dueDate) ?? task.dueDate
        case "monthly": nextDue = cal.date(byAdding: .month, value: 1, to: task.dueDate) ?? task.dueDate
        default: return
        }
        // Reset the same task object — no new copy, no accumulation in Done list
        task.isCompleted = false
        task.completedAt = nil
        task.dueDate     = nextDue

        // Bump the reminder to the next occurrence's time
        if task.reminderEnabled, let oldReminder = task.reminderTime {
            let nextReminder: Date
            switch task.recurrenceRule {
            case "daily":   nextReminder = cal.date(byAdding: .day,   value: 1, to: oldReminder) ?? oldReminder
            case "weekly":  nextReminder = cal.date(byAdding: .day,   value: 7, to: oldReminder) ?? oldReminder
            case "monthly": nextReminder = cal.date(byAdding: .month, value: 1, to: oldReminder) ?? oldReminder
            default:        nextReminder = oldReminder
            }
            task.reminderTime = nextReminder
            NotificationService.shared.schedule(for: task)  // same UUID → clean reschedule
        }
        // Push the full reset state to Firestore (overwrites the doc in-place)
        Task { try? await firestore.addTask(task) }
    }
}

// MARK: - Priority Badge
struct PriorityBadge: View {
    let priority: String
    @EnvironmentObject var lang: LanguageManager

    var color: Color {
        switch priority.lowercased() {
        case "high":   return .blushPink
        case "medium": return .usagiYellow
        default:       return .hachiwareBlue
        }
    }

    var body: some View {
        Text(lang.localizedPriority(priority))
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
