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

            HStack(alignment: .top, spacing: 16) {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 80, height: 80)
                    .foregroundStyle(.blue)
                    .accessibilityLabel("Profile Avatar")

                VStack(alignment: .leading, spacing: 4) {
                    Text("Jane Appleseed")
                        .font(.title3)
                        .fontWeight(.bold)

                    Text("Product Designer")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            Text("Creating beautiful and intuitive interfaces. I love working with SwiftUI and exploring new design patterns.")
                .font(.body)
                .foregroundStyle(.primary)

            Divider()
        }
    }

    // MARK: - Form Section

    private var formSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Form Elements")
                .font(.title2)
                .fontWeight(.semibold)

            TextField("Email address", text: $email)
                .textFieldStyle(.roundedBorder)
                #if os(iOS)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                #endif

            SecureField("Password", text: $password)
                .textFieldStyle(.roundedBorder)

            Toggle("Remember me", isOn: $rememberMe)

            Toggle("Enable notifications", isOn: $notificationsEnabled)

            Divider()
        }
    }

    // MARK: - Buttons Section

    private var buttonsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Buttons")
                .font(.title2)
                .fontWeight(.semibold)

            HStack(spacing: 12) {
                Button(action: {}) {
                    Text("Sign In")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                Button(action: {}) {
                    Text("Create Account")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }

            Button("Forgot Password?") {}
                .font(.subheadline)

            HStack(spacing: 16) {
                Button(action: {}) {
                    Label("Sign in with Apple", systemImage: "apple.logo")
                        .labelStyle(.iconOnly)
                        .font(.title2)
                }
                .buttonStyle(.bordered)

                Button(action: {}) {
                    Label("Sign in with Google", systemImage: "g.circle.fill")
                        .labelStyle(.iconOnly)
                        .font(.title2)
                }
                .buttonStyle(.bordered)

                Button(action: {}) {
                    Label("Sign in with Facebook", systemImage: "f.circle.fill")
                        .labelStyle(.iconOnly)
                        .font(.title2)
                }
                .buttonStyle(.bordered)

                Spacer()
            }

            Divider()
        }
    }

    // MARK: - Controls Section

    private var controlsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Controls")
                .font(.title2)
                .fontWeight(.semibold)

            VStack(alignment: .leading, spacing: 8) {
                Text("Volume: \(Int(volume))%")
                    .font(.subheadline)

                Slider(value: $volume, in: 0...100)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Theme")
                    .font(.subheadline)

                Picker("Theme", selection: $selectedTheme) {
                    Text("Light").tag(0)
                    Text("Dark").tag(1)
                    Text("System").tag(2)
                }
                .pickerStyle(.segmented)
            }

            Divider()
        }
    }

}

// MARK: - Preview

#Preview("SwiftUI Demo") {
    NavigationStack {
        SwiftUIDemoView()
    }
}
