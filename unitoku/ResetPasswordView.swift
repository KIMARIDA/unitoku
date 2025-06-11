import SwiftUI
import FirebaseAuth

struct ResetPasswordView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var email = ""
    @State private var isSending = false
    @State private var showingAlert = false
    @State private var alertMessage = ""

    var body: some View {
        VStack(spacing: 30) {
            // 상단 헤더 (뒤로 가기 버튼 포함)
            HStack {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("戻る")
                    }
                    .foregroundColor(Color.appTheme)
                }
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            
            Text("パスワードリセット")
                .font(.title)
                .fontWeight(.bold)
                .padding(.top, 10)

            TextField("メールアドレスを入力", text: $email)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .padding(.horizontal, 30)

            Button(action: sendResetEmail) {
                if isSending {
                    ProgressView()
                } else {
                    Text("リセットメールを送信")
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.appTheme)
                        .cornerRadius(10)
                }
            }
            .disabled(email.isEmpty || isSending)
            .padding(.horizontal, 30)

            Spacer()
        }
        .alert(isPresented: $showingAlert) {
            Alert(
                title: Text("通知"),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }

    private func sendResetEmail() {
        guard !email.isEmpty else {
            alertMessage = "メールアドレスを入力してください。"
            showingAlert = true
            return
        }
        isSending = true
        Auth.auth().sendPasswordReset(withEmail: email) { error in
            isSending = false
            if let error = error {
                alertMessage = "リセットメールの送信に失敗しました: \(error.localizedDescription)"
            } else {
                alertMessage = "パスワードリセット用のメールを送信しました。メールをご確認ください。"
            }
            showingAlert = true
        }
    }
}

#Preview {
    ResetPasswordView()
}
