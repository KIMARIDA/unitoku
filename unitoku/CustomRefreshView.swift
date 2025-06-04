import SwiftUI

struct BubbleSpinnerView: View {
    let themeColor: Color
    let isRefreshing: Bool
    let bubbleCount: Int
    
    @State private var rotation: Double = 0
    @State private var bubbleScale: [CGFloat]
    
    init(themeColor: Color = Color.appTheme, isRefreshing: Bool = false, bubbleCount: Int = 5) {
        self.themeColor = themeColor
        self.isRefreshing = isRefreshing
        self.bubbleCount = bubbleCount
        self._bubbleScale = State(initialValue: Array(repeating: 0.5, count: bubbleCount))
    }
    
    var body: some View {
        ZStack {
            ForEach(0..<bubbleCount, id: \.self) { index in
                Circle()
                    .fill(themeColor.opacity(max(0.3, Double(index) / Double(bubbleCount))))
                    .frame(width: 12, height: 12)
                    .scaleEffect(bubbleScale[index])
                    .offset(y: -40) // 원형 경로의 반지름
                    .rotationEffect(.degrees(Double(index) * 360.0 / Double(bubbleCount) + rotation))
            }
        }
        .frame(width: 80, height: 80)
        .onChange(of: isRefreshing) { oldValue, newValue in
            if newValue {
                startAnimation()
            } else {
                stopAnimation()
            }
        }
        .onAppear {
            if isRefreshing {
                startAnimation()
            }
        }
    }
    
    private func startAnimation() {
        withAnimation(Animation.linear(duration: 2).repeatForever(autoreverses: false)) {
            rotation = 360
        }
        
        for index in 0..<bubbleCount {
            withAnimation(Animation.easeInOut(duration: 0.5).repeatForever(autoreverses: true).delay(Double(index) * 0.1)) {
                bubbleScale[index] = 1.0
            }
        }
    }
    
    private func stopAnimation() {
        withAnimation {
            rotation = 0
            for index in 0..<bubbleCount {
                bubbleScale[index] = 0.5
            }
        }
    }
}

struct CustomRefreshView: View {
    let isRefreshing: Bool
    let themeColor: Color
    
    @State private var rotation: Double = 0
    @State private var scale: CGFloat = 0.8
    
    var body: some View {
        BubbleSpinnerView(themeColor: themeColor, isRefreshing: isRefreshing, bubbleCount: 8)
    }
}

struct RefreshableScrollView<Content: View>: View {
    var content: Content
    var onRefresh: () async -> Void
    var showsIndicators: Bool
    var themeColor: Color
    
    @State private var isRefreshing = false
    @State private var refreshViewOffset: CGFloat = 0
    
    init(showsIndicators: Bool = true, themeColor: Color = .blue, onRefresh: @escaping () async -> Void, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.onRefresh = onRefresh
        self.showsIndicators = showsIndicators
        self.themeColor = themeColor
    }
    
    var body: some View {
        ScrollView(showsIndicators: showsIndicators) {
            ZStack(alignment: .top) {
                CustomRefreshView(isRefreshing: isRefreshing, themeColor: themeColor)
                    .opacity(refreshViewOffset > 0 || isRefreshing ? 1 : 0)
                    .scaleEffect(refreshViewOffset > 0 ? min(1, refreshViewOffset / 60) : 1)
                    .padding(.top, isRefreshing ? 10 : -50)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isRefreshing)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: refreshViewOffset)
                
                content
                    .offset(y: isRefreshing ? 60 : 0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isRefreshing)
            }
            .background(
                GeometryReader { proxy in
                    Color.clear.preference(key: ScrollOffsetPreferenceKey.self, value: proxy.frame(in: .global).minY)
                }
            )
        }
        .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
            refreshViewOffset = value
            
            if value > 70 && !isRefreshing {
                isRefreshing = true
                Task {
                    await onRefresh()
                    await MainActor.run {
                        withAnimation {
                            isRefreshing = false
                        }
                    }
                }
            }
        }
    }
}

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

#Preview {
    RefreshableScrollView(themeColor: Color.appTheme, onRefresh: {
        try? await Task.sleep(nanoseconds: 2_000_000_000)
    }) {
        VStack {
            ForEach(0..<10, id: \.self) { i in
                Text("Item \(i)")
                    .padding()
            }
        }
    }
}
