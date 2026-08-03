import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            Tab("Today", systemImage: "drop.fill") {
                TodayView()
            }

            Tab("Historical", systemImage: "chart.bar.xaxis") {
                StatisticsView()
            }
			
			Tab("Achievements", systemImage: "trophy") {
				StreaksView()
			}

            Tab("Insights", systemImage: "chart.xyaxis.line") {
                
            }
        }
    }
}

#Preview {
    ContentView()
}
