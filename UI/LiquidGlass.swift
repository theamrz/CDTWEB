import SwiftUI

struct GlassContainer<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(20)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(Color.white.opacity(0.18), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.22), radius: 28, x: 0, y: 24)
            .padding(.vertical, 12)
    }
}

struct LiquidGlassBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color(red: 0.15, green: 0.23, blue: 0.38),
                Color(red: 0.07, green: 0.11, blue: 0.2)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay(
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.18))
                    .blur(radius: 80)
                    .frame(width: 420, height: 420)
                    .offset(x: -220, y: -260)

                Circle()
                    .fill(Color.purple.opacity(0.25))
                    .blur(radius: 120)
                    .frame(width: 380, height: 380)
                    .offset(x: 240, y: -120)

                Circle()
                    .fill(Color.cyan.opacity(0.25))
                    .blur(radius: 140)
                    .frame(width: 460, height: 460)
                    .offset(x: 120, y: 320)
            }
        )
    }
}

struct GlassButtonStyle: ButtonStyle {
    var tint: Color = .cyan

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.callout.weight(.semibold))
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(tint.opacity(configuration.isPressed ? 0.85 : 0.55), lineWidth: 1.4)
                    )
                    .shadow(color: tint.opacity(configuration.isPressed ? 0.15 : 0.28), radius: configuration.isPressed ? 10 : 18, x: 0, y: configuration.isPressed ? 4 : 12)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .foregroundStyle(Color.white)
    }
}
