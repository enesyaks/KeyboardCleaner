import AppKit
import SwiftUI

struct OnboardingView: View {
    var onFinish: () -> Void

    @State private var settings = AppSettings()
    @State private var page = 0
    @State private var appeared = false

    private let pages: [OnboardingPage] = [
        .init(
            symbol: "keyboard.fill",
            title: "Focus on cleaning\nyour keyboard",
            body: "KeyboardCleaner blocks accidental key presses while you clean your Mac keyboard. Keys stay silent until you’re done."
        ),
        .init(
            symbol: "menubar.arrow.up.rectangle",
            title: "Always within\nreach",
            body: "The app lives in the menu bar. Click the icon, lock, clean, unlock. It stays out of your Dock."
        ),
        .init(
            symbol: "lock.shield.fill",
            title: "Safe and\nin control",
            body: "Mouse and trackpad keep working. Emergency unlock: ⌃⌥⇧⌘K. Accessibility permission is required on first use."
        ),
        .init(
            symbol: "power.circle.fill",
            title: "Start with\nyour Mac",
            body: "Turn on Launch at login so KeyboardCleaner is ready in the menu bar every time you sign in."
        )
    ]

    private var isLastPage: Bool { page == pages.count - 1 }

    var body: some View {
        ZStack {
            OnboardingAtmosphere(page: page)

            VStack(spacing: 0) {
                topBar
                    .padding(.horizontal, 28)
                    .padding(.top, 22)

                Group {
                    if isLastPage {
                        launchAtLoginPage
                    } else {
                        pageContent(pages[page], index: page)
                    }
                }
                .id(page)
                .transition(
                    .asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    )
                )

                bottomBar
                    .padding(.horizontal, 28)
                    .padding(.bottom, 28)
                    .padding(.top, 8)
            }
        }
        .frame(width: 460, height: 620)
        .onAppear {
            settings.refreshLaunchAtLoginStatus()
            withAnimation(.easeOut(duration: 0.55)) {
                appeared = true
            }
        }
    }

    private var topBar: some View {
        HStack {
            HStack(spacing: 10) {
                AppIconView()
                    .frame(width: 36, height: 36)
                    .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                    .shadow(color: .black.opacity(0.12), radius: 8, y: 3)

                Text("KeyboardCleaner")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.onboardingInk)
            }

            Spacer()

            if !isLastPage {
                Button("Skip") {
                    finish()
                }
                .font(.system(size: 12.5, weight: .medium, design: .rounded))
                .foregroundStyle(Color.onboardingInk.opacity(0.4))
                .buttonStyle(.plain)
            }
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : -8)
    }

    private func pageContent(_ item: OnboardingPage, index: Int) -> some View {
        VStack(spacing: 22) {
            Spacer(minLength: 12)

            ZStack {
                Circle()
                    .fill(Color.onboardingAccent.opacity(0.12))
                    .frame(width: 128, height: 128)

                if index == 0, let nsImage = NSImage.appIcon {
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 108, height: 108)
                        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                        .shadow(color: Color.onboardingAccent.opacity(0.28), radius: 24, y: 12)
                } else {
                    Image(systemName: item.symbol)
                        .font(.system(size: 44, weight: .semibold))
                        .foregroundStyle(index == 2 ? Color.onboardingLock : Color.onboardingAccent)
                        .symbolEffect(.bounce, value: page)
                }
            }
            .opacity(appeared ? 1 : 0)

            VStack(spacing: 12) {
                Text(item.title)
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.onboardingInk)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                    .tracking(-0.4)

                Text(item.body)
                    .font(.system(size: 14.5, weight: .regular, design: .rounded))
                    .foregroundStyle(Color.onboardingInk.opacity(0.58))
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .frame(maxWidth: 340)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 12)

            Spacer(minLength: 8)
        }
        .padding(.horizontal, 36)
    }

    private var launchAtLoginPage: some View {
        VStack(spacing: 22) {
            Spacer(minLength: 8)

            ZStack {
                Circle()
                    .fill(Color.onboardingAccent.opacity(0.12))
                    .frame(width: 112, height: 112)

                Image(systemName: "power.circle.fill")
                    .font(.system(size: 42, weight: .semibold))
                    .foregroundStyle(Color.onboardingAccent)
                    .symbolEffect(.bounce, value: page)
            }

            VStack(spacing: 12) {
                Text(pages[page].title)
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.onboardingInk)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                    .tracking(-0.4)

                Text(pages[page].body)
                    .font(.system(size: 14.5, weight: .regular, design: .rounded))
                    .foregroundStyle(Color.onboardingInk.opacity(0.58))
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .frame(maxWidth: 340)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Toggle(isOn: Binding(
                get: { settings.launchAtLogin },
                set: { settings.launchAtLogin = $0 }
            )) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Launch at login")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.onboardingInk)
                    Text("Open automatically when you sign in to your Mac")
                        .font(.system(size: 12, weight: .regular, design: .rounded))
                        .foregroundStyle(Color.onboardingInk.opacity(0.5))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .toggleStyle(.switch)
            .tint(Color.onboardingAccent)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white.opacity(0.72))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Color.onboardingInk.opacity(0.06), lineWidth: 1)
            )
            .padding(.horizontal, 8)
            .padding(.top, 4)

            if let error = settings.launchAtLoginError {
                Text(error)
                    .font(.system(size: 11.5, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.onboardingLock)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }

            Spacer(minLength: 4)
        }
        .padding(.horizontal, 36)
        .opacity(appeared ? 1 : 0)
    }

    private var bottomBar: some View {
        VStack(spacing: 18) {
            HStack(spacing: 8) {
                ForEach(0..<pages.count, id: \.self) { index in
                    Capsule()
                        .fill(index == page ? Color.onboardingAccent : Color.onboardingInk.opacity(0.15))
                        .frame(width: index == page ? 22 : 7, height: 7)
                        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: page)
                }
            }

            Button {
                if !isLastPage {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.86)) {
                        page += 1
                    }
                } else {
                    finish()
                }
            } label: {
                Text(isLastPage ? "Go to Menu Bar" : "Continue")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(OnboardingPrimaryButtonStyle())

            Text(isLastPage
                 ? "Look for the icon in the top-right menu bar"
                 : " ")
                .font(.system(size: 11.5, weight: .medium, design: .rounded))
                .foregroundStyle(Color.onboardingInk.opacity(0.4))
        }
        .opacity(appeared ? 1 : 0)
    }

    private func finish() {
        onFinish()
    }
}

// MARK: - Models & Chrome

private struct OnboardingPage {
    let symbol: String
    let title: String
    let body: String
}

private struct AppIconView: View {
    var body: some View {
        if let image = NSImage.appIcon {
            Image(nsImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
        } else {
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .fill(Color.onboardingAccent.opacity(0.2))
                .overlay {
                    Image(systemName: "keyboard.fill")
                        .foregroundStyle(Color.onboardingAccent)
                }
        }
    }
}

private struct OnboardingAtmosphere: View {
    let page: Int

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(hex: 0xF2F8F6),
                    Color(hex: 0xE4F0ED),
                    Color(hex: 0xEAF3F7)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(Color.onboardingAccent.opacity(0.2))
                .frame(width: 280, height: 280)
                .blur(radius: 60)
                .offset(x: page == 1 || page == 3 ? 40 : -120, y: -160)
                .animation(.easeInOut(duration: 0.55), value: page)

            Circle()
                .fill(Color.onboardingLock.opacity(0.16))
                .frame(width: 220, height: 220)
                .blur(radius: 50)
                .offset(x: page == 2 ? -30 : 130, y: 200)
                .animation(.easeInOut(duration: 0.55), value: page)
        }
        .ignoresSafeArea()
    }
}

private struct OnboardingPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.white)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.onboardingAccent)
                    .opacity(configuration.isPressed ? 0.88 : 1)
            )
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

private extension Color {
    static let onboardingInk = Color(hex: 0x14242C)
    static let onboardingAccent = Color(hex: 0x1B8A78)
    static let onboardingLock = Color(hex: 0xE07A3D)

    init(hex: UInt32, opacity: Double = 1) {
        let r = Double((hex >> 16) & 0xFF) / 255
        let g = Double((hex >> 8) & 0xFF) / 255
        let b = Double(hex & 0xFF) / 255
        self.init(.sRGB, red: r, green: g, blue: b, opacity: opacity)
    }
}

extension NSImage {
    static var appIcon: NSImage? {
        if let url = Bundle.main.url(forResource: "AppIcon", withExtension: "icns")
            ?? Bundle.main.url(forResource: "AppIcon", withExtension: "png") {
            return NSImage(contentsOf: url)
        }
        return NSImage(named: NSImage.applicationIconName)
    }
}
