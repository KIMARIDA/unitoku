import SwiftUI

struct TimeTableView: View {
    @StateObject private var viewModel = TimeTableViewModel()
    @State private var showingAddCourse = false
    @State private var selectedDay: Weekday = Weekday.fromDate(Date())
    
    // Time range for the timetable (8 AM to 8 PM)
    private let timeRange = 8..<20
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Weekday selector
                ScrollViewReader { scrollProxy in
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 0) {
                            ForEach(Weekday.allCases, id: \.rawValue) { day in
                                DayHeaderView(day: day, isSelected: day == selectedDay)
                                    .frame(width: 70)
                                    .onTapGesture {
                                        withAnimation {
                                            selectedDay = day
                                        }
                                    }
                                    .id(day)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    .onAppear {
                        scrollProxy.scrollTo(selectedDay, anchor: .center)
                    }
                }
                .background(Color(.systemBackground).shadow(color: Color.black.opacity(0.1), radius: 2, y: 2))
                
                // Time table content
                ScrollView {
                    ZStack(alignment: .topLeading) {
                        // Time guide lines
                        VStack(spacing: 0) {
                            ForEach(timeRange, id: \.self) { hour in
                                HStack {
                                    Text("\(hour):00")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                        .frame(width: 40, alignment: .trailing)
                                    
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(height: 1)
                                }
                                .frame(height: 60, alignment: .top)
                            }
                        }
                        
                        // Course blocks
                        ZStack {
                            ForEach(viewModel.coursesForWeekday(selectedDay)) { course in
                                CourseBlockView(course: course)
                                    .position(positionForCourse(course))
                            }
                        }
                        .padding(.leading, 40)
                    }
                    .padding(.bottom, 20)
                    .frame(minHeight: 720) // Make sure we have enough space to show all hours
                }
                
                // Course list for the selected day
                List {
                    Section(header: Text("\(selectedDay.fullName) 강의")) {
                        if viewModel.coursesForWeekday(selectedDay).isEmpty {
                            Text("등록된 강의가 없습니다")
                                .foregroundColor(.gray)
                                .italic()
                        } else {
                            ForEach(viewModel.coursesForWeekday(selectedDay)) { course in
                                VStack(alignment: .leading) {
                                    Text(course.name)
                                        .font(.headline)
                                    
                                    HStack {
                                        Text(course.professor)
                                            .font(.subheadline)
                                        Spacer()
                                        Text(course.location)
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                    }
                                    
                                    Text("\(formatTime(course.startTime)) - \(formatTime(course.endTime))")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                .padding(.vertical, 4)
                            }
                            .onDelete(perform: viewModel.deleteCourse)
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
            }
            .navigationTitle("시간표")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddCourse = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddCourse) {
                AddCourseView(viewModel: viewModel)
            }
        }
    }
    
    // Calculate position for course block based on time
    private func positionForCourse(_ course: Course) -> CGPoint {
        let calendar = Calendar.current
        let startHour = calendar.component(.hour, from: course.startTime) 
        let startMinute = calendar.component(.minute, from: course.startTime)
        let endHour = calendar.component(.hour, from: course.endTime)
        let endMinute = calendar.component(.minute, from: course.endTime)
        
        let startY = Double(startHour - timeRange.lowerBound) * 60 + Double(startMinute)
        let endY = Double(endHour - timeRange.lowerBound) * 60 + Double(endMinute)
        let height = endY - startY
        
        return CGPoint(x: UIScreen.main.bounds.width / 2, y: startY + height / 2)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// Day header view component
struct DayHeaderView: View {
    let day: Weekday
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            Text(day.shortName)
                .font(.headline)
                .foregroundColor(isSelected ? .white : .primary)
            
            Text("\(Calendar.current.component(.day, from: getDateForWeekday(day)))")
                .font(.subheadline)
                .foregroundColor(isSelected ? .white : .gray)
        }
        .frame(width: 70, height: 50)
        .background(isSelected ? Color.blue : Color.clear)
        .cornerRadius(8)
    }
    
    // Get date for a weekday in the current week
    private func getDateForWeekday(_ weekday: Weekday) -> Date {
        let today = Date()
        let calendar = Calendar.current
        let todayWeekday = calendar.component(.weekday, from: today)
        let daysToAdd = weekday.rawValue - todayWeekday
        
        return calendar.date(byAdding: .day, value: daysToAdd, to: today) ?? today
    }
}

// Course block view component
struct CourseBlockView: View {
    let course: Course
    
    var body: some View {
        let calendar = Calendar.current
        
        let startHour = calendar.component(.hour, from: course.startTime)
        let startMinute = calendar.component(.minute, from: course.startTime)
        let endHour = calendar.component(.hour, from: course.endTime)
        let endMinute = calendar.component(.minute, from: course.endTime)
        
        let startY = Double(startHour) * 60 + Double(startMinute)
        let endY = Double(endHour) * 60 + Double(endMinute)
        let height = endY - startY
        
        return VStack(alignment: .leading, spacing: 4) {
            Text(course.name)
                .font(.headline)
                .foregroundColor(.white)
                .lineLimit(1)
            
            Text(course.location)
                .font(.caption)
                .foregroundColor(.white.opacity(0.9))
                .lineLimit(1)
            
            Text("\(formatTime(course.startTime)) - \(formatTime(course.endTime))")
                .font(.caption2)
                .foregroundColor(.white.opacity(0.8))
        }
        .padding(8)
        .frame(width: UIScreen.main.bounds.width - 80, height: height)
        .background(course.color.opacity(0.8))
        .cornerRadius(8)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}