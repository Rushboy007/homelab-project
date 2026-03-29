import SwiftUI
import LocalAuthentication

// MARK: - PIN Setup (shown on first launch)

struct PinSetupView: View {
    @Environment(SettingsStore.self) private var settingsStore
    @Environment(Localizer.self) private var localizer
    @Environment(\.colorScheme) private var colorScheme

    var onComplete: () -> Void

    @State private var step: SetupStep = .welcome
    @State private var firstPin = ""
    @State private var confirmPin = ""
    @State private var errorMessage: String? = nil

    private enum SetupStep {
        case welcome, ask, create, confirm
    }

    private var palette: SecurityPalette { .resolve(for: colorScheme) }

    var body: some View {
        ZStack {
            SecurityBackgroundView(palette: palette)

            VStack(spacing: 0) {
                Spacer(minLength: 40)

                Group {
                    switch step {
                    case .welcome:
                        welcomeView
                            .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .move(edge: .leading).combined(with: .opacity)))

                    case .ask:
                        askView
                            .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .move(edge: .leading).combined(with: .opacity)))

                    case .create:
                        PinEntryView(
                            pin: $firstPin,
                            title: localizer.t.securitySetupPin,
                            subtitle: localizer.t.securitySetupPinDesc,
                            errorMessage: nil,
                            onComplete: { _ in
                                withAnimation {
                                    step = .confirm
                                }
                            }
                        )
                        .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .move(edge: .leading).combined(with: .opacity)))

                    case .confirm:
                        PinEntryView(
                            pin: $confirmPin,
                            title: localizer.t.securityConfirmPin,
                            subtitle: localizer.t.securityConfirmPinDesc,
                            errorMessage: errorMessage,
                            onComplete: { pin in
                                if pin == firstPin {
                                    settingsStore.savePin(pin)
                                    HapticManager.success()
                                    checkAndEnableBiometric()
                                } else {
                                    errorMessage = localizer.t.securityPinMismatch
                                    HapticManager.error()
                                    confirmPin = ""
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                        errorMessage = nil
                                    }
                                }
                            }
                        )
                        .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .move(edge: .leading).combined(with: .opacity)))
                    }
                }

                Spacer()
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: step)
        }
    }

    // MARK: - Views

    private var welcomeView: some View {
        VStack(spacing: 32) {
            Spacer(minLength: 20)

            ZStack {
                Circle()
                    .fill(palette.accent.opacity(colorScheme == .dark ? 0.14 : 0.10))
                    .frame(width: 200, height: 200)
                    .blur(radius: 50)

                if let icon = UIImage(named: "AppIconImage") {
                    Image(uiImage: icon)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 140, height: 140)
                        .clipShape(RoundedRectangle(cornerRadius: 32))
                        .shadow(color: palette.accent.opacity(colorScheme == .dark ? 0.36 : 0.18), radius: 25, x: 0, y: 15)
                } else {
                    Image(systemName: "house.fill")
                        .font(.system(size: 72))
                        .foregroundStyle(palette.accent)
                        .frame(width: 140, height: 140)
                        .background(palette.iconFill, in: RoundedRectangle(cornerRadius: 32))
                        .overlay(
                            RoundedRectangle(cornerRadius: 32)
                                .stroke(palette.iconStroke, lineWidth: 1.1)
                        )
                        .shadow(color: palette.accent.opacity(colorScheme == .dark ? 0.26 : 0.12), radius: 20, x: 0, y: 12)
                }
            }

            VStack(spacing: 32) {
                VStack(spacing: 16) {
                    Text(localizer.t.onboardingWelcome)
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(palette.primaryText)

                    Text(localizer.t.onboardingWelcomeDesc)
                        .font(.title3)
                        .foregroundStyle(palette.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }

                Button {
                    HapticManager.light()
                    withAnimation {
                        step = .ask
                    }
                } label: {
                    Text(localizer.t.onboardingWelcomeButton)
                        .font(.headline.bold())
                        .foregroundStyle(.white)
                        .frame(width: 240)
                        .padding(.vertical, 18)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(palette.accent)
                                .shadow(color: palette.accent.opacity(colorScheme == .dark ? 0.32 : 0.16), radius: 10, y: 5)
                        )
                }
            }

            Spacer()
            Spacer()
        }
    }

    private var askView: some View {
        VStack(spacing: 32) {
            Spacer(minLength: 20)

            Image(systemName: "lock.shield.fill")
                .font(.system(size: 80))
                .foregroundStyle(palette.accent)
                .frame(width: 140, height: 140)
                .background(
                    Circle()
                        .fill(palette.iconFill)
                        .overlay(
                            Circle()
                                .stroke(palette.iconStroke, lineWidth: 1.1)
                        )
                )

            VStack(spacing: 32) {
                VStack(spacing: 16) {
                    Text(localizer.t.securityTitle)
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(palette.primaryText)

                    Text(localizer.t.onboardingAskPin)
                        .font(.title3)
                        .foregroundStyle(palette.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }

                VStack(spacing: 20) {
                    Button {
                        HapticManager.light()
                        withAnimation {
                            step = .create
                        }
                    } label: {
                        Text(localizer.t.onboardingAskPinYes)
                            .font(.headline.bold())
                            .foregroundStyle(.white)
                            .frame(width: 240)
                            .padding(.vertical, 18)
                            .background(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .fill(palette.accent)
                                    .shadow(color: palette.accent.opacity(colorScheme == .dark ? 0.32 : 0.16), radius: 10, y: 5)
                            )
                    }

                    Button {
                        HapticManager.light()
                        completeSetup()
                    } label: {
                        Text(localizer.t.onboardingAskPinNo)
                            .font(.subheadline.bold())
                            .foregroundStyle(palette.secondaryText)
                            .padding(.vertical, 8)
                    }
                }
            }

            Spacer()
            Spacer()
        }
    }

    // MARK: - Helpers

    private func checkAndEnableBiometric() {
        let context = LAContext()
        var error: NSError?

        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = localizer.t.securityBiometricReason
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authenticationError in
                DispatchQueue.main.async {
                    if success {
                        settingsStore.biometricEnabled = true
                    } else {
                        settingsStore.biometricEnabled = false
                    }
                    completeSetup()
                }
            }
        } else {
            completeSetup()
        }
    }

    private func completeSetup() {
        settingsStore.hasCompletedOnboarding = true
        onComplete()
    }
}
