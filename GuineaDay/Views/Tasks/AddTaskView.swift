import SwiftUI
import SwiftData

// MARK: - Template model
struct TaskTemplate: Identifiable {
    let id             = UUID()
    let emoji:          String
    let title:          String
    let category:       String
    let priority:       String
    let recurrenceRule: String
}

// Template titles use lang — but templates are a struct, so we compute them inside the view body.
// See lang.tplChangeWater etc used in body.
private let taskTemplateData: [(emoji: String, cat: String, pri: String, rec: String)] = [
    ("💧", "feeding",  "high",   "daily"),
    ("🥕", "feeding",  "high",   "daily"),
    ("🌾", "feeding",  "medium", "daily"),
    ("🐾", "play",     "medium", "daily"),
    ("⚖️", "health",   "medium", "weekly"),
    ("🏠", "cleaning", "high",   "weekly"),
    ("✂️", "health",   "low",    "monthly"),
    ("🩺", "health",   "medium", "monthly"),
]

// MARK: - Add Task View
struct AddTaskView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss)      private var dismiss
    @EnvironmentObject var firestore: FirestoreService
    @EnvironmentObject var lang: LanguageManager

    // Form state
    @State private var title          = ""
    @State private var dueDate        = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
    @State private var category       = "feeding"
    @State private var priority       = "medium"
    @State private var recurrenceRule = "none"
    @State private var reminderEnabled = false
    @State private var reminderTime    = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()

    // UI state
    @State private var selectedTemplateId: UUID?  = nil
    @State private var notifDenied               = false
    @State private var isSaving                  = false

    // Computed from lang so they update when language changes
    private var taskTemplates: [TaskTemplate] {
        let titles = [lang.tplChangeWater, lang.tplFreshVeggies, lang.tplRefillHay,
                      lang.tplFloorTime, lang.tplWeighPiggies, lang.tplCleanCage,
                      lang.tplNailTrim, lang.tplHealthCheck]
        return zip(taskTemplateData, titles).map { data, title in
            TaskTemplate(emoji: data.emoji, title: title, category: data.cat,
                         priority: data.pri, recurrenceRule: data.rec)
        }
    }

    private var categories: [(String, String)] {
        [("Feeding", lang.catFeeding),  ("Cleaning", lang.catCleaning),
         ("Health", lang.catHealth),   ("Play", lang.catPlay),
         ("Other", lang.catOther)]
    }
    private let priorities: [(String, Color)] = [
        ("low", .hachiwareBlue), ("medium", .usagiYellow), ("high", .blushPink)
    ]
    private var recurrences: [(String, String)] {
        [("none",    lang.recurrenceNone),  ("daily",  lang.recurrenceDaily),
         ("weekly",  lang.recurrenceWeekly), ("monthly", lang.recurrenceMonthly)]
    }

    // MARK: - Body
    var body: some View {
        NavigationStack {
            ZStack {
                Color.wallGray.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        templatesSection
                        detailsSection
                        repeatSection
                        reminderSection
                        Spacer().frame(height: 24)
                    }
                    .padding(.horizontal)
                    .padding(.top, 12)
                }
            }
            .navigationTitle(lang.newTask)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(lang.cancel) { dismiss() }
                        .foregroundStyle(Color.inkBrown)
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isSaving {
                        ProgressView().tint(Color.inkBrown)
                    } else {
                        Button(lang.save) { Task { await saveTask() } }
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.inkBrown)
                            .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
            }
        }
    }

    // MARK: - Subviews
    private var templatesSection: some View {
        sectionCard(title: lang.sectionTemplates) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(taskTemplates) { tpl in
                        let isSelected = selectedTemplateId == tpl.id
                        Button { applyTemplate(tpl) } label: {
                            VStack(spacing: 6) {
                                Text(tpl.emoji)
                                    .font(.system(size: 28))
                                Text(tpl.title)
                                    .font(.system(size: 10, weight: .bold, design: .rounded))
                                    .foregroundColor(Color.inkBrown)
                                    .multilineTextAlignment(.center)
                                    .frame(width: 64)
                            }
                            .frame(width: 72, height: 78)
                            .background(isSelected ? Color.usagiYellow : Color.wallGray)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .overlay(RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.inkBrown, lineWidth: isSelected ? 2.5 : 1.5))
                            .scaleEffect(isSelected ? 1.05 : 1.0)
                            .animation(.spring(dampingFraction: 0.65), value: isSelected)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }

    private var detailsSection: some View {
        sectionCard(title: lang.sectionDetails) {
            // Title
            VStack(alignment: .leading, spacing: 6) {
                Text(lang.labelTitle).settingsLabel()
                TextField(lang.taskPlaceholder, text: $title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(Color.inkBrown)
                Divider().background(Color.inkBrown.opacity(0.2))
            }

            // Due date
            VStack(alignment: .leading, spacing: 6) {
                Text(lang.labelDueDate).settingsLabel()
                DatePicker("", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                    .labelsHidden()
                    .tint(Color.inkBrown)
            }

            // Category pills
            VStack(alignment: .leading, spacing: 8) {
                Text(lang.labelCategory).settingsLabel()
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(categories, id: \.0) { item in
                            let cat   = item.0
                            let label = item.1   // fully-localized string e.g. "🍽 喂食" or "🍽 Feeding"
                            let sel   = category == cat
                            Button { withAnimation { category = cat } } label: {
                                Text(label)
                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                                    .foregroundColor(Color.inkBrown)
                                    .padding(.horizontal, 10).padding(.vertical, 6)
                                    .background(sel ? Color.mintGreen : Color.wallGray)
                                    .clipShape(Capsule())
                                    .overlay(Capsule().stroke(Color.inkBrown, lineWidth: sel ? 2.5 : 1.5))
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }

            // Priority pills
            VStack(alignment: .leading, spacing: 8) {
                Text(lang.labelPriority).settingsLabel()
                HStack(spacing: 8) {
                    ForEach(priorities, id: \.0) { item in
                        let p = item.0
                        let color = item.1
                        let sel = priority == p
                        Button { withAnimation { priority = p } } label: {
                            Text(lang.localizedPriority(p))
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundColor(Color.inkBrown)
                                .padding(.horizontal, 12).padding(.vertical, 6)
                                .background(sel ? color : Color.wallGray)
                                .clipShape(Capsule())
                                .overlay(Capsule().stroke(Color.inkBrown, lineWidth: sel ? 2.5 : 1.5))
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }

    private var repeatSection: some View {
        sectionCard(title: lang.sectionRepeat) {
            HStack(spacing: 8) {
                ForEach(recurrences, id: \.0) { item in
                    let rule = item.0
                    let label = item.1
                    let sel = recurrenceRule == rule
                    Button { withAnimation { recurrenceRule = rule } } label: {
                        Text(label)
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(Color.inkBrown)
                            .padding(.horizontal, 10).padding(.vertical, 6)
                            .background(sel ? Color.lavenderPurple : Color.wallGray)
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(Color.inkBrown, lineWidth: sel ? 2.5 : 1.5))
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }

    private var reminderSection: some View {
        sectionCard(title: lang.sectionReminder) {
            Toggle(isOn: $reminderEnabled.animation()) {
                Text(lang.remindMe)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(Color.inkBrown)
            }
            .tint(Color.mintGreen)

            if reminderEnabled {
                Divider().background(Color.inkBrown.opacity(0.15))
                DatePicker(lang.remindAt, selection: $reminderTime,
                           in: Date()...,
                           displayedComponents: [.date, .hourAndMinute])
                    .font(.system(size: 14, design: .rounded))
                    .tint(Color.inkBrown)
            }

            if notifDenied {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundColor(Color.blushPink)
                    Text(lang.notifDeniedMsg)
                        .font(.system(size: 11, design: .rounded))
                        .foregroundColor(Color.inkBrown.opacity(0.7))
                }
            }
        }
        .onChange(of: reminderEnabled) { _, newValue in
            if newValue {
                reminderTime = dueDate   // default to due date
                Task {
                    let granted = await NotificationService.shared.requestPermission()
                    if !granted {
                        reminderEnabled = false
                        notifDenied     = true
                    }
                }
            }
        }
    }

    // MARK: - Apply template
    private func applyTemplate(_ tpl: TaskTemplate) {
        withAnimation {
            selectedTemplateId = tpl.id
            title              = tpl.title
            category           = tpl.category
            priority           = tpl.priority
            recurrenceRule     = tpl.recurrenceRule
        }
    }

    // MARK: - Save
    private func saveTask() async {
        let trimmed = title.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, !isSaving else { return }
        isSaving = true

        let newTask             = TaskItem(title: trimmed, dueDate: dueDate,
                                           category: category, priority: priority)
        newTask.isRecurring     = recurrenceRule != "none"
        newTask.recurrenceRule  = recurrenceRule
        newTask.reminderEnabled = reminderEnabled
        newTask.reminderTime    = reminderEnabled ? reminderTime : nil

        // Schedule local notification on this device
        if reminderEnabled {
            NotificationService.shared.schedule(for: newTask)
        }

        modelContext.insert(newTask)
        try? await firestore.addTask(newTask)

        isSaving = false
        dismiss()
    }

    // MARK: - Section card builder
    @ViewBuilder
    private func sectionCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(Color.inkBrown.opacity(0.45))
                .padding(.leading, 4)
            VStack(alignment: .leading, spacing: 12) {
                content()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(Color.chiikawaWhite)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.inkBrown, lineWidth: 2.5))
            .shadow(color: Color.inkBrown.opacity(0.3), radius: 0, x: 2, y: 3)
        }
    }
}

// MARK: - Text helper (shared with SettingsView pattern)
private extension Text {
    func settingsLabel() -> some View {
        self.font(.system(size: 10, weight: .bold, design: .rounded))
            .foregroundColor(Color.inkBrown.opacity(0.45))
            .textCase(.uppercase)
    }
}

#Preview {
    AddTaskView()
        .modelContainer(for: TaskItem.self, inMemory: true)
}
