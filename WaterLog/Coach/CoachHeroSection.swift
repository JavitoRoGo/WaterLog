//
//  CoachHeroSection.swift
//  WaterLog
//
//  Created by Javier Rodríguez Gómez on 09/08/2026.
//

import SwiftUI
import FoundationModels

struct CoachHeroSection:  View {
	let coachingContext: CoachingContext
	
	@Environment(FMManager.self) var fmManager
	@State private var coachService: FMCoachService
	
	init(coachingContext: CoachingContext) {
		self.coachingContext = coachingContext
		self.coachService = FMCoachService(context: coachingContext)
	}
	
	var body: some View {
		VStack(spacing: 16) {
			ZStack {
				Circle()
					.fill(coachColor.opacity(0.1))
					.frame(width: 100, height: 100)
				
				Image(systemName: coachIcon)
					.font(.system(size: 50))
					.foregroundStyle(coachColor)
			}
			List {
				ForEach(coachService.coachResponse) { response in
					if let message = response.adviceMessage {
						VStack {
							Text("\(response.toneEmoji ?? "") \(message)")
							Text(response.actionableStep ?? "sin mensaje")
								.font(.headline)
						}
							.multilineTextAlignment(.center)
							.contentTransition(.opacity)
							.animation(.easeInOut, value: message)
					} else {
						Text("")
					}
				}
				.listRowBackground(Color.clear)
			}
			.listStyle(.plain)
			.frame(minHeight: 200)
			.overlay {
				if coachService.session.isResponding {
					ProgressView()
						.tint(coachColor)
				}
			}
			.overlay {
				if let error = coachService.errorString {
					Text(error)
				}
			}
		}
		.frame(maxWidth: .infinity)
		.padding()
		.background(
			RoundedRectangle(cornerRadius: 24)
				.fill(coachColor.opacity(0.05))
		)
		.onChange(of: coachingContext, initial: true) {
			fetchCoachAdvice()
		}
	}
	
	private func fetchCoachAdvice() {
        // 1. Verificar si Apple Intelligence está disponible
        guard fmManager.isModelAvailable else {
            return
        }

        // 2. Consumir el stream del servicio
		coachService.streamAdvice()
    }
	
	private var coachColor: Color {
		switch coachingContext.summary.primaryMotivationTag {
		case .celebratory: return .orange
		case .urgent: return .red
		case .encouraging: return .blue
		case .neutral: return .secondary
		}
	}

	private var coachIcon: String {
		switch coachingContext.summary.primaryMotivationTag {
		case .celebratory: return "sparkles"
		case .urgent: return "exclamationmark.triangle.fill"
		case .encouraging: return "leaf.fill"
		case .neutral: return "person.fill"
		}
	}
}

#Preview {
	CoachHeroSection(coachingContext: MockData.coachingContextWarning)
		.environment(FMManager())
}
