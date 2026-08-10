//
//  CoachHeroSection.swift
//  WaterLog
//
//  Created by Javier Rodríguez Gómez on 09/08/2026.
//

import SwiftUI

struct CoachHeroSection:  View {
	let motivationTag: CoachingContext.MotivationTag
	
	@State private var isGeneratingAdvice: Bool = false
	@State private var coachMessage: String = ""
	
	var body: some View {
		VStack(spacing: 16) {
			ZStack {
				Circle()
					.fill(coachColor.opacity(0.1))
					.frame(width: 120, height: 120)
				
				Image(systemName: coachIcon)
					.font(.system(size: 50))
					.foregroundStyle(coachColor)
			}
			
			VStack(spacing: 8) {
				if isGeneratingAdvice {
					ProgressView()
						.controlSize(.large)
						.tint(coachColor)
				} else {
					Text(coachMessage)
						.font(.title3)
						.fontWeight(.medium)
						.multilineTextAlignment(.center)
						.contentTransition(.opacity)
						.animation(.easeInOut, value: coachMessage)
				}
			}
			.frame(minHeight: 100) // Evita saltos de layout mientras carga
		}
		.frame(maxWidth: .infinity)
		.padding()
		.background(
			RoundedRectangle(cornerRadius: 24)
				.fill(coachColor.opacity(0.05))
		)
		.task {
			// Simulamos la llamada al LLM local al cargar la vista
			await fetchCoachAdvice()
		}
	}
	
	private func fetchCoachAdvice() async {
		isGeneratingAdvice = true
		
		// Simulamos el tiempo de respuesta de un LLM local (Foundation Models)
		// En la implementación real, aquí llamarías al modelo pasándole coachingContext
		try? await Task.sleep(for: .seconds(1.5))
		
		// Ejemplo de cómo el mensaje cambiaría según el contexto generado
		switch motivationTag {
		case .celebratory:
			coachMessage = "You're on fire! Your hydration streak is growing beautifully. Keep this momentum!"
		case .urgent:
			coachMessage = "Warning: We've noticed a drop in your consistency. Let's try to hit your goal today!"
		case .encouraging:
			coachMessage = "You're doing well, but let's try to make your drinking habits even more regular."
		case .neutral:
			coachMessage = "Ready for today? Your hydration levels are looking steady."
		}
		
		isGeneratingAdvice = false
	}
	
	private var coachColor: Color {
		switch motivationTag {
		case .celebratory: return .orange
		case .urgent: return .red
		case .encouraging: return .blue
		case .neutral: return .secondary
		}
	}

	private var coachIcon: String {
		switch motivationTag {
		case .celebratory: return "sparkles"
		case .urgent: return "exclamationmark.triangle.fill"
		case .encouraging: return "leaf.fill"
		case .neutral: return "person.fill"
		}
	}
}

#Preview {
	CoachHeroSection(motivationTag: .urgent)
}
