//
//  CoachResponse.swift
//  WaterLog
//
//  Created by Javier Rodríguez Gómez on 11/08/2026.
//

import Foundation
import FoundationModels

/// The structured format that the LLM must follow to ensure a useful and controlled response.
@Generable
struct CoachResponse {
    @Guide(description: "Empathetic coaching message.")
    var adviceMessage: String
    
    @Guide(description: "Short actionable command.")
    var actionableStep: String?

    @Guide(description: "Single relevant emoji.")
    var toneEmoji: String
}
