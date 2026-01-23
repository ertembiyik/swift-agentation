import SwiftUI
import Agentation

struct SwiftUIDemoView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var rememberMe = false
    @State private var volume: Double = 50
    @State private var selectedTheme = 2
    @State private var notificationsEnabled = true

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                profileSection
                formSection
                buttonsSection
                controlsSection
                agentationSection
            }
            .padding(20)
        }
        .navigationTitle("SwiftUI Demo")
        .agentationTag("SwiftUIDemoScreen")
    }

    // MARK: - Profile Section

    private var profileSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Profile")
                .font(.title2)
                .fontWeight(.semibold)
                .agentationTag("ProfileHeader")

            HStack(alignment: .top, spacing: 16) {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 80, height: 80)
                    .foregroundColor(.blue)
                    .agentationTag("ProfileAvatar")

                VStack(alignment: .leading, spacing: 4) {
                    Text("Jane Appleseed")
                        .font(.title3)
                        .fontWeight(.bold)
                        .agentationTag("UserName")

                    Text("Product Designer")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .agentationTag("JobTitle")
                }

                Spacer()
            }
            .agentationTag("ProfileCard")

            Text("Creating beautiful and intuitive interfaces. I love working with SwiftUI and exploring new design patterns.")
                .font(.body)
                .foregroundColor(.primary)
                .agentationTag("BioText")

            Divider()
        }
        .agentationTag("ProfileSection")
    }

    // MARK: - Form Section

    private var formSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Form Elements")
                .font(.title2)
                .fontWeight(.semibold)
                .agentationTag("FormHeader")

            TextField("Email address", text: $email)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .agentationTag("EmailInput")

            SecureField("Password", text: $password)
                .textFieldStyle(.roundedBorder)
                .agentationTag("PasswordInput")

            Toggle("Remember me", isOn: $rememberMe)
                .agentationTag("RememberMeToggle")

            Toggle("Enable notifications", isOn: $notificationsEnabled)
                .agentationTag("NotificationsToggle")

            Divider()
        }
        .agentationTag("FormSection")
    }

    // MARK: - Buttons Section

    private var buttonsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Buttons")
                .font(.title2)
                .fontWeight(.semibold)
                .agentationTag("ButtonsHeader")

            HStack(spacing: 12) {
                Button(action: {}) {
                    Text("Sign In")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .agentationTag("SignInButton")

                Button(action: {}) {
                    Text("Create Account")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .agentationTag("CreateAccountButton")
            }
            .agentationTag("PrimaryButtons")

            Button("Forgot Password?") {}
                .font(.subheadline)
                .agentationTag("ForgotPasswordLink")

            HStack(spacing: 16) {
                Button(action: {}) {
                    Image(systemName: "apple.logo")
                        .font(.title2)
                }
                .buttonStyle(.bordered)
                .agentationTag("AppleSignIn")

                Button(action: {}) {
                    Image(systemName: "g.circle.fill")
                        .font(.title2)
                }
                .buttonStyle(.bordered)
                .agentationTag("GoogleSignIn")

                Button(action: {}) {
                    Image(systemName: "f.circle.fill")
                        .font(.title2)
                }
                .buttonStyle(.bordered)
                .agentationTag("FacebookSignIn")

                Spacer()
            }
            .agentationTag("SocialButtons")

            Divider()
        }
        .agentationTag("ButtonsSection")
    }

    // MARK: - Controls Section

    private var controlsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Controls")
                .font(.title2)
                .fontWeight(.semibold)
                .agentationTag("ControlsHeader")

            VStack(alignment: .leading, spacing: 8) {
                Text("Volume: \(Int(volume))%")
                    .font(.subheadline)
                    .agentationTag("VolumeLabel")

                Slider(value: $volume, in: 0...100)
                    .agentationTag("VolumeSlider")
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Theme")
                    .font(.subheadline)
                    .agentationTag("ThemeLabel")

                Picker("Theme", selection: $selectedTheme) {
                    Text("Light").tag(0)
                    Text("Dark").tag(1)
                    Text("System").tag(2)
                }
                .pickerStyle(.segmented)
                .agentationTag("ThemePicker")
            }

            Divider()
        }
        .agentationTag("ControlsSection")
    }

    // MARK: - Agentation Section

    private var agentationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Agentation")
                .font(.title2)
                .fontWeight(.semibold)
                .agentationTag("AgentationHeader")

            Text("Tap the button below or shake your device to start capturing UI feedback.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .agentationTag("InstructionText")

            Button(action: startAgentation) {
                HStack {
                    Image(systemName: "sparkles")
                    Text("Start Agentation")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
            }
            .buttonStyle(.borderedProminent)
            .tint(.purple)
            .agentationTag("StartAgentationButton")

            Spacer(minLength: 40)
        }
        .agentationTag("AgentationSection")
    }

    // MARK: - Actions

    private func startAgentation() {
        Agentation.shared.start { feedback in
            print("=== Agentation Feedback ===")
            print(feedback.toMarkdown())
            print("===========================")
        }
    }
}

// MARK: - Preview

#Preview("SwiftUI Demo") {
    NavigationStack {
        SwiftUIDemoView()
    }
}
