import SwiftUI

/// One cell in Mon–Sun streak row (labels always M T W T F S S).
private struct StreakCalendarDaySlot: Identifiable {
    let id: String
    let label: String
    let date: Date
    let isCompleted: Bool

    var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
}

struct StreakCardView: View {
    let streakData: StreakData
    let personalBest: Int
    let isFirstTimeUser: Bool
    let onViewCalendar: () -> Void

    /// Current calendar week Monday → Sunday with fixed labels M T W T F S S.
    private var calendarWeekSlots: [StreakCalendarDaySlot] {
        let cal = Calendar.current
        let idFormatter = DateFormatter()
        idFormatter.calendar = cal
        idFormatter.dateFormat = "yyyy-MM-dd"

        let todayStart = cal.startOfDay(for: Date())
        let weekday = cal.component(.weekday, from: todayStart)
        let daysSinceMonday = (weekday + 5) % 7
        guard let monday = cal.date(byAdding: .day, value: -daysSinceMonday, to: todayStart) else { return [] }

        let labels = ["M", "T", "W", "T", "F", "S", "S"]
        return (0..<7).compactMap { i -> StreakCalendarDaySlot? in
            guard let date = cal.date(byAdding: .day, value: i, to: monday) else { return nil }
            let dayStart = cal.startOfDay(for: date)
            let completed = streakData.weeklyActivities.contains { act in
                cal.isDate(cal.startOfDay(for: act.date), inSameDayAs: dayStart) && act.isCompleted
            }
            return StreakCalendarDaySlot(
                id: idFormatter.string(from: dayStart),
                label: labels[i],
                date: date,
                isCompleted: completed
            )
        }
    }

    private var isOnFire: Bool {
        streakData.currentStreak >= 5
    }

    /// Maps consecutive-day streak to a week count for display (ceil(days / 7), min 0).
    private func weeksFromDays(_ days: Int) -> Int {
        guard days > 0 else { return 0 }
        return (days + 6) / 7
    }

    private var streakWeeksTitle: String {
        let w = weeksFromDays(streakData.currentStreak)
        return "\(w) Week" + (w == 1 ? "" : "s")
    }

    private var personalBestWeeksLine: String {
        let w = weeksFromDays(personalBest)
        return "PERSONAL BEST: \(w) WEEK" + (w == 1 ? "" : "S")
    }

    var body: some View {
        if isFirstTimeUser {
            firstTimeStreakEmptyState
        } else {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .center, spacing: 6) {
                    Image("streak")
                        .resizable()
                        .renderingMode(.original)
                        .scaledToFit()
                        .frame(width: 28, height: 28)
                        .accessibilityHidden(true)

                    Text(streakWeeksTitle)
                        .font(.system(size: 23, weight: .bold))
                        .foregroundColor(AppConstants.TrakkitHome.heading)

                    Spacer(minLength: 6)

                    if isOnFire {
                        Text("ON FIRE")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(AppConstants.TrakkitHome.onFireText)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(AppConstants.TrakkitHome.onFireBackground)
                            .clipShape(Capsule())
                    }
                }

                Text(personalBestWeeksLine)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(AppConstants.TrakkitHome.secondaryText)
                    .tracking(0.45)

                HStack(alignment: .center, spacing: 0) {
                    HStack(spacing: 3) {
                        ForEach(calendarWeekSlots) { slot in
                            dayChipSlot(slot)
                        }
                    }
                    .layoutPriority(-1)

                    Spacer(minLength: 6)

                    Button(action: onViewCalendar) {
                        HStack(spacing: 3) {
                            Text("VIEW CALENDAR")
                                .font(.system(size: 11, weight: .bold))
                                .lineLimit(1)
                                .minimumScaleFactor(0.82)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 9, weight: .bold))
                        }
                        .foregroundColor(AppConstants.TrakkitHome.accentOrange)
                    }
                    .buttonStyle(.plain)
                    .layoutPriority(1)
                    .accessibilityLabel("View calendar")
                }
            }
            .padding(18)
            .background {
                ZStack {
                    Color.white
                    RadialGradient(
                        colors: [
                            AppConstants.TrakkitHome.accentOrange.opacity(0.2),
                            Color.clear
                        ],
                        center: UnitPoint(x: 0.12, y: 1.05),
                        startRadius: 4,
                        endRadius: 140
                    )
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: AppConstants.TrakkitHome.cardCornerRadius, style: .continuous))
            .shadow(
                color: AppConstants.TrakkitHome.cardShadowColor,
                radius: AppConstants.TrakkitHome.cardShadowRadius,
                x: 0,
                y: AppConstants.TrakkitHome.cardShadowY
            )
            .padding(.horizontal, 20)
        }
    }
    
    private var firstTimeStreakEmptyState: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Text("🔥")
                    .font(.system(size: 22))
                Text("No streaks")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(AppConstants.TrakkitHome.heading)
            }

            Text("Start your first session to begin your streak")
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(AppConstants.TrakkitHome.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: AppConstants.TrakkitHome.cardCornerRadius, style: .continuous)
                .stroke(Color(hex: "#F1DCC7"), style: StrokeStyle(lineWidth: 1, dash: [5, 4]))
        )
        .clipShape(RoundedRectangle(cornerRadius: AppConstants.TrakkitHome.cardCornerRadius, style: .continuous))
        .shadow(
            color: AppConstants.TrakkitHome.cardShadowColor,
            radius: AppConstants.TrakkitHome.cardShadowRadius,
            x: 0,
            y: AppConstants.TrakkitHome.cardShadowY
        )
        .padding(.horizontal, 20)
    }

    private func dayChipSlot(_ slot: StreakCalendarDaySlot) -> some View {
        let isToday = slot.isToday
        return Text(slot.label)
            .font(.system(size: 11, weight: .bold))
            .foregroundColor(dayChipTextColor(isToday: isToday, completed: slot.isCompleted))
            .frame(width: 26, height: 26)
            .background(dayChipBackground(isToday: isToday, completed: slot.isCompleted))
            .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
            .shadow(
                color: isToday ? AppConstants.TrakkitHome.accentOrange.opacity(0.5) : .clear,
                radius: 8,
                x: 0,
                y: 3
            )
            .accessibilityLabel("\(slot.label) \(slot.isCompleted ? "completed" : "not completed")\(isToday ? ", today" : "")")
    }

    private func dayChipBackground(isToday: Bool, completed: Bool) -> Color {
        if isToday {
            return AppConstants.TrakkitHome.accentOrange
        }
        if completed {
            return AppConstants.TrakkitHome.streakDayCompletedBackground
        }
        return AppConstants.TrakkitHome.streakDayInactiveBackground
    }

    private func dayChipTextColor(isToday: Bool, completed: Bool) -> Color {
        if isToday {
            return .white
        }
        if completed {
            return AppConstants.TrakkitHome.streakDayCompletedText
        }
        return AppConstants.TrakkitHome.streakDayInactiveText
    }
}

#Preview {
    StreakCardView(
        streakData: DashboardViewModel2.generateMockStreakData(),
        personalBest: 8,
        isFirstTimeUser: false,
        onViewCalendar: {}
    )
    .background(AppConstants.TrakkitHome.background)
    .previewLayout(.sizeThatFits)
}
