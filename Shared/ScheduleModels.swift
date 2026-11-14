import Foundation

// MARK: - Time Slot
struct TimeSlot: Codable, Identifiable, Hashable {
    let index: Int
    let start: String
    let end: String

    var id: Int { index }

    var startTime: Date? {
        Self.timeFormatter.date(from: start)
    }

    var endTime: Date? {
        Self.timeFormatter.date(from: end)
    }

    static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        f.locale = Locale(identifier: "uk_UA")
        return f
    }()

    func contains(_ date: Date) -> Bool {
        guard let start = startTime, let end = endTime else { return false }
        let calendar = Calendar.current
        let startComponents = calendar.dateComponents([.hour, .minute], from: start)
        let endComponents = calendar.dateComponents([.hour, .minute], from: end)
        let dateComponents = calendar.dateComponents([.hour, .minute], from: date)

        guard let sh = startComponents.hour, let sm = startComponents.minute,
              let eh = endComponents.hour, let em = endComponents.minute,
              let dh = dateComponents.hour, let dm = dateComponents.minute else { return false }

        let startMinutes = sh * 60 + sm
        let endMinutes = eh * 60 + em
        let dateMinutes = dh * 60 + dm

        return dateMinutes >= startMinutes && dateMinutes < endMinutes
    }

    func timeUntilStart(from date: Date) -> TimeInterval? {
        guard let start = startTime else { return nil }
        let calendar = Calendar.current
        let startComponents = calendar.dateComponents([.hour, .minute], from: start)
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)

        guard let sh = startComponents.hour, let sm = startComponents.minute,
              let y = dateComponents.year, let m = dateComponents.month, let d = dateComponents.day else { return nil }

        let targetDate = calendar.date(from: DateComponents(year: y, month: m, day: d, hour: sh, minute: sm))
        return targetDate?.timeIntervalSince(date)
    }
}

// MARK: - Lesson
struct Lesson: Codable, Identifiable, Hashable {
    let id = UUID()
    let slot: Int
    let subject: String
    let room: String
    let teacher: String

    enum CodingKeys: String, CodingKey {
        case slot, subject, room, teacher
    }
}

// MARK: - Day Schedule
struct DaySchedule: Codable, Hashable {
    let even: [Lesson]
    let odd: [Lesson]

    func lessons(for parity: WeekParity) -> [Lesson] {
        parity == .even ? even : odd
    }
}

// MARK: - Week Parity
enum WeekParity: String, Codable, CaseIterable {
    case even = "even"
    case odd = "odd"

    var displayName: String {
        self == .even ? "Чётная" : "Нечётная"
    }

    static func current(for date: Date = Date()) -> WeekParity {
        let calendar = Calendar.current
        let weekOfYear = calendar.component(.weekOfYear, from: date)
        return weekOfYear % 2 == 0 ? .even : .odd
    }
}

// MARK: - Weekday
enum Weekday: Int, Codable, CaseIterable {
    case monday = 1, tuesday, wednesday, thursday, friday, saturday, sunday

    var key: String {
        switch self {
        case .monday: return "monday"
        case .tuesday: return "tuesday"
        case .wednesday: return "wednesday"
        case .thursday: return "thursday"
        case .friday: return "friday"
        case .saturday: return "saturday"
        case .sunday: return "sunday"
        }
    }

    var shortName: String {
        switch self {
        case .monday: return "Пн"
        case .tuesday: return "Вт"
        case .wednesday: return "Ср"
        case .thursday: return "Чт"
        case .friday: return "Пт"
        case .saturday: return "Сб"
        case .sunday: return "Нд"
        }
    }

    var fullName: String {
        switch self {
        case .monday: return "Понедельник"
        case .tuesday: return "Вторник"
        case .wednesday: return "Среда"
        case .thursday: return "Четверг"
        case .friday: return "Пятница"
        case .saturday: return "Суббота"
        case .sunday: return "Воскресенье"
        }
    }

    static func current(for date: Date = Date()) -> Weekday {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)
        return Weekday(rawValue: weekday) ?? .monday
    }
}

// MARK: - Full Schedule
struct Schedule: Codable {
    let version: Int
    let group: String
    let timeSlots: [TimeSlot]
    let schedule: [String: DaySchedule]

    func lessons(for weekday: Weekday, parity: WeekParity) -> [Lesson] {
        schedule[weekday.key]?.lessons(for: parity) ?? []
    }

    func currentLesson(at date: Date = Date()) -> (Lesson, TimeSlot)? {
        let weekday = Weekday.current(for: date)
        let parity = WeekParity.current(for: date)
        let lessons = self.lessons(for: weekday, parity: parity)

        for lesson in lessons {
            if let slot = timeSlots.first(where: { $0.index == lesson.slot }),
               slot.contains(date) {
                return (lesson, slot)
            }
        }
        return nil
    }

    func nextLesson(after date: Date = Date()) -> (Lesson, TimeSlot, Date)? {
        let calendar = Calendar.current
        let weekday = Weekday.current(for: date)
        let parity = WeekParity.current(for: date)
        let lessons = self.lessons(for: weekday, parity: parity)

        // Today's upcoming lessons
        for lesson in lessons {
            if let slot = timeSlots.first(where: { $0.index == lesson.slot }),
               let startTime = slot.startTime {
                let targetDate = calendar.date(bySettingHour: calendar.component(.hour, from: startTime),
                                                minute: calendar.component(.minute, from: startTime),
                                                second: 0, of: date)!
                if targetDate > date {
                    return (lesson, slot, targetDate)
                }
            }
        }

        // Next days (up to 7 days ahead)
        for dayOffset in 1...7 {
            guard let nextDate = calendar.date(byAdding: .day, value: dayOffset, to: date) else { continue }
            let nextWeekday = Weekday.current(for: nextDate)
            let nextParity = WeekParity.current(for: nextDate)
            let nextLessons = self.lessons(for: nextWeekday, parity: nextParity)

            if let firstLesson = nextLessons.first,
               let slot = timeSlots.first(where: { $0.index == firstLesson.slot }),
               let startTime = slot.startTime {
                let targetDate = calendar.date(bySettingHour: calendar.component(.hour, from: startTime),
                                                minute: calendar.component(.minute, from: startTime),
                                                second: 0, of: nextDate)!
                return (firstLesson, slot, targetDate)
            }
        }
        return nil
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

// MARK: - Schedule Store
final class ScheduleStore: ObservableObject {
    static let shared = ScheduleStore()

    @Published private(set) var schedule: Schedule

    private init() {
        // Load from App Group first, then bundle
        if let url = AppGroup.scheduleURL,
           let data = try? Data(contentsOf: url),
           let decoded = try? JSONDecoder().decode(Schedule.self, from: data) {
            self.schedule = decoded
        } else if let url = Bundle.main.url(forResource: "schedule", withExtension: "json"),
                  let data = try? Data(contentsOf: url),
                  let decoded = try? JSONDecoder().decode(Schedule.self, from: data) {
            self.schedule = decoded
        } else {
            // Fallback empty schedule
            self.schedule = Schedule(version: 1, group: "", timeSlots: [], schedule: [:])
        }
    }

    func save(_ schedule: Schedule) {
        self.schedule = schedule
        if let url = AppGroup.scheduleURL,
           let data = try? JSONEncoder().encode(schedule) {
            try? data.write(to: url, options: .atomic)
        }
    }
}