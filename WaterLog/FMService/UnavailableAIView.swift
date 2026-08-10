//
//  UnavailableAIView.swift
//  WaterLog
//
//  Created by Javier Rodríguez Gómez on 10/08/2026.
//

import SwiftUI

struct UnavailableAIView: View {
	@Environment(FMManager.self) var manager
	
    var body: some View {
		ContentUnavailableView {
			Label("Apple Intelligence is unavailable", systemImage: "apple.intelligence")
		} description: {
			Text(manager.notAvailableReason)
		} actions: {
			Button("Try again") {
				manager.checkIsAvailable()
			}
			.buttonStyle(.borderedProminent)
		}

    }
}

#Preview {
    UnavailableAIView()
		.environment(FMManager())
}
