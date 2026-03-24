import SwiftUI

struct CalendarView: View {
    @StateObject private var viewModel: CalendarViewModel
    @StateObject private var planViewModel = WorkoutPlanViewModel()
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.colorScheme) var colorScheme
    @State private var selectedDay: WorkoutDay?
    @State private var showWorkoutDetail = false
    
    init(userId: String? = nil) {
        _viewModel = StateObject(wrappedValue: CalendarViewModel(userId: userId))
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color(hex: "#F5F5F7")
                    .ignoresSafeArea()
                
                if viewModel.isLoading && viewModel.currentPlan == nil {
                    loadingView
                } else if let plan = viewModel.currentPlan {
                    calendarContentView(plan: plan)
                } else {
                    emptyStateView
                }
            }
            .navigationTitle("Calendar")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                if viewModel.userId == nil {
                    viewModel.userId = authViewModel.currentUser?.id
                }
                if viewModel.currentPlan == nil && !viewModel.isLoading {
                    Task {
                        await viewModel.fetchUserPlan()
                    }
                }
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
    }
    
    // MARK: - Calendar Content
    
    private func calendarContentView(plan: WorkoutPlan) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                // Streak Summary
                streakSummaryCard
                
                // Week View
                weekView
                
                // Monthly Calendar
                monthlyCalendarView
                
                // Today's Workout
                if let todayWorkout = plan.getWorkoutForToday(), !todayWorkout.isRestDay {
                    todayWorkoutCard(day: todayWorkout)
                        .padding(.horizontal, 20)
                }
            }
            .padding(.vertical, 20)
        }
    }
    
    // MARK: - Streak Summary
    
    private var streakSummaryCard: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "flame.fill")
                    .foregroundColor(Color(hex: "#FF9500"))
                    .font(.system(size: 24))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(viewModel.calculateCurrentStreak())")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text("Day Streak")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: {
                    viewModel.goToToday()
                }) {
                    Text("Today")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(hex: "#FF9500"))
                }
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .padding(.horizontal, 20)
    }
    
    // MARK: - Week View
    
    private var weekView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("This Week")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.primary)
                .padding(.horizontal, 20)
            
            let weekDates = viewModel.getWeekDates(for: Date())
            
            HStack(spacing: 12) {
                ForEach(weekDates, id: \.self) { date in
                    let day = viewModel.getWorkoutForDate(date)
                    let isToday = viewModel.isToday(date)
                    
                    Button(action: {
                        if let day = day {
                            selectedDay = day
                        }
                    }) {
                        VStack(spacing: 8) {
                            Text(dayName(for: date))
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(isToday ? .white : .secondary)
                            
                            if let day = day {
                                if day.isRestDay {
                                    Image(systemName: "moon.zzz.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(isToday ? .white.opacity(0.8) : .secondary.opacity(0.5))
                                } else if day.completed {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(isToday ? .white : Color.green)
                                } else {
                                    Image(systemName: "figure.run")
                                        .font(.system(size: 20))
                                        .foregroundColor(isToday ? .white : Color(hex: "#FF9500"))
                                }
                            } else {
                                Circle()
                                    .fill(Color.clear)
                                    .frame(width: 20, height: 20)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 70)
                        .background(isToday ? Color(hex: "#FF9500") : Color.white)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(isToday ? Color.clear : Color.gray.opacity(0.2), lineWidth: 1)
                        )
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Monthly Calendar
    
    private var monthlyCalendarView: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Month Header
            HStack {
                Button(action: {
                    viewModel.previousMonth()
                }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                Text(monthYearString(for: viewModel.currentMonth))
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: {
                    viewModel.nextMonth()
                }) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.primary)
                }
            }
            .padding(.horizontal, 20)
            
            // Calendar Grid
            let calendar = Calendar.current
            let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: viewModel.currentMonth))!
            let monthEnd = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: monthStart)!
            let daysInMonth = calendar.component(.day, from: monthEnd)
            let firstWeekday = calendar.component(.weekday, from: monthStart)
            let adjustedFirstWeekday = (firstWeekday + 5) % 7 // Convert to 0-based (Sunday = 0)
            
            VStack(spacing: 8) {
                // Day headers
                HStack(spacing: 0) {
                    ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { day in
                        Text(day)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal, 20)
                
                // Calendar days
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                    // Empty cells for days before month starts
                    ForEach(0..<adjustedFirstWeekday, id: \.self) { _ in
                        Color.clear
                            .frame(height: 44)
                    }
                    
                    // Days of the month
                    ForEach(1...daysInMonth, id: \.self) { day in
                        let date = calendar.date(byAdding: .day, value: day - 1, to: monthStart)!
                        let isToday = viewModel.isToday(date)
                        let hasWorkout = viewModel.hasWorkoutOnDate(date)
                        let isCompleted = viewModel.isDateCompleted(date)
                        let isRestDay = viewModel.isDateRestDay(date)
                        
                        Button(action: {
                            if let day = viewModel.getWorkoutForDate(date) {
                                selectedDay = day
                            }
                        }) {
                            ZStack {
                                if isToday {
                                    Circle()
                                        .fill(Color(hex: "#FF9500"))
                                } else if isCompleted {
                                    Circle()
                                        .fill(Color.green.opacity(0.2))
                                } else if isRestDay {
                                    Circle()
                                        .fill(Color.gray.opacity(0.1))
                                }
                                
                                Text("\(day)")
                                    .font(.system(size: 14, weight: isToday ? .bold : .regular))
                                    .foregroundColor(isToday ? .white : (isCompleted ? .green : .primary))
                                
                                if hasWorkout && !isRestDay {
                                    Circle()
                                        .fill(isCompleted ? Color.green : Color(hex: "#FF9500"))
                                        .frame(width: 6, height: 6)
                                        .offset(x: 12, y: -12)
                                }
                            }
                            .frame(height: 44)
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .padding(.vertical, 16)
        .background(Color.white)
        .cornerRadius(16)
        .padding(.horizontal, 20)
    }
    
    // MARK: - Today's Workout Card
    
    private func todayWorkoutCard(day: WorkoutDay) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Today's Workout")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                if day.completed {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            }
            
            if let workoutId = day.workoutId {
                Text("Workout ID: \(workoutId)")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            
            if !day.completed {
                Button(action: {
                    selectedDay = day
                }) {
                    Text("Start Workout")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Color(hex: "#FF9500"))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 60))
                .foregroundColor(.secondary.opacity(0.5))
            
            Text("No Workout Plan")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.primary)
            
            Text("Create a workout plan to see your schedule here.")
                .font(.system(size: 16))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading calendar...")
                .font(.system(size: 16))
                .foregroundColor(.secondary)
                .padding(.top, 16)
        }
    }
    
    // MARK: - Helper Methods
    
    private func dayName(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return String(formatter.string(from: date).prefix(1))
    }
    
    private func monthYearString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }
}

#Preview {
    CalendarView()
        .environmentObject(AuthViewModel())
}
