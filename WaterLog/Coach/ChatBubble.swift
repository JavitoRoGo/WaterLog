//
//  ChatBubble.swift
//  WaterLog
//
//  Created by Javier Rodríguez Gómez on 16/08/2026.
//

import SwiftUI
import MarkdownUI

struct ChatBubble: View {
	let message: String
	let isUser: Bool
	
	var body: some View {
		HStack {
			if isUser { Spacer(minLength: 50) }
			
			MarkdownView(streaming: .constant(message))
				.foregroundStyle(isUser ? .white : .primary)
				.padding(.horizontal, 12)
				.padding(.vertical, 8)
				.background(isUser ? Color.blue : Color(.systemGray5))
				.clipShape(.rect(cornerRadius: 16))
				.frame(maxWidth: .infinity, alignment: isUser ? .trailing : .leading)
			
			if !isUser { Spacer() }
		}
	}
}

#Preview {
	ChatBubble(message: "Hello, world!", isUser: true)
}

struct ThinkingBubble: View {
	var body: some View {
		Image(systemName: "ellipsis")
			.symbolEffect(.variableColor)
			.imageScale(.large)
			.padding(.horizontal, 12)
			.padding(.vertical, 8)
			.background(Color(.systemGray5))
			.clipShape(.rect(cornerRadius: 16))
			.frame(maxWidth: .infinity, alignment: .leading)
	}
}

#Preview {
	ThinkingBubble()
}
