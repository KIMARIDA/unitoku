import SwiftUI

// 수업 등록/편집 폼 뷰
struct CourseFormView: View {
    @Binding var course: Course
    let viewModel: TimeTableViewModel
    let isEditing: Bool
    let onSave: (Bool) -> Void
    
    @Environment(\.presentationMode) var presentationMode
    @State private var name: String = ""
    @State private var professor: String = ""
    @State private var room: String = ""
    @State private var colorIndex: Int = 0
    @State private var weekday: Weekday = .monday
    @State private var period: Period = .first
    
    init(course: Binding<Course>, viewModel: TimeTableViewModel, isEditing: Bool, onSave: @escaping (Bool) -> Void = {_ in}) {
        self._course = course
        self.viewModel = viewModel
        self.isEditing = isEditing
        self.onSave = onSave
        
        self._name = State(initialValue: course.wrappedValue.name)
        self._professor = State(initialValue: course.wrappedValue.professor)
        self._room = State(initialValue: course.wrappedValue.room)
        self._colorIndex = State(initialValue: course.wrappedValue.colorIndex)
        self._weekday = State(initialValue: course.wrappedValue.weekday)
        self._period = State(initialValue: course.wrappedValue.period)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("授業情報")) {
                    TextField("授業名", text: $name)
                    TextField("教授名", text: $professor)
                    TextField("教室", text: $room)
                    
                    Picker("曜日", selection: $weekday) {
                        ForEach(Weekday.allCases, id: \.self) { day in
                            Text(day.fullName).tag(day)
                        }
                    }
                    
                    Picker("時限", selection: $period) {
                        ForEach(Period.allCases, id: \.self) { period in
                            Text("\(period.rawValue)限 (\(period.timeRange))").tag(period)
                        }
                    }
                    
                    Picker("色", selection: $colorIndex) {
                        ForEach(Course.colors.indices, id: \.self) { index in
                            HStack {
                                Circle()
                                    .fill(Course.colors[index])
                                    .frame(width: 20, height: 20)
                                Text("色 \(index + 1)")
                            }.tag(index)
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? "授業編集" : "新規授業")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveCourse()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
    
    private func saveCourse() {
        course.name = name
        course.professor = professor
        course.room = room
        course.colorIndex = colorIndex
        course.weekday = weekday
        course.period = period
        
        if isEditing {
            viewModel.updateCourse(course)
        } else {
            viewModel.addCourse(course)
        }
        
        onSave(true)
        presentationMode.wrappedValue.dismiss()
    }
}

// 수업 상세 뷰
struct CourseDetailView: View {
    let course: Course
    let viewModel: TimeTableViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var showingEditSheet = false
    @State private var editingCourse: Course
    
    init(course: Course, viewModel: TimeTableViewModel) {
        self.course = course
        self.viewModel = viewModel
        self._editingCourse = State(initialValue: course)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 수업 정보 헤더
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Circle()
                            .fill(course.color)
                            .frame(width: 40, height: 40)
                        
                        VStack(alignment: .leading) {
                            Text(course.name)
                                .font(.title2)
                                .fontWeight(.bold)
                            Text(course.professor)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    
                    // 수업 시간 및 장소
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundColor(.blue)
                            Text("\(course.weekday.shortName) \(course.period.rawValue)限")
                        }
                        
                        HStack {
                            Image(systemName: "location")
                                .foregroundColor(.green)
                            Text(course.room.isEmpty ? "교실 미정" : course.room)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle("수업 상세")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("편집") {
                    editingCourse = course
                    showingEditSheet = true
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            CourseFormView(
                course: $editingCourse,
                viewModel: viewModel,
                isEditing: true
            ) { success in
                if success {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }
}

#Preview {
    NavigationView {
        CourseDetailView(
            course: Course.samples[0],
            viewModel: TimeTableViewModel()
        )
    }
}
