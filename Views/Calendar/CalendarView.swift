import SwiftUI

// Calendar — Trakkit
// Figma: day https://www.figma.com/design/cvRZan7u5L3sHIV727t1f1/Trakkit?node-id=670-246
// week https://www.figma.com/design/cvRZan7u5L3sHIV727t1f1/Trakkit?node-id=672-773
// month https://www.figma.com/design/cvRZan7u5L3sHIV727t1f1/Trakkit?node-id=674-1336

struct CalendarView: View {
    @StateObject private var viewModel: CalendarViewModel
    @StateObject private var planViewModel = WorkoutPlanViewModel()
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var selectedDay: WorkoutDay?
    
    private let background = AppConstants.TrakkitHome.background
    private let primaryOrange = Color(hex: "#FF9500")
    private let cardRadius: CGFloat = 20
    private let dayNavPillBackground = Color(hex: "#FFF5EB")
    /// Week header: forward chevron — slightly warmer than back (Figma week section).
    private let weekNavPillForward = Color(hex: "#FFE8D4")
    private let dayWorkoutPeach = Color(hex: "#FFF5EB")
    private let weekRowBorderIdle = Color(hex: "#E8E8E8")
    /// Month grid weekday labels (Figma).
    private let monthWeekdayLabelColor = Color(hex: "#9A6B2A")
    /// Session strip at bottom of month card (light peach).
    private let monthSessionCardFill = Color(hex: "#FFF8F4")
    /// Activity dot: workout day.
    private let monthDotWorkout = Color(hex: "#7C3AED")
    /// Activity dot: rest / recovery.
    private let monthDotRest = Color(hex: "#A67C52")
    /// Achievements (Figma): bronze / brown text hierarchy
    private let achievementHeaderBronze = Color(hex: "#8B5A2B")
    private let achievementTitleBrown = Color(hex: "#3D2B1F")
    private let achievementSubMauve = Color(hex: "#8A7A6E")
    
    init(userId: String? = nil) {
        _viewModel = StateObject(wrappedValue: CalendarViewModel(userId: userId))
    }
    
    var body: some View {
        ZStack {
            background.ignoresSafeArea()
            
            if viewModel.isLoading && viewModel.currentPlan == nil {
                loadingView
            } else if let err = viewModel.errorMessage, !viewModel.isLoading, viewModel.currentPlan == nil {
                LoadFailureFallbackView(
                    message: err,
                    onRetry: {
                        Task {
                            await viewModel.fetchUserPlan()
                            await viewModel.loadUserWorkoutCache()
                            viewModel.refreshPersonalBestIfNeeded()
                        }
                    },
                    onGoBack: nil
                )
            } else if viewModel.currentPlan != nil {
                mainScrollContent
            } else {
                emptyStateView
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            if viewModel.userId == nil {
                viewModel.userId = authViewModel.currentUser?.id
            }
        }
        .task(id: viewModel.userId) {
            guard viewModel.userId != nil else { return }
            if viewModel.currentPlan == nil {
                await viewModel.fetchUserPlan()
            }
            await viewModel.loadUserWorkoutCache()
            viewModel.refreshPersonalBestIfNeeded()
        }
        .sheet(item: $selectedDay) { day in
            if day.isRestDay {
                RestDaySheet(day: day)
            } else if let workoutId = day.workoutId {
                WorkoutDetailSheet(
                    workoutId: workoutId,
                    dayId: day.id,
                    viewModel: planViewModel
                )
            }
        }
    }
    
    // MARK: - Main scroll
    
    private var mainScrollContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                topHeader
                
                streakCardView
                
                displayModePicker
                
                Group {
                    switch viewModel.displayMode {
                    case .day:
                        daySection
                    case .week:
                        weekSection
                    case .month:
                        monthSection
                    }
                }
                .padding(.horizontal, 20)
                
                achievementsBlock
                
                recoveryTipCard
            }
            .padding(.top, 8)
            .padding(.bottom, 100)
        }
    }
    
    // MARK: - Header
    
    private var topHeader: some View {
        HStack {
            Button {
                NotificationCenter.default.post(name: NSNotification.Name("NavigateToHome"), object: nil)
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Back")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(AppConstants.TrakkitHome.heading)
            }
            Spacer()
            Text("Calendar")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(AppConstants.TrakkitHome.heading)
            Spacer()
            Color.clear.frame(width: 56, height: 1)
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Streak card (aligned with home `StreakCardView`; no “View calendar” on this tab)
    
    private var isStreakOnFire: Bool {
        viewModel.calculateCurrentStreak() >= 5
    }
    
    private var streakCardView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 10) {
                Image("streak")
                    .resizable()
                    .renderingMode(.original)
                    .scaledToFit()
                    .frame(width: 32, height: 32)
                    .accessibilityHidden(true)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(streakWeeksTitle)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(AppConstants.TrakkitHome.heading)
                    Text("PERSONAL BEST: \(viewModel.personalBestStreakWeeks) WEEKS")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(AppConstants.TrakkitHome.secondaryText)
                        .tracking(0.45)
                }
                
                Spacer(minLength: 8)
                
                if isStreakOnFire {
                    Text("ON FIRE")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(AppConstants.TrakkitHome.onFireText)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(AppConstants.TrakkitHome.onFireBackground)
                        .clipShape(Capsule())
                }
            }
            
            HStack(spacing: 3) {
                let letters = ["M", "T", "W", "T", "F"]
                let dates = viewModel.mondayThroughFridayDates(containing: viewModel.selectedDate)
                ForEach(Array(zip(letters, dates).enumerated()), id: \.offset) { _, pair in
                    let (letter, date) = pair
                    calendarStreakPill(letter: letter, date: date)
                }
            }
        }
        .padding(18)
        .background {
            ZStack {
                Color.white
                RadialGradient(
                    colors: [
                        AppConstants.TrakkitHome.accentOrange.opacity(0.18),
                        Color.clear
                    ],
                    center: UnitPoint(x: 0.1, y: 0.15),
                    startRadius: 2,
                    endRadius: 120
                )
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: cardRadius, style: .continuous))
        .shadow(color: AppConstants.TrakkitHome.cardShadowColor, radius: 12, x: 0, y: 4)
        .padding(.horizontal, 20)
    }
    
    private var streakWeeksTitle: String {
        let w = viewModel.currentStreakWeeks
        if w == 0 { return "0 Weeks" }
        return "\(w) Week" + (w == 1 ? "" : "s")
    }
    
    private func calendarStreakPill(letter: String, date: Date) -> some View {
        let cal = Calendar.current
        let isToday = cal.isDateInToday(date)
        let completed = viewModel.isStripDayCompleted(date)
        return Text(letter)
            .font(.system(size: 11, weight: .bold))
            .foregroundColor(
                calStreakPillText(isToday: isToday, completed: completed)
            )
            .frame(width: 26, height: 26)
            .background(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(calStreakPillBackground(isToday: isToday, completed: completed))
            )
            .shadow(
                color: isToday ? AppConstants.TrakkitHome.accentOrange.opacity(0.45) : .clear,
                radius: 8,
                x: 0,
                y: 3
            )
    }
    
    private func calStreakPillBackground(isToday: Bool, completed: Bool) -> Color {
        if isToday {
            return AppConstants.TrakkitHome.accentOrange
        }
        if completed {
            return AppConstants.TrakkitHome.streakDayCompletedBackground
        }
        return AppConstants.TrakkitHome.streakDayInactiveBackground
    }
    
    private func calStreakPillText(isToday: Bool, completed: Bool) -> Color {
        if isToday {
            return .white
        }
        if completed {
            return AppConstants.TrakkitHome.streakDayCompletedText
        }
        return AppConstants.TrakkitHome.streakDayInactiveText
    }
    
    // MARK: - Mode picker
    
    private var displayModePicker: some View {
        HStack(spacing: 0) {
            ForEach(CalendarDisplayMode.allCases) { mode in
                let on = viewModel.displayMode == mode
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                        viewModel.displayMode = mode
                        viewModel.syncMonthWithSelectedForPicker()
                    }
                } label: {
                    Text(mode.rawValue)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(on ? .white : AppConstants.TrakkitHome.secondaryText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(on ? Color.black : Color.clear)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Color.white)
        .clipShape(Capsule())
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        .padding(.horizontal, 20)
    }
    
    private var monthYearTitle: String {
        let d = viewModel.displayMode == .month ? viewModel.currentMonth : viewModel.selectedDate
        let f = DateFormatter()
        f.dateFormat = "MMMM, yyyy"
        return f.string(from: d)
    }
    
    // MARK: - Day mode (date header + workout in one card — Figma)
    
    private var daySection: some View {
        VStack(alignment: .leading, spacing: 18) {
            dayModeDateHeader
            if let day = dayForSelected {
                dayWorkoutHeroCard(day: day)
            } else {
                noScheduleCard
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: cardRadius, style: .continuous))
        .shadow(color: AppConstants.TrakkitHome.cardShadowColor, radius: 12, x: 0, y: 4)
    }
    
    private var dayModeDateHeader: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(dayModeMonthYearString)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(AppConstants.TrakkitHome.heading)
                Text(weekdayLongDayNumber)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(AppConstants.TrakkitHome.heading)
            }
            Spacer(minLength: 8)
            HStack(spacing: 10) {
                dayNavPillButton(systemName: "chevron.left") {
                    viewModel.stepPeriodBack()
                }
                dayNavPillButton(systemName: "chevron.right") {
                    viewModel.stepPeriodForward()
                }
            }
        }
    }
    
    /// e.g. "April, 2026"
    private var dayModeMonthYearString: String {
        let f = DateFormatter()
        f.dateFormat = "MMMM, yyyy"
        return f.string(from: viewModel.selectedDate)
    }
    
    private var weekdayLongDayNumber: String {
        let f = DateFormatter()
        f.dateFormat = "EEEE, d"
        return f.string(from: viewModel.selectedDate)
    }
    
    private func dayNavPillButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: {
            action()
            HapticFeedback.impact()
        }) {
            Image(systemName: systemName)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(AppConstants.TrakkitHome.heading)
                .frame(width: 44, height: 44)
                .background(dayNavPillBackground)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Week mode (Figma: Mon–Fri list, card, peach nav, active row = orange)
    
    private var weekSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            monthYearNavHeader
            
            let weekdays = viewModel.mondayThroughFridayDates(containing: viewModel.selectedDate)
            VStack(spacing: 12) {
                ForEach(weekdays, id: \.timeIntervalSince1970) { date in
                    weekRow(date: date)
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: cardRadius, style: .continuous))
        .shadow(color: AppConstants.TrakkitHome.cardShadowColor, radius: 12, x: 0, y: 4)
    }
    
    /// Bold month title + peach chevrons (week + month).
    private var monthYearNavHeader: some View {
        HStack(alignment: .center, spacing: 12) {
            Text(monthYearTitle)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(AppConstants.TrakkitHome.heading)
            Spacer(minLength: 8)
            HStack(spacing: 10) {
                weekNavPillButton(systemName: "chevron.left", background: dayNavPillBackground) {
                    viewModel.stepPeriodBack()
                }
                weekNavPillButton(systemName: "chevron.right", background: weekNavPillForward) {
                    viewModel.stepPeriodForward()
                }
            }
        }
    }
    
    private func weekNavPillButton(systemName: String, background: Color, action: @escaping () -> Void) -> some View {
        Button(action: {
            action()
            HapticFeedback.impact()
        }) {
            Image(systemName: systemName)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(AppConstants.TrakkitHome.heading)
                .frame(width: 44, height: 44)
                .background(background)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }
    
    private func weekRow(date: Date) -> some View {
        let day = viewModel.getWorkoutForDate(date)
        let cal = Calendar.current
        let isSel = cal.isDate(date, inSameDayAs: viewModel.selectedDate)
        let hasStartableWorkout = day.map { !$0.isRestDay && $0.workoutId != nil } ?? false
        let isActiveRow = isSel && hasStartableWorkout
        
        return HStack(alignment: .center, spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                Text(weekRowWeekdayAbbrev(date))
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Color(hex: "#9E9E9E"))
                Text(weekRowDayNumber(date))
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(AppConstants.TrakkitHome.heading)
            }
            .frame(width: 40, alignment: .leading)
            
            VStack(alignment: .leading, spacing: 4) {
                if let d = day {
                    Text(viewModel.displayTitle(for: d))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(AppConstants.TrakkitHome.heading)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    if d.isRestDay {
                        Text("Recovery")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(AppConstants.TrakkitHome.secondaryText)
                    } else {
                        weekRowSubline(for: d)
                    }
                } else {
                    Text("No schedule available")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(Color(hex: "#6B6B6B"))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            if isActiveRow, let d = day {
                weekStartPillButton { selectedDay = d }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white)
                .shadow(
                    color: isActiveRow ? primaryOrange.opacity(0.18) : Color.black.opacity(0.04),
                    radius: isActiveRow ? 12 : 5,
                    x: 0,
                    y: isActiveRow ? 3 : 2
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(
                    isActiveRow ? primaryOrange.opacity(0.55) : weekRowBorderIdle,
                    lineWidth: isActiveRow ? 1.5 : 1
                )
        )
        .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .onTapGesture {
            viewModel.selectedDate = date
        }
    }
    
    private func weekRowWeekdayAbbrev(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "EEE"
        return f.string(from: date).uppercased()
    }
    
    private func weekRowDayNumber(_ date: Date) -> String {
        String(Calendar.current.component(.day, from: date))
    }
    
    private func weekRowSubline(for day: WorkoutDay) -> some View {
        Text("\(viewModel.displayDurationMinutes(for: day)) Minutes • \(viewModel.displayCategoryLabel(for: day))")
            .font(.system(size: 13, weight: .regular))
            .foregroundColor(AppConstants.TrakkitHome.secondaryText)
    }
    
    private func weekStartPillButton(action: @escaping () -> Void) -> some View {
        Button(action: {
            HapticFeedback.impact()
            action()
        }) {
            Text("Start")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(primaryOrange)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Month mode (Figma: single card, SUN–SAT, square selection, dots, session strip)
    
    private var monthSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            monthYearNavHeader
            
            monthGrid
                .padding(.top, 18)
            
            if let d = dayForSelected {
                monthModeSessionCard(day: d)
                    .padding(.top, 20)
            } else {
                monthNoScheduleStrip
                    .padding(.top, 20)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: cardRadius, style: .continuous))
        .shadow(color: AppConstants.TrakkitHome.cardShadowColor, radius: 12, x: 0, y: 4)
    }
    
    private var monthGrid: some View {
        let cells = monthGridCells(for: viewModel.currentMonth)
        return VStack(spacing: 12) {
            HStack(spacing: 0) {
                ForEach(monthWeekdaySymbols(), id: \.self) { sym in
                    Text(sym)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(monthWeekdayLabelColor)
                        .frame(maxWidth: .infinity)
                }
            }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 7), spacing: 10) {
                ForEach(cells) { cell in
                    monthGridDayCell(cell: cell)
                }
            }
        }
    }
    
    private func monthWeekdaySymbols() -> [String] {
        let cal = Calendar.current
        let syms = cal.shortWeekdaySymbols // Sun…Sat in current locale
        return syms.map { $0.uppercased() }
    }
    
    private struct MonthGridCell: Identifiable {
        let id: String
        let date: Date
        let isInDisplayedMonth: Bool
        let dayNumber: Int
    }
    
    private func monthGridCells(for monthAnchor: Date) -> [MonthGridCell] {
        let cal = Calendar.current
        guard let monthStart = cal.date(from: cal.dateComponents([.year, .month], from: monthAnchor)),
              let monthEnd = cal.date(byAdding: DateComponents(month: 1, day: -1), to: monthStart)
        else { return [] }
        let daysInMonth = cal.component(.day, from: monthEnd)
        let firstWeekday = cal.component(.weekday, from: monthStart)
        let pad = (firstWeekday - 1 + 7) % 7
        
        var cells: [MonthGridCell] = []
        for i in 0..<pad {
            guard let d = cal.date(byAdding: .day, value: -(pad - i), to: monthStart) else { continue }
            let dn = cal.component(.day, from: d)
            cells.append(MonthGridCell(
                id: "p-\(d.timeIntervalSince1970)",
                date: d,
                isInDisplayedMonth: false,
                dayNumber: dn
            ))
        }
        for dayN in 1...daysInMonth {
            guard let d = cal.date(byAdding: .day, value: dayN - 1, to: monthStart) else { continue }
            cells.append(MonthGridCell(
                id: "c-\(d.timeIntervalSince1970)",
                date: d,
                isInDisplayedMonth: true,
                dayNumber: dayN
            ))
        }
        let endPad = (7 - (cells.count % 7)) % 7
        if endPad > 0, let nextStart = cal.date(byAdding: .day, value: 1, to: monthEnd) {
            for j in 0..<endPad {
                guard let d = cal.date(byAdding: .day, value: j, to: nextStart) else { break }
                let dn = cal.component(.day, from: d)
                cells.append(MonthGridCell(
                    id: "n-\(d.timeIntervalSince1970)",
                    date: d,
                    isInDisplayedMonth: false,
                    dayNumber: dn
                ))
            }
        }
        return cells
    }
    
    private func monthGridDayCell(cell: MonthGridCell) -> some View {
        let cal = Calendar.current
        let date = cell.date
        let sel = cal.isDate(date, inSameDayAs: viewModel.selectedDate)
        let today = cal.isDateInToday(date)
        let outside = !cell.isInDisplayedMonth
        let dotColor = monthActivityDotColor(for: date)
        
        return Button {
            viewModel.selectedDate = date
            viewModel.currentMonth = cal.date(from: cal.dateComponents([.year, .month], from: date))!
            HapticFeedback.impact()
        } label: {
            VStack(spacing: 4) {
                ZStack {
                    if sel {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(primaryOrange)
                            .frame(width: 38, height: 38)
                            .shadow(color: primaryOrange.opacity(0.35), radius: 6, x: 0, y: 3)
                    } else if today {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(primaryOrange, lineWidth: 1.5)
                            .frame(width: 38, height: 38)
                    }
                    Text("\(cell.dayNumber)")
                        .font(.system(size: 15, weight: sel ? .bold : .medium))
                        .foregroundColor(
                            sel ? .white : (outside ? Color(hex: "#C8C8C8") : (today ? primaryOrange : AppConstants.TrakkitHome.heading))
                        )
                }
                .frame(height: 38)
                if let c = dotColor {
                    Circle()
                        .fill(c)
                        .frame(width: 5, height: 5)
                } else {
                    Color.clear.frame(width: 5, height: 5)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 52)
        }
        .buttonStyle(.plain)
    }
    
    private func monthActivityDotColor(for date: Date) -> Color? {
        guard let wd = viewModel.getWorkoutForDate(date) else { return nil }
        return wd.isRestDay ? monthDotRest : monthDotWorkout
    }
    
    private func monthModeSessionCard(day: WorkoutDay) -> some View {
        let d = viewModel.selectedDate
        return HStack(alignment: .center, spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                Text(weekRowWeekdayAbbrev(d))
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Color(hex: "#9E9E9E"))
                Text(weekRowDayNumber(d))
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(AppConstants.TrakkitHome.heading)
            }
            .frame(width: 40, alignment: .leading)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.displayTitle(for: day))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(AppConstants.TrakkitHome.heading)
                    .multilineTextAlignment(.leading)
                if day.isRestDay {
                    Text("Recovery")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(AppConstants.TrakkitHome.secondaryText)
                } else {
                    weekRowSubline(for: day)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            if !day.isRestDay, day.workoutId != nil {
                weekStartPillButton { selectedDay = day }
            }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(monthSessionCardFill)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.black.opacity(0.05), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 4)
    }
    
    private var monthNoScheduleStrip: some View {
        Text("No schedule available for this day.")
            .font(.system(size: 15, weight: .medium))
            .foregroundColor(AppConstants.TrakkitHome.secondaryText)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            .background(monthSessionCardFill)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.black.opacity(0.05), lineWidth: 1)
            )
    }
    
    // MARK: - Workout cards
    
    private var dayForSelected: WorkoutDay? {
        viewModel.getWorkoutForDate(viewModel.selectedDate)
    }
    
    private func dayWorkoutHeroCard(day: WorkoutDay) -> some View {
        HStack(alignment: .center, spacing: 14) {
            VStack(alignment: .leading, spacing: 8) {
                Text(viewModel.displayTitle(for: day))
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(AppConstants.TrakkitHome.heading)
                if day.isRestDay {
                    HStack(spacing: 6) {
                        Image(systemName: "moon.zzz.fill")
                            .font(.system(size: 13))
                        Text("Recovery")
                            .font(.system(size: 14, weight: .regular))
                    }
                    .foregroundColor(AppConstants.TrakkitHome.secondaryText)
                } else {
                    HStack(spacing: 6) {
                        Image(systemName: "stopwatch")
                            .font(.system(size: 13, weight: .medium))
                        Text("\(viewModel.displayDurationMinutes(for: day)) Minutes • \(viewModel.displayCategoryLabel(for: day))")
                            .font(.system(size: 14, weight: .regular))
                    }
                    .foregroundColor(AppConstants.TrakkitHome.secondaryText)
                }
            }
            if !day.isRestDay, day.workoutId != nil {
                Spacer(minLength: 8)
                startSquareButton { selectedDay = day }
                    .frame(width: 72, height: 72)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            Group {
                if day.isRestDay {
                    Color(hex: "#F0F4F8")
                } else {
                    LinearGradient(
                        colors: [dayWorkoutPeach, Color.white],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                }
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(
                    day.isRestDay ? Color.clear : Color.black.opacity(0.06),
                    lineWidth: day.isRestDay ? 0 : 1
                )
        )
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
    }
    
    private var noScheduleCard: some View {
        Text("No schedule available for this day.")
            .font(.system(size: 15, weight: .medium))
            .foregroundColor(AppConstants.TrakkitHome.secondaryText)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
    
    private func startSquareButton(action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text("Start")
                .font(.system(size: 14, weight: .heavy))
                .foregroundColor(.white)
                .frame(width: 72, height: 72)
                .background(primaryOrange)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: primaryOrange.opacity(0.35), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }
    
    private func subline(for day: WorkoutDay) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "clock")
                .font(.system(size: 12))
            Text("\(viewModel.displayDurationMinutes(for: day)) Minutes • \(viewModel.displayCategoryLabel(for: day))")
                .font(.system(size: 13))
        }
        .foregroundColor(AppConstants.TrakkitHome.secondaryText)
    }
    
    // MARK: - Achievements
    
    private var achievementsBlock: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center) {
                Text("Achievements")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(AppConstants.TrakkitHome.heading)
                Spacer()
                Button { } label: {
                    Text("View All")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(achievementHeaderBronze)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            
            HStack(alignment: .top, spacing: 12) {
                achievementPill(
                    title: "5–Day Streak",
                    sub: "Earned Apr 12",
                    systemImage: "flame.fill",
                    iconGradient: LinearGradient(
                        colors: [Color(hex: "#FF7A1A"), Color(hex: "#FFD35C")],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                achievementPill(
                    title: "Early Bird",
                    sub: "Earned Apr 08",
                    systemImage: "sun.max.fill",
                    iconGradient: LinearGradient(
                        colors: [Color(hex: "#6B3FD4"), Color(hex: "#C4A8F5")],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
            .padding(.horizontal, 20)
        }
    }
    
    private func achievementPill(title: String, sub: String, systemImage: String, iconGradient: LinearGradient) -> some View {
        VStack(alignment: .center, spacing: 10) {
            ZStack {
                Circle()
                    .fill(iconGradient)
                    .frame(width: 56, height: 56)
                Image(systemName: systemImage)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.white)
            }
            Text(title)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(achievementTitleBrown)
                .multilineTextAlignment(.center)
            Text(sub)
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(achievementSubMauve)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 10)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Recovery tip
    
    private var recoveryTipCard: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(AppConstants.TrakkitAI.iconBox)
                    .frame(width: 44, height: 44)
                    .shadow(
                        color: AppConstants.TrakkitAI.iconBox.opacity(0.35),
                        radius: 5,
                        x: 0,
                        y: 3
                    )
                Image("generate")
                    .resizable()
                    .renderingMode(.template)
                    .foregroundColor(.white)
                    .scaledToFit()
                    .frame(width: 24, height: 24)
            }
            VStack(alignment: .leading, spacing: 6) {
                Text("Recovery Tip")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(AppConstants.TrakkitAI.title)
                Text("You have been working consistently for 15 days straight. I would suggest you take a recovery day to prevent any unforeseen injuries.")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(AppConstants.TrakkitAI.body)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            ZStack {
                AppConstants.TrakkitAI.cardFill
                RadialGradient(
                    colors: [AppConstants.TrakkitAI.glowTopTrailing, Color.clear],
                    center: .topTrailing,
                    startRadius: 8,
                    endRadius: 180
                )
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(AppConstants.TrakkitAI.cardBorder, lineWidth: 1)
        )
        .padding(.horizontal, 20)
    }
    
    // MARK: - Empty & loading
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            topHeader
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 48))
                .foregroundColor(AppConstants.TrakkitHome.secondaryText.opacity(0.4))
            Text("No Workout Plan")
                .font(.system(size: 22, weight: .bold))
            Text("Create a workout plan to see your schedule here.")
                .font(.system(size: 15))
                .foregroundColor(AppConstants.TrakkitHome.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.top, 12)
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Loading calendar…")
                .font(.system(size: 15))
                .foregroundColor(AppConstants.TrakkitHome.secondaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    CalendarView()
        .environmentObject(AuthViewModel())
}
