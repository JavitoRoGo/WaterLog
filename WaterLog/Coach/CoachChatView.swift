import SwiftUI
import FoundationModels

/// Representa un mensaje en el chat para la UI
struct ChatMessage: Identifiable, Equatable {
	let id = UUID()
	let text: String
	let isUser: Bool
	let timestamp: Date
}

struct CoachChatView: View {
	@Environment(FMCoachService.self) private var coachService
	@Environment(\.dismiss) private var dismiss
	@State private var inputText: String = ""
	
	var body: some View {
		NavigationStack {
			VStack(spacing: 0) {
				// Área de mensajes vinculada directamente al servicio
				ScrollViewReader { proxy in
					ScrollView {
						LazyVStack(spacing: 16) {
							ForEach(coachService.chatMessages) { message in
								ChatBubble(message: message)
									.id(message.id)
							}
							
							// Indicador de carga si el bot está pensando
							if coachService.isResponding {
								HStack {
									Text("CoachAI is thinking...")
										.font(.caption)
										.foregroundStyle(.secondary)
										.italic()
									Spacer()
								}
								.padding(.horizontal)
							}
						}
						.padding()
						.overlay {
							if let error = coachService.errorString {
								Text(error)
							}
						}
					}
					.onChange(of: coachService.chatMessages) {
						withAnimation {
							proxy.scrollTo(coachService.chatMessages.last?.id, anchor: .bottom)
						}
					}
				}
				
				inputBar
			}
			.navigationTitle("CoachAI Chat")
			.navigationBarTitleDisplayMode(.inline)
			.toolbar {
				ToolbarItem(placement: .topBarTrailing) {
					Button() {
						dismiss()
					} label: {
						Image(systemName: "xmark")
					}
				}
			}
			.onAppear {
				coachService.chatMessages = [.init(text: "Hi! I'm your hydration coach. How can I help you today?", isUser: false, timestamp: .now)]
			}
		}
	}
	
	private var inputBar: some View {
		VStack(spacing: 0) {
			Divider()
			HStack(alignment: .bottom, spacing: 12) {
				TextField("Ask me about hydration...", text: $inputText, axis: .vertical)
					.padding(.horizontal, 16)
					.padding(.vertical, 10)
					.background(Color(.systemGray6))
					.clipShape(RoundedRectangle(cornerRadius: 20))
					.lineLimit(1...5)
					.disabled(coachService.isResponding) // Deshabilitar mientras responde
				
				Button {
					let textToSend = inputText
					inputText = ""
					Task {
						await coachService.sendMessage(textToSend)
					}
				} label: {
					Image(systemName: "arrow.up.circle.fill")
						.font(.system(size: 32))
						.foregroundStyle(inputText.isEmpty || coachService.isResponding ? .gray : .blue)
				}
				.disabled(inputText.isEmpty || coachService.isResponding)
			}
			.padding(.horizontal)
			.padding(.vertical, 10)
			.background(.ultraThinMaterial)
		}
	}
}

/// Subvista para los globos de texto
struct ChatBubble: View {
	let message: ChatMessage
	
	var body: some View {
		HStack {
			if message.isUser { Spacer() }
			
			Text(message.text)
				.padding(.horizontal, 14)
				.padding(.vertical, 10)
				.background(message.isUser ? Color.blue : Color(.systemGray5))
				.foregroundStyle(message.isUser ? .white : .primary)
				.clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
				// Un pequeño ajuste para que el globo del usuario no tenga esquinas tan redondeadas en la base
				.clipShape(BubbleShape(isUser: message.isUser))
			
			if !message.isUser { Spacer() }
		}
	}
}

/// Shape personalizado para dar un toque más orgánico a los globos de chat
struct BubbleShape: Shape {
	let isUser: Bool
	
	func path(in rect: CGRect) -> Path {
		let path = RoundedRectangle(cornerRadius: 18, style: .continuous).path(in: rect)
		let mutablePath = path
		
		// Aquí podrías añadir lógica para hacer la "colita" del globo si quisieras algo más complejo,
		// pero un corner radius diferenciado suele ser suficiente para una UI limpia.
		return mutablePath
	}
}

#Preview {
	CoachChatView()
		.environment(FMCoachService(context: MockData.coachingContextWarning))
}
