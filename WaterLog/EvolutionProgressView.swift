import SwiftUI

struct EvolutionProgressView: View {
    let currentStreak: Int
    private let maxThreshold: Int = 30
    
    @State private var animatedProgress: CGFloat = 0

    private var milestones: [(days: Int, emoji: String)] {
        ConsistencyEvolution.allCases.map {
            ($0.rawValue, $0.emoji)
        }
    }
    
    private var actualProgress: CGFloat {
        let p = CGFloat(currentStreak) / CGFloat(maxThreshold)
        return min(max(p, 0), 1)
    }

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let centerY = height / 2
            
            ZStack(alignment: .leading) {
                // 1. La Línea de Fondo
                Capsule()
                    .fill(Color.secondary.opacity(0.2))
                    .frame(height: 4)
                
                // 2. La Línea de Progreso
                Capsule()
                    .fill(currentStreak >= 30 ? Color.green.gradient : Color.blue.gradient)
                    .frame(width: width * animatedProgress, height: 4)
                    .shadow(color: currentStreak >= 30 ? .green.opacity(0.5) : .clear, radius: 5)

                // 3. Los Nodos (Hitos)
                ForEach(milestones, id: \.days) { milestone in
                    let xPosition = calculateX(for: milestone.days, width: width)
                    let threshold = CGFloat(milestone.days)/CGFloat(maxThreshold)
                    
                    // Calculamos un factor de "activación" basado en el progreso real
                    // Esto nos permite una transición mucho más controlada
                    let isReached = animatedProgress >= threshold
                    
                    VStack(spacing: 4) {
                        Text(milestone.emoji)
                            .font(.system(size: 16))
                            .scaleEffect(isReached ? 1.2 : 0.8)
                            .opacity(isReached ? 1.0 : 0.4)
                            .offset(y: isReached ? 0 : 10)
                        
                        Circle()
                            .fill(isReached ? Color.blue : Color.secondary.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                    .position(x: xPosition, y: centerY - 15)
                }

                // 4. El "Viajero"
                Circle()
                    .fill(.white)
                    .frame(width: 12, height: 12)
                    .shadow(color: .black.opacity(0.2), radius: 2)
                    .position(x: width * animatedProgress, y: centerY)
            }
        }
        .frame(height: 40)
		.onAppear {
			animatedProgress = 0
			withAnimation(.spring(response: 2.0, dampingFraction: 0.8).delay(0.2)) {
				animatedProgress = actualProgress
			}
		}
        .onChange(of: currentStreak) { _, newValue in
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                animatedProgress = CGFloat(newValue) / CGFloat(maxThreshold)
            }
        }
    }

    private func calculateX(for days: Int, width: CGFloat) -> CGFloat {
        let minDays = 0
        let maxDays = 30
        let normalized = CGFloat(days - minDays) / CGFloat(maxDays - minDays)
        return width * normalized
    }
}

#Preview {
	EvolutionProgressView(currentStreak: 12)
}
