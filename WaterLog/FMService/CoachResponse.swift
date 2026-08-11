//
//  CoachResponse.swift
//  WaterLog
//
//  Created by Javier Rodríguez Gómez on 11/08/2026.
//

import Foundation
import FoundationModels

/// El formato estructurado que el LLM debe seguir para garantizar una respuesta útil y controlada.
@Generable
struct CoachResponse {
	var adviceMessage: String
	var actionableStep: String? // Un consejo corto tipo "Bebe un vaso ahora"
}
