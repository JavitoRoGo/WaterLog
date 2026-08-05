//
//  TrendMetricView.swift
//  WaterLog
//
//  Created by Javier Rodríguez Gómez on 05/08/2026.
//

import SwiftUI

struct TrendMetricView: View {
    let label: LocalizedStringResource
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.callout.bold())
        }
    }
}

#Preview {
	TrendMetricView(label: "Label", value: "Value")
}
