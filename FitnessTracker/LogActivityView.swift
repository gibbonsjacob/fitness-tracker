//
//  LogActivityView.swift
//  FitnessTracker
//

import SwiftUI
import SwiftData

struct LogActivityView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var activityType: ActivityType = .running
    @State private var distanceText = ""
    @State private var hours = 0
    @State private var minutes = 30
    @State private var date = Date()

    private var canSave: Bool {
        guard let distance = Double(distanceText), distance > 0 else { return false }
        return hours > 0 || minutes > 0
    }

    var body: some View {
        Form {
            Section("Activity") {
                Picker("Type", selection: $activityType) {
                    ForEach(ActivityType.allCases, id: \.self) { type in
                        Text(type.label).tag(type)
                    }
                }
                .pickerStyle(.segmented)

                DatePicker("Date", selection: $date, displayedComponents: .date)
            }

            Section("Details") {
                HStack {
                    Text("Distance")
                    Spacer()
                    TextField("0.0", text: $distanceText)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                    Text("mi")
                        .foregroundStyle(.secondary)
                }

                Stepper("Hours: \(hours)", value: $hours, in: 0...10)
                Stepper("Minutes: \(minutes)", value: $minutes, in: 0...59)
            }
        }
        .navigationTitle("Log Activity")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    saveActivity()
                }
                .disabled(!canSave)
            }
        }
    }

    private func saveActivity() {
        guard let distance = Double(distanceText), distance > 0 else { return }

        let durationSeconds = Double(hours * 3600 + minutes * 60)
        guard durationSeconds > 0 else { return }

        let activity = CardioActivity(
            activityType: activityType,
            distanceMiles: distance,
            durationSeconds: durationSeconds,
            date: date
        )
        modelContext.insert(activity)
        dismiss()
    }
}

#Preview {
    NavigationStack {
        LogActivityView()
    }
    .modelContainer(for: CardioActivity.self, inMemory: true)
}
