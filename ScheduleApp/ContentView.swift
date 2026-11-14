import SwiftUI
import WidgetKit

struct ContentView: View {
    @EnvironmentObject var store: ScheduleStore
    @State private var selectedWeekday: Weekday = .current()
    @State private var selectedParity: WeekParity = .current()

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()

                VStack(spacing: 0) {
                    // Current lesson card
                    CurrentLessonCard(schedule: store.schedule)
                        .padding(.horizontal)
                        .padding(.top, 8)

                    // Weekday picker
                    WeekdayPicker(selected: $selectedWeekday)
                        .padding(.horizontal)
                        .padding(.vertical, 8)

                    // Parity picker
                    ParityPicker(selected: $selectedParity)
                        .padding(.horizontal)
                        .padding(.bottom, 8)

                    // Lessons list
                    LessonsList(
                        schedule: store.schedule,
                        weekday: selectedWeekday,
                        parity: selectedParity
                    )
                }
            }
            .navigationTitle("Расписание \(store.schedule.group)")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        WidgetCenter.shared.reloadAllTimelines()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
        }
    }
}

// MARK: - Current Lesson Card
struct CurrentLessonCard: View {
    let schedule: Schedule
    @State private var now = Date()
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        Group {
            if let (lesson, slot) = schedule.currentLesson(at: now) {
                CurrentLessonView(lesson: lesson, slot: slot, now: now)
            } else if let (nextLesson, nextSlot, startDate) = schedule.nextLesson(after: now) {
                NextLessonView(lesson: nextLesson, slot: nextSlot, startDate: startDate, now: now)
            } else {
                NoLessonsView()
            }
        }
        .onReceive(timer) { now = $0 }
    }
}

struct CurrentLessonView: View {
    let lesson: Lesson
    let slot: TimeSlot
    let now: Date

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Label("Сейчас", systemImage: "clock.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.green)
                Spacer()
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(lesson.subject)
                    .font(.headline)
                    .foregroundStyle(.primary)

                HStack(spacing: 12) {
                    Label(lesson.room, systemImage: "door.left.hand.open")
                    Label(lesson.teacher, systemImage: "person.fill")
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)

                if let timeLeft = slot.endTime?.timeIntervalSince(now), timeLeft > 0 {
                    ProgressView(value: 1 - timeLeft / (slot.endTime!.timeIntervalSince(slot.startTime!)))
                        .tint(.green)
                    Text("Осталось: \(formatInterval(timeLeft))")
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(.green.opacity(0.1), in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.green.opacity(0.3), lineWidth: 1)
        )
    }
}

struct NextLessonView: View {
    let lesson: Lesson
    let slot: TimeSlot
    let startDate: Date
    let now: Date

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Label("Следующая", systemImage: "clock")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.blue)
                Spacer()
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(lesson.subject)
                    .font(.headline)
                    .foregroundStyle(.primary)

                HStack(spacing: 12) {
                    Label(lesson.room, systemImage: "door.left.hand.open")
                    Label(lesson.teacher, systemImage: "person.fill")
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)

                Text("Начинается в \(slot.start) — \(slot.end)")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.blue)

                Text("Через: \(formatInterval(startDate.timeIntervalSince(now)))")
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.blue.opacity(0.3), lineWidth: 1)
        )
    }
}

struct NoLessonsView: View {
    var body: some View {
        VStack(spacing: 8) {
            Label("Пар нет", systemImage: "checkmark.circle.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.gray)
            Text("Отдыхай!")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.gray.opacity(0.1), in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Weekday Picker
struct WeekdayPicker: View {
    @Binding var selected: Weekday

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Weekday.allCases.filter { $0 != .saturday && $0 != .sunday }) { day in
                    Button {
                        withAnimation(.spring(response: 0.3)) { selected = day }
                    } label: {
                        Text(day.shortName)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(selected == day ? .white : .primary)
                            .frame(width: 44, height: 36)
                            .background(
                                selected == day ? Color.accentColor : Color(.systemGray5),
                                in: RoundedRectangle(cornerRadius: 10)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 4)
        }
    }
}

// MARK: - Parity Picker
struct ParityPicker: View {
    @Binding var selected: WeekParity

    var body: some View {
        HStack(spacing: 12) {
            ForEach(WeekParity.allCases) { parity in
                Button {
                    withAnimation(.spring(response: 0.3)) { selected = parity }
                } label: {
                    Text(parity.displayName)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(selected == parity ? .white : .primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            selected == parity ? Color.accentColor : Color(.systemGray5),
                            in: RoundedRectangle(cornerRadius: 10)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Lessons List
struct LessonsList: View {
    let schedule: Schedule
    let weekday: Weekday
    let parity: WeekParity

    var lessons: [Lesson] {
        schedule.lessons(for: weekday, parity: parity)
    }

    var body: some View {
        List {
            if lessons.isEmpty {
                ContentUnavailableView(
                    "Пар нет",
                    systemImage: "calendar.badge.checkmark",
                    description: Text("В этот день занятий не запланировано")
                )
                .listRowBackground(Color.clear)
            } else {
                ForEach(lessons) { lesson in
                    if let slot = schedule.timeSlots.first(where: { $0.index == lesson.slot }) {
                        LessonRow(lesson: lesson, slot: slot)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
    }
}

struct LessonRow: View {
    let lesson: Lesson
    let slot: TimeSlot

    var body: some View {
        HStack(spacing: 12) {
            // Time badge
            VStack(spacing: 2) {
                Text(slot.start)
                    .font(.caption.weight(.semibold))
                Text(slot.end)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 56)
            .padding(.vertical, 8)
            .background(Color.accentColor.opacity(0.15), in: RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                Text(lesson.subject)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)

                HStack(spacing: 8) {
                    Label(lesson.room, systemImage: "door.left.hand.open")
                    Label(lesson.teacher, systemImage: "person.fill")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Helpers
func formatInterval(_ interval: TimeInterval) -> String {
    let total = Int(interval)
    let hours = total / 3600
    let minutes = (total % 3600) / 60
    let seconds = total % 60
    if hours > 0 {
        return String(format: "%dч %02dм", hours, minutes)
    } else if minutes > 0 {
        return String(format: "%dм %02dс", minutes, seconds)
    } else {
        return "\(seconds)с"
    }
}

#Preview {
    ContentView()
        .environmentObject(ScheduleStore.shared)
}