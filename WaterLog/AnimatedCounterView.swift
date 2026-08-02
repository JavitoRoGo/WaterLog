import SwiftUI

struct AnimatedCounterView: View {
    let targetValue: Int
    
    @State private var animatedValue: Double = 0

	var body: some View {
		HStack(alignment: .firstTextBaseline, spacing: 4) {
			Text("\(animatedValue.formatted())")
				.contentTransition(.numericText(value: animatedValue))
			
			if targetValue == 1 {
				Text("day")
			} else {
				Text("days")
			}
		}
		.font(.title.bold())
		.onAppear {
			animatedValue = 0
			withAnimation(.easeIn(duration: 2.0).delay(0.3)) {
				animatedValue = Double(targetValue)
			}
		}
		.onChange(of: targetValue) { _, newValue in
			withAnimation(.easeIn(duration: 2.0)) {
				animatedValue = Double(newValue)
			}
		}
	}
}

#Preview {
    // Probamos con una duración más larga para apreciar el efecto de subida
    AnimatedCounterView(targetValue: 10)
}
