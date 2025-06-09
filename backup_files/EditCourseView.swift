import SwiftUI

struct EditCourseView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: TimeTableViewModel
    
    @State private var name: String
    @State private var professor: String
    @State private var location: String
    @State private var startTime: Date
    @State private var endTime: Date
    @State private var selectedColor: Color
    @State private var selectedWeekdays: [Weekday]
    
    private let courseId: UUID
    private let colors: [Color] = [.blue, .green, .orange, .purple, .red, .pink, .yellow]
    
    init(viewModel: TimeTableViewModel, course: Course) {
        self.viewModel = viewModel
        self._name = State(initialValue: course.name)
        self._professor = State(initialValue: course.professor)
        self._location = State(initialValue: course.location)
        self._startTime = State(initialValue: course.startTime)
        self._endTime = State(initialValue: course.endTime)
        self._selectedColor = State(initialValue: course.color)
        self._selectedWeekdays = State(initialValue: course.weekdays)
        self.courseId = course.id
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("강의 정보")) {
                    TextField("강의명", text: $name)
                    TextField("교수명", text: $professor)
                    TextField("강의실", text: $location)
                }
                
                Section(header: Text("시간")) {
                    DatePicker("시작 시간", selection: $startTime, displayedComponents: .hourAndMinute)
                    DatePicker("종료 시간", selection: $endTime, displayedComponents: .hourAndMinute)
                }
                
                Section(header: Text("요일")) {
                    ForEach(Weekday.allCases, id: \.self) { day in
                        Button(action: {
                            if selectedWeekdays.contains(day) {
                                selectedWeekdays.removeAll(where: { $0 == day })
                            } else {
                                selectedWeekdays.append(day)
                            }
                        }) {
                            HStack {
                                Text(day.fullName)
                                Spacer()
                                if selectedWeekdays.contains(day) {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                        .foregroundColor(.primary)
                    }
                }
                
                Section(header: Text("색상")) {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 44))], spacing: 10) {
                        ForEach(colors, id: \.self) { color in
                            Circle()
                                .fill(color)
                                .frame(width: 30, height: 30)
                                .overlay(
                                    Circle()
                                        .stroke(Color.primary, lineWidth: selectedColor == color ? 2 : 0)
                                )
                                .onTapGesture {
                                    selectedColor = color
                                }
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("강의 수정")
            .navigationBarItems(
                leading: Button("취소") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("저장") {
                    saveChanges()
                }
            )
        }
    }
    
    private func saveChanges() {
        let updatedCourse = Course(
            id: courseId,
            name: name,
            professor: professor,
            location: location,
            startTime: startTime,
            endTime: endTime,
            weekdays: selectedWeekdays,
            color: selectedColor
        )
        
        viewModel.editCourse(updatedCourse)
        presentationMode.wrappedValue.dismiss()
    }
}