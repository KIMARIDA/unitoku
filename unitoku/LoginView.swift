import SwiftUI

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var isShowingSignUp = false
    @State private var isPasswordVisible = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isLoggedIn = false
    
    var body: some View {
        NavigationStack {
            VStack {
                // 로고 및 앱 이름만 표시
                VStack(spacing: 20) {
                    Image(systemName: "graduationcap.fill")
                        .font(.system(size: 70))
                        .foregroundColor(Color.appTheme)
                    
                    Text("ユニトク")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(Color.appTheme)
                        .padding(.bottom, 30)
                }
                .padding(.top, 50)
                
                // 로그인 폼
                VStack(spacing: 20) {
                    // 이메일 입력 필드 - 라벨 제거
                    TextField("学内メールアドレス", text: $email)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    
                    // 비밀번호 입력 필드 - 라벨 제거
                    ZStack(alignment: .trailing) {
                        if isPasswordVisible {
                            TextField("パスワード", text: $password)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(10)
                                .autocapitalization(.none)
                        } else {
                            SecureField("パスワード", text: $password)
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
                    
                    // 비밀번호 찾기
                    HStack {
                        Spacer()
                        
                        Button("パスワードをお忘れですか？") {
                            // 비밀번호 찾기 로직
                        }
                        .font(.footnote)
                        .foregroundColor(Color.appTheme)
                    }
                    .padding(.bottom, 20)
                    
                    // 로그인 버튼
                    Button(action: login) {
                        Text("ログイン")
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.appTheme)
                            .cornerRadius(10)
                    }
                    .disabled(email.isEmpty || password.isEmpty)
                    .opacity((email.isEmpty || password.isEmpty) ? 0.6 : 1)
                    
                    // 회원가입 링크
                    HStack {
                        Text("アカウントをお持ちでないですか？")
                            .foregroundColor(.secondary)
                        
                        Button("登録") {
                            isShowingSignUp = true
                        }
                        .foregroundColor(Color.appTheme)
                        .fontWeight(.bold)
                    }
                    .font(.subheadline)
                    .padding(.top, 20)
                }
                .padding(.horizontal, 30)
                
                Spacer()
            }
            .navigationDestination(isPresented: $isLoggedIn) {
                MainTabView()
                    .navigationBarBackButtonHidden(true)
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $isShowingSignUp) {
                SignUpView()
            }
            .alert(isPresented: $showingAlert) {
                Alert(
                    title: Text("エラー"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
    
    private func login() {
        // 간단한 유효성 검사
        guard !email.isEmpty else {
            alertMessage = "メールアドレスを入力してください。"
            showingAlert = true
            return
        }
        
        guard !password.isEmpty else {
            alertMessage = "パスワードを入力してください。"
            showingAlert = true
            return
        }
        
        // 로그인 처리 (현재는 더미 구현)
        if email.contains("@") && password.count >= 6 {
            // 로그인 성공
            isLoggedIn = true
        } else {
            // 로그인 실패
            alertMessage = "メールアドレスまたはパスワードが正しくありません。"
            showingAlert = true
        }
    }
}

#Preview {
    LoginView()
}
