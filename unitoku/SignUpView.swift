import SwiftUI

struct SignUpView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var studentID = ""
    @State private var department = ""
    @State private var isPasswordVisible = false
    @State private var isConfirmPasswordVisible = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var selectedGrade = "1年生"
    @State private var currentStep = 0
    
    private let grades = ["1年生", "2年生", "3年生", "4年生", "大学院生"]
    private let departments = ["情報理工学部", "経営学部", "国際関係学部", "文学部", "法学部", "産業社会学部", "映像学部", "スポーツ健康科学部", "生命科学部"]
    
    // 단계별 입력 필드 타이틀 - 라벨 제거
    private let stepTitles = [
        "",  // 이름 입력 라벨 제거
        "",  // 학생번호 입력 라벨 제거
        "",  // 학부 선택 라벨 제거
        "",  // 학년 선택 라벨 제거
        "",  // 메일주소 입력 라벨 제거
        "",  // 비밀번호 설정 라벨 제거
        ""   // 비밀번호 확인 라벨 제거
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 25) {
                // ヘッダー - "大学匿名コミュニティに参加しましょう" 문구 제거
                VStack(spacing: 15) {
                    Text("アカウント作成")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(Color.appTheme)
                    
                    // "大学匿名コミュニティに参加しましょう" 문구 제거
                    
                    // 진행 상황 표시기
                    ProgressView(value: Double(currentStep), total: Double(stepTitles.count))
                        .progressViewStyle(LinearProgressViewStyle(tint: Color.appTheme))
                        .padding(.top, 20)
                }
                .padding(.top, 50)
                .padding(.bottom, 40)
                
                // 현재 단계 타이틀 - 표시하지 않음
                // Text(stepTitles[currentStep]) 제거
                
                // 단계별 입력 필드
                VStack(spacing: 20) {
                    // 단계에 따라 적절한 입력 필드 표시 - 각 필드의 타이틀 제거
                    switch currentStep {
                    case 0:
                        // 이름 입력 - 라벨 제거
                        TextField("フルネームを入力", text: $name)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                            .transition(.opacity)
                    case 1:
                        // 학생 번호 입력 - 라벨 제거
                        TextField("学生証に記載の番号", text: $studentID)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                            .keyboardType(.numberPad)
                            .transition(.opacity)
                    case 2:
                        // 학부 선택 - 라벨 제거
                        Picker("学部を選択", selection: $department) {
                            Text("学部を選択").tag("")
                            ForEach(departments, id: \.self) { department in
                                Text(department).tag(department)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .pickerStyle(MenuPickerStyle())
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        .transition(.opacity)
                    case 3:
                        // 학년 선택 - 라벨 제거
                        Picker("学年を選択", selection: $selectedGrade) {
                            ForEach(grades, id: \.self) { grade in
                                Text(grade).tag(grade)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .pickerStyle(MenuPickerStyle())
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        .transition(.opacity)
                    case 4:
                        // 이메일 입력 - 라벨 제거
                        TextField("大学のメールアドレス", text: $email)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .transition(.opacity)
                    case 5:
                        // 비밀번호 입력 - 라벨 제거
                        ZStack(alignment: .trailing) {
                            if isPasswordVisible {
                                TextField("6文字以上のパスワード", text: $password)
                                    .padding()
                                    .background(Color(.systemGray6))
                                    .cornerRadius(10)
                                    .autocapitalization(.none)
                            } else {
                                SecureField("6文字以上のパスワード", text: $password)
                                    .padding()
                                    .background(Color(.systemGray6))
                                    .cornerRadius(10)
                                    .autocapitalization(.none)
                            }
                            
                            Button(action: {
                                isPasswordVisible.toggle()
                            }) {
                                Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                                    .foregroundColor(.gray)
                            }
                            .padding(.trailing, 16)
                        }
                        .transition(.opacity)
                    case 6:
                        // 비밀번호 확인 - 라벨 제거
                        ZStack(alignment: .trailing) {
                            if isConfirmPasswordVisible {
                                TextField("パスワードを再入力", text: $confirmPassword)
                                    .padding()
                                    .background(Color(.systemGray6))
                                    .cornerRadius(10)
                                    .autocapitalization(.none)
                            } else {
                                SecureField("パスワードを再入力", text: $confirmPassword)
                                    .padding()
                                    .background(Color(.systemGray6))
                                    .cornerRadius(10)
                                    .autocapitalization(.none)
                            }
                            
                            Button(action: {
                                isConfirmPasswordVisible.toggle()
                            }) {
                                Image(systemName: isConfirmPasswordVisible ? "eye.slash.fill" : "eye.fill")
                                    .foregroundColor(.gray)
                            }
                            .padding(.trailing, 16)
                        }
                        .transition(.opacity)
                    default:
                        EmptyView()
                    }
                }
                .padding(.horizontal, 30)
                .animation(.easeInOut, value: currentStep)
                
                Spacer()
                
                // 이전/다음/완료 버튼
                HStack(spacing: 15) {
                    // 이전 버튼 (첫 단계가 아닐 때만 표시)
                    if currentStep > 0 {
                        Button(action: {
                            withAnimation {
                                currentStep -= 1
                            }
                        }) {
                            Text("前へ")
                                .fontWeight(.medium)
                                .foregroundColor(Color.appTheme)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(10)
                        }
                    }
                    
                    // 다음 버튼 또는 등록 버튼
                    Button(action: {
                        if currentStep == stepTitles.count - 1 {
                            signUp()
                        } else {
                            withAnimation {
                                currentStep += 1
                            }
                        }
                    }) {
                        Text(currentStep == stepTitles.count - 1 ? "登録" : "次へ")
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(isCurrentStepValid ? Color.appTheme : Color.gray)
                            .cornerRadius(10)
                    }
                    .disabled(!isCurrentStepValid)
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 40)
                
                // 이미 계정이 있는 경우 로그인 링크
                HStack {
                    Text("すでにアカウントをお持ちですか？")
                        .foregroundColor(.secondary)
                    
                    Button("ログイン") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(Color.appTheme)
                    .fontWeight(.bold)
                }
                .font(.subheadline)
                .padding(.bottom, 20)
            }
            .navigationBarItems(leading: Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                HStack {
                    Image(systemName: "chevron.left")
                    Text("戻る")
                }
                .foregroundColor(Color.appTheme)
            })
            .alert(isPresented: $showingAlert) {
                Alert(
                    title: Text(alertMessage == "登録が完了しました。認証メールをご確認ください。" ? "通知" : "エラー"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
    
    // 현재 단계가 유효한지 확인
    private var isCurrentStepValid: Bool {
        switch currentStep {
        case 0:
            return !name.isEmpty
        case 1:
            return !studentID.isEmpty
        case 2:
            return !department.isEmpty
        case 3:
            return true // 학년은 항상 선택되어 있음
        case 4:
            return !email.isEmpty && email.contains("@")
        case 5:
            return password.count >= 6
        case 6:
            return password == confirmPassword
        default:
            return false
        }
    }
    
    // formField 함수 수정 - 라벨 표시 제거
    private func formField(title: String, placeholder: String, text: Binding<String>) -> some View {
        TextField(placeholder, text: text)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
    }
    
    // フォームバリデーション
    private var isFormValid: Bool {
        !name.isEmpty &&
        !email.isEmpty && email.contains("@") &&
        password.count >= 6 &&
        password == confirmPassword &&
        !studentID.isEmpty &&
        !department.isEmpty
    }
    
    private func signUp() {
        // 最終バリデーション
        if !isFormValid {
            if name.isEmpty {
                alertMessage = "名前を入力してください。"
            } else if studentID.isEmpty {
                alertMessage = "学生番号を入力してください。"
            } else if department.isEmpty {
                alertMessage = "学部を選択してください。"
            } else if email.isEmpty {
                alertMessage = "メールアドレスを入力してください。"
            } else if !email.contains("@") {
                alertMessage = "有効なメールアドレスを入力してください。"
            } else if password.count < 6 {
                alertMessage = "パスワードは6文字以上である必要があります。"
            } else if password != confirmPassword {
                alertMessage = "パスワードが一致しません。"
            }
            showingAlert = true
            return
        }
        // 実際の会員登録ロジック
        Task {
            let result = await NetworkService.shared.signUp(
                name: name,
                email: email,
                password: password,
                studentID: studentID,
                department: department,
                grade: selectedGrade
            )
            switch result {
            case .success(_):
                alertMessage = "登録が完了しました。認証メールをご確認ください。"
                showingAlert = true
                // 会員登録成功後、入力値を初期化し最初のステップに戻す
                name = ""
                email = ""
                password = ""
                confirmPassword = ""
                studentID = ""
                department = ""
                selectedGrade = "1年生"
                currentStep = 0
            case .failure(let error):
                alertMessage = error.message
                showingAlert = true
            }
        }
    }
}

#Preview {
    SignUpView()
}
