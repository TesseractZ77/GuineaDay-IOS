import SwiftUI
import SwiftData
import Charts

struct WeightLogView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var guineaPig: GuineaPig

    // @Query keeps the list reactive — filter to this pig in Swift
    @Query(sort: \WeightLog.date, order: .reverse) private var allLogs: [WeightLog]

    @State private var newWeight: Int = 0
    @State private var newDate: Date = Date()
    @State private var isAdding: Bool = false

    var pigLogs: [WeightLog] {
        allLogs.filter { $0.guineaPig?.persistentModelID == guineaPig.persistentModelID }
    }

    var chartLogs: [WeightLog] {
        pigLogs.sorted { $0.date < $1.date }  // ascending for the chart
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {

            // ── Header ──
            HStack {
                ChiikawaSectionHeader(title: "Weight Tracker", color: Color.mintGreen, icon: "scalemass.fill")
                Spacer()
                Button(action: { withAnimation { isAdding.toggle() } }) {
                    ZStack {
                        Circle()
                            .fill(isAdding ? Color.blushPink : Color.usagiYellow)
                            .frame(width: 32, height: 32)
                            .overlay(Circle().stroke(Color.inkBrown, lineWidth: 2))
                            .shadow(color: Color.inkBrown.opacity(0.3), radius: 0, x: 1, y: 2)
                        Image(systemName: isAdding ? "xmark" : "plus")
                            .font(.system(size: 13, weight: .black))
                            .foregroundColor(Color.inkBrown)
                    }
                }
            }

            // ── Add form ──
            if isAdding {
                HStack(spacing: 10) {
                    DatePicker("", selection: $newDate, displayedComponents: .date)
                        .labelsHidden()
                        .tint(Color.inkBrown)
                        .frame(maxWidth: .infinity)

                    HStack(spacing: 4) {
                        TextField("0", value: $newWeight, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.center)
                            .frame(width: 60)
                            .padding(.vertical, 6)
                            .background(Color.wallGray)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.inkBrown, lineWidth: 1.5))
                        Text("g")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(Color.inkBrown)
                    }

                    Button("Save") { addWeight() }
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(Color.inkBrown)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(Color.mintGreen)
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Color.inkBrown, lineWidth: 2))
                        .shadow(color: Color.inkBrown.opacity(0.3), radius: 0, x: 1, y: 2)
                        .disabled(newWeight <= 0)
                }
                .padding(10)
                .background(Color.wallGray)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.inkBrown, lineWidth: 2))
                .transition(.scale.combined(with: .opacity))
            }

            if pigLogs.isEmpty {
                Text("No records yet — add your first weigh-in!")
                    .font(.system(size: 13, design: .rounded))
                    .foregroundStyle(Color.inkBrown.opacity(0.5))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                // ── Weight Chart ──
                weightChart

                // ── History list ──
                VStack(spacing: 0) {
                    ForEach(pigLogs, id: \.persistentModelID) { log in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(log.date, style: .date)
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                                    .foregroundStyle(Color.inkBrown)
                                if let idx = chartLogs.firstIndex(where: { $0.persistentModelID == log.persistentModelID }),
                                   idx > 0 {
                                    let diff = log.weightGrams - chartLogs[idx - 1].weightGrams
                                    Text(diff == 0 ? "No change" : (diff > 0 ? "+\(diff)g" : "\(diff)g"))
                                        .font(.system(size: 10, design: .rounded))
                                        .foregroundStyle(diff > 0 ? Color.hachiwareBlue : (diff < 0 ? Color.blushPink : Color.inkBrown.opacity(0.4)))
                                }
                            }
                            Spacer()
                            Text("\(log.weightGrams)g")
                                .font(.system(size: 17, weight: .black, design: .rounded))
                                .foregroundStyle(Color.inkBrown)

                            Button(action: { deleteLog(log) }) {
                                Image(systemName: "trash")
                                    .font(.system(size: 12))
                                    .foregroundColor(Color.blushPink)
                            }
                            .buttonStyle(.plain)
                            .padding(.leading, 8)
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 4)

                        if log.persistentModelID != pigLogs.last?.persistentModelID {
                            Divider().background(Color.inkBrown.opacity(0.15))
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(Color.chiikawaWhite)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.inkBrown, lineWidth: 2.5))
        .shadow(color: Color.inkBrown.opacity(0.3), radius: 0, x: 2, y: 3)
    }

    // MARK: - Chart

    @ViewBuilder
    var weightChart: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Weight History")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(Color.inkBrown.opacity(0.6))

            Chart {
                ForEach(chartLogs, id: \.persistentModelID) { log in
                    LineMark(
                        x: .value("Date", log.date),
                        y: .value("Weight (g)", log.weightGrams)
                    )
                    .foregroundStyle(Color.hachiwareBlue)
                    .lineStyle(StrokeStyle(lineWidth: 2.5))

                    PointMark(
                        x: .value("Date", log.date),
                        y: .value("Weight (g)", log.weightGrams)
                    )
                    .foregroundStyle(Color.inkBrown)
                    .symbolSize(50)

                    AreaMark(
                        x: .value("Date", log.date),
                        y: .value("Weight (g)", log.weightGrams)
                    )
                    .foregroundStyle(Color.hachiwareBlue.opacity(0.15))
                }
            }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 4)) { value in
                    AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                        .font(.system(size: 9, design: .rounded))
                        .foregroundStyle(Color.inkBrown)
                }
            }
            .chartYAxis {
                AxisMarks(values: .automatic(desiredCount: 4)) { value in
                    AxisGridLine().foregroundStyle(Color.inkBrown.opacity(0.1))
                    AxisValueLabel()
                        .font(.system(size: 9, design: .rounded))
                        .foregroundStyle(Color.inkBrown)
                }
            }
            .frame(height: 140)
            .padding(.vertical, 6)
        }
        .padding(12)
        .background(Color.wallGray)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.inkBrown.opacity(0.3), lineWidth: 1.5))
    }

    // MARK: - Actions

    private func addWeight() {
        let log = WeightLog(date: newDate, weightGrams: newWeight)
        log.guineaPig = guineaPig
        modelContext.insert(log)
        if !guineaPig.weightLogs.contains(where: { $0.persistentModelID == log.persistentModelID }) {
            guineaPig.weightLogs.append(log)
        }
        withAnimation {
            newWeight = 0
            newDate = Date()
            isAdding = false
        }
    }

    private func deleteLog(_ log: WeightLog) {
        withAnimation {
            guineaPig.weightLogs.removeAll { $0.persistentModelID == log.persistentModelID }
            modelContext.delete(log)
        }
    }
}
