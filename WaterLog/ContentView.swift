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
			
			Tab("Progress", systemImage: "chart.bar.fill") {
				StreaksView()
			}

            Tab("Settings", systemImage: "gearshape") {
                SettingsView()
            }
        }
    }
}

#Preview {
    ContentView()
}
