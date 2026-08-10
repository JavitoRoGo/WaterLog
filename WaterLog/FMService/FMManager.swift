//
//  FMManager.swift
//  WaterLog
//
//  Created by Javier Rodríguez Gómez on 10/08/2026.
//

import Foundation
import FoundationModels

@Observable
final class FMManager {
	var notAvailableReason: LocalizedStringResource = "Checking for model availability..."
	var isModelAvailable: Bool {
		notAvailableReason.key.isEmpty
	}
	
	init() {
		checkIsAvailable()
	}
	
	@discardableResult
	func checkIsAvailable() -> Bool {
		switch SystemLanguageModel.default.availability {
		case .available:
			notAvailableReason = ""
		case .unavailable(.appleIntelligenceNotEnabled):
			notAvailableReason = "Enable Apple Intelligence in System Settings."
		case .unavailable(.deviceNotEligible):
			notAvailableReason = "Apple Intelligence is not available on this device."
		case .unavailable(.modelNotReady):
			notAvailableReason = "The model is not ready yet."
		case .unavailable(let unknown):
			notAvailableReason = "Foundation Model unavailable: \(String(describing: unknown))."
		}
		return isModelAvailable
	}
}
