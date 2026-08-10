//
//  PatternRow.swift
//  WaterLog
//
//  Created by Javier Rodríguez Gómez on 10/08/2026.
//

import SwiftUI

struct PatternRow: View {
    let label: String
    let value: String
    let icon: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.secondary)
                .frame(width: 24)
            Text(label)
                .font(.subheadline)
            Spacer()
            Text(value)
                .font(.subheadline.bold())
                .foregroundStyle(.primary)
        }
        .padding()
    }
}
