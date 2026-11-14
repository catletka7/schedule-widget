import WidgetKit
import SwiftUI

// MARK: - Timeline Provider
struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), lesson: nil, nextLesson: nil, nextStart: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> Void) {
        let entry = makeEntry(for: Date())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> Void) {
        let now = Date()
        let calendar = Calendar.current
        let schedule = loadSchedule()

        // Get current and next lesson
        let (currentLesson, currentSlot) = currentLessonInfo(schedule: schedule, date: now) ?? (nil, nil)
        let (nextLesson, nextSlot, nextStart) = nextLessonInfo(schedule: schedule, date: now) ?? (nil, nil, nil)

        var entries: [SimpleEntry] = []

        // Entry for current moment
        entries.append(SimpleEntry(
            date: now,
            lesson: currentLesson,
            nextLesson: nextLesson,
            nextStart: nextStart
        ))

        // If there's a current lesson, add entry when it ends
        if let currentSlot = currentSlot,
           let endTime = currentSlot.endTime {
            let endDate = calendar.date(bySettingHour: calendar.component(.hour, from: endTime),
                                         minute: calendar.component(.minute, from: endTime),
                                         second: 0, of: now)!
            if endDate > now {
                let (nextL, nextS, nextSt) = nextLessonInfo(schedule: schedule, date: endDate) ?? (nil, nil, nil)
                entries.append(SimpleEntry(
                    date: endDate,
                    lesson: nextL,
                    nextLesson: nextL,
                    nextStart: nextSt
                ))
            }
        }

        // If there's a next lesson, add entry when it starts
        if let nextStart = nextStart, nextStart > now {
            let (nextL, nextS, nextSt) = nextLessonInfo(schedule: schedule, date: nextStart) ?? (nil, nil, nil)
            entries.append(SimpleEntry(
                date: nextStart,
                lesson: nextL,
                nextLesson: nextL,
                nextStart: nextSt
            ))
        }

        // Update every minute for timer
        let nextUpdate = calendar.date(byAdding: .minute, value: 1, to: now)!
        let timeline = Timeline(entries: entries, policy: .after(nextUpdate))
        completion(timeline)
    }

    private func loadSchedule() -> Schedule {
        // Try App Group first
        if let url = AppGroup.scheduleURL,
           let data = try? Data(contentsOf: url),
           let decoded = try? JSONDecoder().decode(Schedule.self, from: data) {
            return decoded
        }
        // Fallback to bundle
        if let url = Bundle.main.url(forResource: "schedule", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let decoded = try? JSONDecoder().decode(Schedule.self, from: data) {
            return decoded
        }
        return Schedule(version: 1, group: "", timeSlots: [], schedule: [:])
    }

    private func currentLessonInfo(schedule: Schedule, date: Date) -> (Lesson, TimeSlot)? {
        schedule.currentLesson(at: date)
    }

    private func nextLessonInfo(schedule: Schedule, date: Date) -> (Lesson, TimeSlot, Date)? {
        schedule.nextLesson(after: date)
    }

    private func makeEntry(for date: Date) -> SimpleEntry {
        let schedule = loadSchedule()
        let (currentLesson, currentSlot) = currentLessonInfo(schedule: schedule, date: date) ?? (nil, nil)
        let (nextLesson, nextSlot, nextStart) = nextLessonInfo(schedule: schedule, date: date) ?? (nil, nil, nil)

        return SimpleEntry(
            date: date,
            lesson: currentLesson,
            nextLesson: nextLesson,
            nextStart: nextStart
        )
    }
}

// MARK: - Entry
struct SimpleEntry: TimelineEntry {
    let date: Date
    let lesson: Lesson?
    let nextLesson: Lesson?
    let nextStart: Date?
}

// MARK: - Widget Views
struct ScheduleWidgetEntryView: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

struct SmallWidgetView: View {
    let entry: SimpleEntry

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [Color.accentColor.opacity(0.15), Color.accentColor.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 8) {
                // Header
                HStack {
                    if entry.lesson != nil {
                        Label("Сейчас", systemImage: "clock.fill")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.green)
                    } else {
                        Label("Следующая", systemImage: "clock")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.blue)
                    }
                    Spacer()
                    Text(entry.date, style: .time)
                        .font(.caption2.monospaced())
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 4)

                // Main content
                if let lesson = entry.lesson, let slot = findSlot(for: lesson) {
                    CurrentLessonWidgetView(lesson: lesson, slot: slot, now: entry.date)
                } else if let nextLesson = entry.nextLesson, let slot = findSlot(for: nextLesson) {
                    NextLessonWidgetView(lesson: nextLesson, slot: slot, startDate: entry.nextStart, now: entry.date)
                } else {
                    NoLessonsWidgetView()
                }

                Spacer(minLength: 4)

                // Group name
                Text(loadSchedule().group)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .padding(12)
        }
        .widgetURL(URL(string: "schedulewidget://today"))
    }

    private func findSlot(for lesson: Lesson) -> TimeSlot? {
        loadSchedule().timeSlots.first(where: { $0.index == lesson.slot })
    }

    private func loadSchedule() -> Schedule {
        if let url = AppGroup.scheduleURL,
           let data = try? Data(contentsOf: url),
           let decoded = try? JSONDecoder().decode(Schedule.self, from: data) {
            return decoded
        }
        if let url = Bundle.main.url(forResource: "schedule", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let decoded = try? JSONDecoder().decode(Schedule.self, from: data) {
            return decoded
        }
        return Schedule(version: 1, group: "", timeSlots: [], schedule: [:])
    }
}

struct CurrentLessonWidgetView: View {
    let lesson: Lesson
    let slot: TimeSlot
    let now: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(lesson.subject)
                .font(.system(.headline, design: .rounded).weight(.bold))
                .foregroundStyle(.primary)
                .lineLimit(2)
                .minimumScaleFactor(0.8)

            HStack(spacing: 8) {
                Label(lesson.room, systemImage: "door.left.hand.open")
                Label(lesson.teacher, systemImage: "person.fill")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(1)

            if let timeLeft = slot.endTime?.timeIntervalSince(now), timeLeft > 0 {
                VStack(alignment: .leading, spacing: 2) {
                    ProgressView(value: 1 - timeLeft / (slot.endTime!.timeIntervalSince(slot.startTime!)))
                        .tint(.green)
                        .scaleEffect(y: 0.8)
                    Text("Осталось: \(formatInterval(timeLeft))")
                        .font(.caption2.monospaced())
                        .foregroundStyle(.green)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct NextLessonWidgetView: View {
    let lesson: Lesson
    let slot: TimeSlot
    let startDate: Date?
    let now: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(lesson.subject)
                .font(.system(.headline, design: .rounded).weight(.bold))
                .foregroundStyle(.primary)
                .lineLimit(2)
                .minimumScaleFactor(0.8)

            HStack(spacing: 8) {
                Label(lesson.room, systemImage: "door.left.hand.open")
                Label(lesson.teacher, systemImage: "person.fill")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(1)

            Text("\(slot.start) — \(slot.end)")
                .font(.caption.weight(.medium))
                .foregroundStyle(.blue)

            if let startDate = startDate {
                Text("Через: \(formatInterval(startDate.timeIntervalSince(now)))")
                    .font(.caption2.monospaced())
                    .foregroundStyle(.blue)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct NoLessonsWidgetView: View {
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: "checkmark.circle.fill")
                .font(.title)
                .foregroundStyle(.green)
            Text("Пар нет")
                .font(.headline.weight(.semibold))
            Text("Отдыхай!")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Widget Configuration
@main
struct ScheduleWidget: Widget {
    let kind: String = "ScheduleWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            ScheduleWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Расписание")
        .description("Показывает текущую или следующую пару с таймером")
        .supportedFamilies([.systemSmall])
    }
}

// MARK: - App Group
enum AppGroup {
    static let identifier = "group.com.schedulewidget.schedule"
    static let scheduleKey = "schedule.json"

    static var containerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: identifier)
    }

    static var scheduleURL: URL? {
        containerURL?.appendingPathComponent(scheduleKey)
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

#Preview(as: .systemSmall) {
    ScheduleWidget()
} timeline: {
    SimpleEntry(date: Date(), lesson: nil, nextLesson: nil, nextStart: nil)
}