import SwiftUI
import FoundationModels

struct CoachChatView: View {
	@Environment(FMCoachService.self) private var coachService
	@Environment(\.dismiss) private var dismiss
	@State private var inputText: String = ""
	@State private var scrollPosition = ScrollPosition()
	
	var body: some View {
		@Bindable var bvm = coachService
		NavigationStack {
			VStack(spacing: 0) {
				ScrollView {
					ForEach(coachService.chatSession.transcript) { entry in
						if let interaction = getInteraction(for: entry) {
							interaction
						}
					}
					
					// Indicador de carga si el bot está pensando
					if coachService.isChatResponding {
						ThinkingBubble()
					}
				}
				.scrollPosition($scrollPosition)
				
				Spacer()
				inputBar
			}
			.padding()
			.navigationTitle("CoachAI Chat")
			.navigationBarTitleDisplayMode(.inline)
			.toolbar {
				ToolbarItem(placement: .topBarLeading) {
					Button("Close", systemImage: "xmark") {
						dismiss()
					}
				}
				ToolbarItem(placement: .topBarTrailing) {
					Button("New Chat", systemImage: "square.and.pencil") {
						coachService.newChat()
					}
					.disabled(coachService.chatSession.transcript.count <= 1 || coachService.isChatResponding)
				}
			}
			.alert("Error", isPresented: $bvm.showErrorAlert) {
				Button("OK") {
					bvm.showErrorAlert = false
				}
			} message: {
				Text(bvm.errorString ?? "Unknown error")
			}
			.onAppear {
				coachService.newChat()
			}
			.onChange(of: coachService.chatSession.transcript) {
				withAnimation {
					scrollPosition.scrollTo(edge: .bottom)
				}
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
					.background(.background)
					.clipShape(RoundedRectangle(cornerRadius: 20))
					.lineLimit(1...5)
					.disabled(coachService.isChatResponding)
				
				Button {
					Task {
						await coachService.sendMessage(inputText)
						inputText = ""
					}
				} label: {
					Image(systemName: "arrow.up.circle.fill")
						.font(.system(size: 32))
						.foregroundStyle(inputText.isEmpty || coachService.isChatResponding ? .gray : .blue)
						.accessibilityLabel("Send message")
				}
				.disabled(inputText.isEmpty || coachService.isChatResponding)
			}
			.background(.ultraThinMaterial)
		}
	}
	
	private func getInteraction(for entry: Transcript.Entry) -> ChatBubble? {
		switch entry {
		case .prompt(let prompt):
			ChatBubble(
				message: prompt.segments[0].description,
				isUser: true
			)
		case .response(let response):
			ChatBubble(
				message: response.segments[0].description,
				isUser: false
			)
		default:
			nil
		}
	}
}

#Preview {
	CoachChatView()
		.environment(FMCoachService(context: MockData.coachingContextWarning))
}
