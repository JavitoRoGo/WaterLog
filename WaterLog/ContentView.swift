import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            Tab("Today", systemImage: "drop.fill") {
                TodayView()
            }

            Tab("CoachAI", systemImage: "sparkles.2") {
                CoachView()
            }
        }
    }
}

#Preview {
    ContentView()
}
