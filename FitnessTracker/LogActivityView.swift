//
//  LogActivityView.swift
//  FitnessTracker
//

import SwiftUI
import SwiftData

struct LogActivityView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    private let existingActivity: CardioActivity?

    @State private var activityType: ActivityType
    @State private var distanceText: String
    @State private var durationText: String
    @State private var date: Date
    @State private var isFormValid = false
    @FocusState private var focusedField: Field?

    init(
        existingActivity: CardioActivity? = nil,
        initialActivityType: ActivityType = .running,
        initialDurationSeconds: Double? = nil,
        initialDistanceMiles: Double? = nil,
        initialDate: Date? = nil
    ) {
        self.existingActivity = existingActivity

        if let existingActivity {
            _activityType = State(initialValue: existingActivity.activityType)
            _durationText = State(
                initialValue: Self.formatDuration(seconds: existingActivity.durationSeconds)
            )
            _distanceText = State(
                initialValue: Self.formatDistanceInput(existingActivity.distanceMiles)
            )
            _date = State(initialValue: existingActivity.date)
        } else {
            _activityType = State(initialValue: initialActivityType)
            _durationText = State(
                initialValue: Self.formatDuration(seconds: initialDurationSeconds ?? 1_800)
            )
            _distanceText = State(
                initialValue: Self.formatDistanceInput(initialDistanceMiles)
            )
            _date = State(initialValue: initialDate ?? Date())
        }
    }

    private enum Field {
        case distance
        case duration
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
                LabeledContent("Distance (mi)") {
                    TextField("0.0", text: $distanceText)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .focused($focusedField, equals: .distance)
                }

                LabeledContent("Duration") {
                    TextField("0:00:00", text: $durationText)
                        .keyboardType(.asciiCapable)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .multilineTextAlignment(.trailing)
                        .monospacedDigit()
                        .focused($focusedField, equals: .duration)
                        .onSubmit(normalizeDurationText)
                }

                if !durationText.isEmpty && parsedDurationSeconds == nil {
                    Text("Enter duration as HH:MM:SS. Minutes and seconds over 59 are converted automatically.")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }

            if focusedField != nil {
                Section {
                    Button("Done") {
                        focusedField = nil
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .onAppear(perform: validateForm)
        .onChange(of: distanceText) { _, newValue in
            let sanitized = Self.sanitizeDistanceInput(newValue)
            if sanitized != newValue {
                distanceText = sanitized
            }
            validateForm()
        }
        .onChange(of: durationText) { _, _ in validateForm() }
        .onChange(of: focusedField) { oldField, newField in
            if oldField == .duration && newField != .duration {
                normalizeDurationText()
            }
        }
        .navigationTitle(existingActivity == nil ? "Log Activity" : "Edit Activity")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    saveActivity()
                }
                .disabled(!isFormValid)
            }
        }
    }

    private func validateForm() {
        guard let distance = parseDistance(distanceText), distance > 0 else {
            isFormValid = false
            return
        }
        guard let seconds = parsedDurationSeconds, seconds > 0 else {
            isFormValid = false
            return
        }
        isFormValid = true
    }

    private var parsedDurationSeconds: Double? {
        Self.parseDuration(durationText)
    }

    private func saveActivity() {
        normalizeDurationText()
        guard let distance = parseDistance(distanceText), distance > 0 else { return }
        guard let durationSeconds = parsedDurationSeconds else { return }

        if let existingActivity {
            existingActivity.activityType = activityType
            existingActivity.distanceMiles = distance
            existingActivity.durationSeconds = durationSeconds
            existingActivity.date = date

            do {
                try modelContext.save()
                dismiss()
            } catch {
                return
            }
        } else {
            let activity = CardioActivity(
                activityType: activityType,
                distanceMiles: distance,
                durationSeconds: durationSeconds,
                date: date
            )
            modelContext.insert(activity)

            do {
                try modelContext.save()
                dismiss()
            } catch {
                modelContext.delete(activity)
            }
        }
    }

    private func parseDistance(_ text: String) -> Double? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return Double(trimmed)
    }

    private static func sanitizeDistanceInput(_ text: String) -> String {
        var result = ""
        var hasDecimalSeparator = false

        for character in text {
            if character.isNumber {
                result.append(character)
            } else if character == "." && !hasDecimalSeparator {
                hasDecimalSeparator = true
                result.append(character)
            }
        }

        return result
    }

    private func normalizeDurationText() {
        guard let seconds = parsedDurationSeconds else { return }
        let formatted = Self.formatDuration(seconds: seconds)
        if formatted != durationText {
            durationText = formatted
        }
        validateForm()
    }

    private static func formatDuration(seconds: Double) -> String {
        let total = Int(seconds)
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let secs = total % 60
        return String(format: "%d:%02d:%02d", hours, minutes, secs)
    }

    private static func formatDistanceInput(_ miles: Double?) -> String {
        guard let miles, miles > 0 else { return "" }
        return String(format: "%.2f", miles)
    }

    private static func parseDuration(_ text: String) -> Double? {
        let normalized = text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "：", with: ":")
            .replacingOccurrences(of: "﹕", with: ":")

        let parts = normalized
            .split(separator: ":", omittingEmptySubsequences: false)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

        guard !normalized.isEmpty, parts.count <= 3, !parts.contains(where: \.isEmpty) else {
            return nil
        }

        let numbers = parts.compactMap { Int($0) }
        guard numbers.count == parts.count else { return nil }

        let hours: Int
        let minutes: Int
        let seconds: Int

        switch parts.count {
        case 3:
            (hours, minutes, seconds) = (numbers[0], numbers[1], numbers[2])
        case 2:
            (hours, minutes, seconds) = (numbers[0], numbers[1], 0)
        case 1:
            (hours, minutes, seconds) = (0, numbers[0], 0)
        default:
            return nil
        }

        guard hours >= 0, minutes >= 0, seconds >= 0 else {
            return nil
        }

        let total = hours * 3600 + minutes * 60 + seconds
        return total > 0 ? Double(total) : nil
    }
}

#Preview {
    NavigationStack {
        LogActivityView()
    }
    .modelContainer(for: CardioActivity.self, inMemory: true)
}
