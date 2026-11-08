//
//  PatternsSection.swift
//  WaterLog
//
//  Created by Javier Rodríguez Gómez on 10/08/2026.
//

import SwiftUI

struct PatternsSection: View {
	let coachingContext: CoachingContext
	
	var body: some View{
		VStack(alignment: .leading, spacing: 12) {
			Text("Insights")
				.font(.headline)
				.padding(.leading, 4)
			
			VStack(spacing: 0) {
				PatternRow(label: "Consistency", value: coachingContext.patterns.isStable ? "Stable" : "Variable", icon: "waveform.path.ecg")
				Divider().padding(.leading, 36)
				PatternRow(label: "Momentum", value: coachingContext.patterns.isImproving ? "Improving" : "Declining", icon: "arrow.up.forward.circle")
			}
			.background(.secondary.opacity(0.2))
			.clipShape(.rect(cornerRadius: 16))
		}
	}
}

#Preview {
	PatternsSection(coachingContext: MockData.coachingContextGood)
}
