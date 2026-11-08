//
//  StatCard.swift
//  WaterLog
//
//  Created by Javier Rodríguez Gómez on 10/08/2026.
//

import SwiftUI

struct StatCard: View {
    let title: LocalizedStringResource
    let value: LocalizedStringResource
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Text(value)
                .font(.headline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
		.background(.secondary.opacity(0.2))
        .clipShape(.rect(cornerRadius: 16))
    }
}
