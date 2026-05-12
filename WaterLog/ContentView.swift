import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            Tab("Hoy", systemImage: "drop.fill") {
                TodayView()
            }

            Tab("Historial", systemImage: "chart.bar.xaxis") {
                StatisticsView()
            }
        }
    }
}

#Preview {
    ContentView()
}
