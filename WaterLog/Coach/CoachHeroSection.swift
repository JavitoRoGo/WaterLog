//
//  CoachHeroSection.swift
//  WaterLog
//
//  Created by Javier Rodríguez Gómez on 09/08/2026.
//

import SwiftUI

struct CoachHeroSection:  View {
	let coachColor: Color
	let coachIcon: String
	let coachMessage: String
	let isGeneratingAdvice: Bool
	
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
        }
    }

#Preview {
	CoachHeroSection(coachColor: .blue, coachIcon: "drop.fill", coachMessage: "You're doing great!", isGeneratingAdvice: false)
}
