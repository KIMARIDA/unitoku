// filepath: /Users/junnykim/unitoku/CourseEvaluationView.swift
import SwiftUI

struct CourseEvaluationView: View {
    @StateObject private var viewModel = CourseEvaluationViewModel()
    @State private var showingAddEvaluation = false
    @State private var selectedCourse: Course?
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("수강 강의 평가")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.horizontal)
                    
                    // 최근 평가된 강의
                    VStack(alignment: .leading, spacing: 8) {
                        Text("최근 평가")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(Course.samples) { course in
                                    Button(action: {
                                        selectedCourse = course
                                    }) {
                                        RecentCourseCard(course: course, viewModel: viewModel)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    Divider()
                        .padding(.vertical, 8)
                    
                    // 모든 강의 목록
                    VStack(alignment: .leading, spacing: 8) {
                        Text("전체 강의")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(Course.samples) { course in
                                Button(action: {
                                    selectedCourse = course
                                }) {
                                    CourseCard(course: course, viewModel: viewModel)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("강의평가")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddEvaluation = true
                    }) {
                        Image(systemName: "square.and.pencil")
                    }
                }
            }
            .sheet(item: $selectedCourse) { course in
                CourseEvaluationDetailView(course: course, viewModel: viewModel)
            }
            .sheet(isPresented: $showingAddEvaluation) {
                NewEvaluationView(viewModel: viewModel)
            }
        }
    }
}

// 최근 평가된 강의 카드
struct RecentCourseCard: View {
    let course: Course
    let viewModel: CourseEvaluationViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(course.name)
                    .font(.headline)
                    .foregroundColor(.white)
                    .lineLimit(1)
                Spacer()
            }
            
            Text(course.professor)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.9))
                .lineLimit(1)
            
            Spacer()
            
            HStack {
                if let rating = course.averageRating(viewModel: viewModel) {
                    ForEach(1...5, id: \.self) { index in
                        Image(systemName: index <= Int(rating.rounded()) ? "star.fill" : "star")
                            .foregroundColor(.yellow)
                            .font(.caption)
                    }
                    Text(String(format: "%.1f", rating))
                        .font(.caption)
                        .foregroundColor(.white)
                } else {
                    Text("평가 없음")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
                
                Text("\(viewModel.evaluationsForCourse(course.id).count)개 평가")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .padding()
        .frame(width: 200, height: 120)
        .background(course.color)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

// 모든 강의 카드
struct CourseCard: View {
    let course: Course
    let viewModel: CourseEvaluationViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Circle()
                .fill(course.color)
                .frame(width: 40, height: 40)
                .overlay(
                    Text(String(course.name.prefix(1)))
                        .font(.headline)
                        .foregroundColor(.white)
                )
            
            Text(course.name)
                .font(.headline)
                .lineLimit(1)
            
            Text(course.professor)
                .font(.caption)
                .foregroundColor(.gray)
                .lineLimit(1)
            
            HStack {
                if let rating = course.averageRating(viewModel: viewModel) {
                    ForEach(1...5, id: \.self) { index in
                        Image(systemName: index <= Int(rating.rounded()) ? "star.fill" : "star")
                            .foregroundColor(.yellow)
                            .font(.caption)
                    }
                    Text(String(format: "%.1f", rating))
                        .font(.caption)
                } else {
                    Text("평가 없음")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Text("\(viewModel.evaluationsForCourse(course.id).count)")
                    .font(.caption)
                    .padding(4)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

// 강의 평가 상세 화면
struct CourseEvaluationDetailView: View {
    let course: Course
    let viewModel: CourseEvaluationViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var showingAddEvaluation = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // 강의 정보 헤더
                    VStack(alignment: .leading, spacing: 8) {
                        Text(course.name)
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("\(course.professor) · \(course.room)")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        Text("\(course.weekday.rawValue)요일 \(course.period.timeRange)")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        Divider()
                        
                        // 평균 평점
                        if let rating = course.averageRating(viewModel: viewModel) {
                            HStack(spacing: 8) {
                                Text(String(format: "%.1f", rating))
                                    .font(.title)
                                    .fontWeight(.bold)
                                
                                ForEach(1...5, id: \.self) { index in
                                    Image(systemName: index <= Int(rating.rounded()) ? "star.fill" : "star")
                                        .foregroundColor(.yellow)
                                }
                                
                                Spacer()
                                
                                Text("\(viewModel.evaluationsForCourse(course.id).count)개 평가")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            
                            // 세부 항목 평점
                            VStack(alignment: .leading, spacing: 12) {
                                ScoreBarView(category: .overall, score: averageScore(for: \.overallScore))
                                ScoreBarView(category: .difficulty, score: averageScore(for: \.difficultyScore))
                                ScoreBarView(category: .assignments, score: averageScore(for: \.assignmentsScore))
                                ScoreBarView(category: .teaching, score: averageScore(for: \.teachingScore))
                                ScoreBarView(category: .grading, score: averageScore(for: \.gradingScore))
                            }
                            .padding(.vertical, 8)
                        } else {
                            Text("아직 평가가 없습니다")
                                .font(.headline)
                                .foregroundColor(.gray)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding()
                        }
                        
                        Divider()
                    }
                    .padding()
                    
                    // 평가 목록
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("강의평")
                                .font(.headline)
                            
                            Spacer()
                            
                            Button(action: {
                                showingAddEvaluation = true
                            }) {
                                Label("평가 작성", systemImage: "square.and.pencil")
                                    .font(.subheadline)
                            }
                        }
                        .padding(.horizontal)
                        
                        if viewModel.evaluationsForCourse(course.id).isEmpty {
                            Text("아직 작성된 강의평이 없습니다")
                                .foregroundColor(.gray)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding()
                        } else {
                            ForEach(viewModel.evaluationsForCourse(course.id)) { evaluation in
                                EvaluationCard(evaluation: evaluation, viewModel: viewModel)
                            }
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("닫기") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
            .sheet(isPresented: $showingAddEvaluation) {
                NewEvaluationView(viewModel: viewModel, courseId: course.id)
            }
        }
    }
    
    // 특정 카테고리의 평균 점수 계산 헬퍼 함수
    private func averageScore<T>(for keyPath: KeyPath<CourseEvaluation, T>) -> Double where T: RawRepresentable, T.RawValue == Int {
        let evaluations = viewModel.evaluationsForCourse(course.id)
        if evaluations.isEmpty { return 0 }
        
        let sum = evaluations.reduce(0) { $0 + Double(evaluations[$1][keyPath: keyPath].rawValue) }
        return sum / Double(evaluations.count)
    }
}

// 평가 점수 바 컴포넌트
struct ScoreBarView: View {
    let category: EvaluationCategory
    let score: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(category.rawValue)
                    .font(.subheadline)
                
                Spacer()
                
                Text(String(format: "%.1f", score))
                    .font(.subheadline)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .frame(width: geometry.size.width, height: 8)
                        .opacity(0.1)
                        .foregroundColor(.gray)
                    
                    Rectangle()
                        .frame(width: min(CGFloat(score) / 5.0 * geometry.size.width, geometry.size.width), height: 8)
                        .foregroundColor(scoreColor(score: score))
                }
                .cornerRadius(4)
            }
            .frame(height: 8)
            
            Text(category.description)
                .font(.caption)
                .foregroundColor(.gray)
        }
    }
    
    // 점수에 따른 색상
    private func scoreColor(score: Double) -> Color {
        switch score {
        case 0..<2: return .red
        case 2..<3: return .orange
        case 3..<4: return .yellow
        case 4...5: return .green
        default: return .gray
        }
    }
}

// 개별 평가 카드
struct EvaluationCard: View {
    let evaluation: CourseEvaluation
    let viewModel: CourseEvaluationViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ForEach(1...5, id: \.self) { index in
                    Image(systemName: index <= evaluation.overallScore.rawValue ? "star.fill" : "star")
                        .foregroundColor(.yellow)
                        .font(.caption)
                }
                
                Text(String(format: "%.1f", evaluation.averageScore))
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text(evaluation.semester)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Text(evaluation.comment)
                .font(.body)
                .lineLimit(5)
            
            HStack {
                Text(evaluation.authorName)
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Text("•")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Text(formatDate(evaluation.date))
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Spacer()
                
                Button(action: {
                    viewModel.likeEvaluation(evaluation.id)
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "hand.thumbsup")
                        Text("\(evaluation.likes)")
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        .padding(.horizontal)
    }
    
    // 날짜 포맷 변환 헬퍼
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd"
        return formatter.string(from: date)
    }
}
