//
// SettingsView.swift
//
import SwiftUI
import ServiceManagement
import KeyboardShortcuts

#Preview {
    SettingsWindowView(windowRef: nil).frame(height: 1000)
}

enum SettingsTab {
    case general
    case api
    case about
}
struct ApiModelPickerOption {
    var displayName: String
    var value: String
}

enum AppearancePreference: String, CaseIterable {
    case light
    case dark
    case system
}

enum WindowStylePreference: String, CaseIterable {
    case pinnable
    case windowed
}


struct SettingsWindowView: View {
    @AppStorage(AppStorageKey.appearancePref) var appStorage_appearance: AppearancePreference = DEFAULT_APPEARANCE_PREFERENCE
    let windowRef: SettingsWindow?
    
    @State private var selectedTab: SettingsTab = .general
    let generalTabSize: CGFloat = 624
    let apiTabSize: CGFloat = 556
    let aboutTabSize: CGFloat = 364
    
    var body: some View {
        TabViewController(selectedTab: $selectedTab)
            .navigationTitle("Settings")
            .onChange(of: appStorage_appearance) {
                if let window = windowRef {
                    window.appearance = getPreferredAppearance(pref: appStorage_appearance)
                }
            }
        // Keep track of selected tab and resize window accordingly
        // This seems like a terrible approach, but I couldn't figure out another way to
        // auto-resize the tab view to the children content height.
        // https://gist.github.com/mminer/caec00d2165362ff65e9f1f728cecae2 indicates that setting
        // the frame size seems to be a valid approach...
            .onChange(of: selectedTab) { _, _ in
                var contentSize: CGFloat = 0
                switch selectedTab {
                case .general:
                    contentSize = generalTabSize
                case .api:
                    contentSize = apiTabSize
                case .about:
                    contentSize = aboutTabSize
                }
                if let window = windowRef {
                    let currentFrame = window.frame
                    let newFrame = NSRect(x: currentFrame.minX, y: currentFrame.maxY - contentSize, width: currentFrame.width, height: contentSize)
                    window.setFrame(newFrame, display: true, animate: false)
                }
            }
            .onAppear() {
                if let window = windowRef {
                    let currentFrame = window.frame
                    let newFrame = NSRect(x: currentFrame.minX, y: currentFrame.maxY - generalTabSize, width: currentFrame.width, height: generalTabSize)
                    window.setFrame(newFrame, display: true, animate: false)
                }
            }
    }
}

//
// macOS Sonoma appears to have problems with displaying icons inside TabItems,
// so implementing a TabView with AppKit is the temporary solve...
//
struct TabViewController: NSViewControllerRepresentable {
    @Binding var selectedTab: SettingsTab
    
    func makeNSViewController(context: Context) -> NSTabViewController {
        let tabViewController = NSTabViewController()
        tabViewController.tabStyle = .toolbar
        
        /* General */
        let generalTabViewController = NSHostingController(rootView: GeneralTabView().onAppear() {selectedTab = .general})
        let generalTabItem = NSTabViewItem(viewController: generalTabViewController)
        generalTabItem.label = "General"
        generalTabItem.image = NSImage(systemSymbolName: "gear", accessibilityDescription: generalTabItem.label)
        
        /* API */
        let apiTabViewController = NSHostingController(rootView: ApiTabView().onAppear() {selectedTab = .api})
        let apiTabItem = NSTabViewItem(viewController: apiTabViewController)
        apiTabItem.label = "API"
        apiTabItem.image = NSImage(systemSymbolName: "sparkle", accessibilityDescription: generalTabItem.label)
        
        /* About */
        let aboutTabViewController = NSHostingController(rootView: AboutTabView().onAppear() {selectedTab = .about})
        let aboutTabItem = NSTabViewItem(viewController: aboutTabViewController)
        aboutTabItem.label = "About"
        aboutTabItem.image = NSImage(systemSymbolName: "info", accessibilityDescription: generalTabItem.label)
        
        tabViewController.addTabViewItem(generalTabItem)
        tabViewController.addTabViewItem(apiTabItem)
        tabViewController.addTabViewItem(aboutTabItem)
        
        return tabViewController
    }
    
    func updateNSViewController(_ nsViewController: NSTabViewController, context: Context) {
    }
}

//  ┌────┬────┬────┐
//  ├────┴────┴────┤
//  │ Tabs         │
//  └──────────────┘

let SETTINGS_LABEL_WIDTH: CGFloat = 132

struct Divider: View {
    var body: some View {
        ZStack {
            Rectangle().fill(.separator).frame(height: 1)
        }
    }
}

//
//  ┌──────────────┐
//  │ General Tab  |
//  └──────────────┘
//
struct GeneralTabView: View {
    @Environment(\.colorScheme) var colorScheme
    
    private var startupIsChecked: Binding<Bool> {
        Binding(
            get: { SMAppService.mainApp.status == .enabled },
            set: { newValue in
                do {
                    if newValue {
                        if SMAppService.mainApp.status == .enabled {
                            try? SMAppService.mainApp.unregister()
                        }
                        try SMAppService.mainApp.register()
                    } else {
                        try SMAppService.mainApp.unregister()
                    }
                } catch {
                    print("Failed to \(newValue ? "enable" : "disable") launch at login: \(error.localizedDescription)")
                }
            }
        )
    }
    
    @AppStorage(AppStorageKey.appearancePref) var appStorage_appearance: AppearancePreference = DEFAULT_APPEARANCE_PREFERENCE
    @AppStorage(AppStorageKey.windowStylePref) var appStorage_windowStyle: WindowStylePreference = DEFAULT_WINDOW_STYLE_PREFERENCE
    
    var isPinnable: Bool {
        return appStorage_windowStyle == .pinnable
    }
    var isWindowed: Bool {
        return appStorage_windowStyle == .windowed
    }
    
    @State private var userHasGrantedAccessibilityPermission = false
    @State private var pollAccessibilityAccessTimer = Timer.publish(every: 1.0, on: .current, in: .common).autoconnect()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16.0) {
            /* Appearance Preference */
            HStack(alignment: .top) {
                HStack {
                    Spacer()
                    Text("Appearance")
                        .font(.headline)
                    
                }
                .frame(width: SETTINGS_LABEL_WIDTH)
                VStack(alignment: .leading) {
                    Picker(selection: $appStorage_appearance, label: EmptyView()) {
                        Text("Light").tag(AppearancePreference.light)
                        Text("Dark").tag(AppearancePreference.dark)
                        Text("Use system setting").tag(AppearancePreference.system)
                    }
                    .pickerStyle(.inline)
                }
                Spacer()
            }
            .onChange(of: appStorage_appearance) {
                NotificationCenter.default.post(name: .appearanceChangedFromSettings, object: nil)
            }
            
            Divider()
            
            /* Window Style */
            HStack(alignment: .top) {
                HStack {
                    Spacer()
                    Text("Window Style")
                        .font(.headline)
                }
                .frame(width: SETTINGS_LABEL_WIDTH)
                VStack(spacing: 6.0) {
                    
                    HStack {
                        HStack(spacing: 16.0) {
                            VStack {
                                Image("SettingsPinnableIcon")
                                    .resizable()
                                    .frame(width:100, height: 66)
                                    .mask {
                                        RoundedRectangle(cornerRadius: 8)
                                    }
                                    .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 2)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(isPinnable ? .blue : .white.opacity(0.15), lineWidth: isPinnable ? 2.0 : 0.5)
                                    )
                                Text("Pinnable")
                                    .font(.system(size: 11, weight: isPinnable ? .bold : .regular))
                                    .foregroundStyle(isPinnable ? .primary : .secondary)
                                
                            }
                            .onTapGesture {
                                appStorage_windowStyle = .pinnable
                                NotificationCenter.default.post(name: .windowStyleChangedFromSettings, object: nil)
                            }
                            VStack {
                                Image("SettingsWindowedIcon")
                                    .resizable()
                                    .frame(width:100, height: 66)
                                    .mask {
                                        RoundedRectangle(cornerRadius: 8)
                                    }
                                    .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 2)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(isWindowed ? .blue : .white.opacity(0.15), lineWidth: isWindowed ? 2.0 : 0.5)
                                    )
                                Text("Traditional")
                                    .font(.system(size: 11, weight: appStorage_windowStyle == .windowed ? .bold : .regular))
                                    .foregroundStyle(appStorage_windowStyle == .windowed ? .primary : .secondary)
                                
                            }
                            .onTapGesture {
                                appStorage_windowStyle = .windowed
                                NotificationCenter.default.post(name: .windowStyleChangedFromSettings, object: nil)
                            }
                        }
                        Spacer()
                    }
                    HStack {
                        if(isPinnable) {
                            Text("Transient window disappears when clicked outside of it. Can be pinned by clicking the Pin icon or dragging the window.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        else {
                            Text("Traditional window with traffic lights that has to be manually closed. \n")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                }
            }
            
            Divider()
            
            /* Launch Preference */
            HStack(alignment: .top) {
                HStack {
                    Spacer()
                    Text("Auto-Launch")
                        .font(.headline)
                    
                }
                .frame(width: SETTINGS_LABEL_WIDTH)
                VStack(alignment: .leading) {
                    Toggle(isOn: startupIsChecked) {
                        Text("Launch app on startup")
                    }
                }
                Spacer()
            }
            
            Divider()
            
            VStack(spacing: 24.0) {
                /* Shortcut Preference */
                HStack(alignment: .top) {
                    HStack {
                        Spacer()
                        Text("Shortcut")
                            .font(.headline)
                    }
                    .frame(width: SETTINGS_LABEL_WIDTH)
                    VStack(alignment: .leading) {
                        KeyboardShortcuts.Recorder("", name: .toggleAppWindow)
                            .offset(x: -6.0)
                        HStack {
                            Text("The shortcut only triggers if Origami Studio is active.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    Spacer()
                }
                VStack(alignment: .leading, spacing: 16.0){
                    HStack {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Open JavaScript Patch via Shortcut")
                                .bold()
                            Text("\(APP_NAME) makes it possible to open a selected JavaScript Patch file via the keyboard shortcut. For this to work, the app requires the **Privacy & Security > Accessibility** permission in order to programmatically copy the JavaScript Patch to the clipboard.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    HStack(spacing:0){
                        ZStack{
                            Image(systemName: userHasGrantedAccessibilityPermission ? "gear.badge.checkmark" : "gear.badge.questionmark")
                                .resizable()
                                .symbolRenderingMode(.multicolor)
                                .frame(width: 32, height: 28)
                        }
                        .frame(
                            minWidth: 0,
                            maxWidth: 100,
                            minHeight: 0,
                            maxHeight: .infinity
                        )
                        .background(colorScheme == .light ? .white.opacity(0.5) : .white.opacity(0.05))
                        
                        ZStack{
                            if userHasGrantedAccessibilityPermission {
                                VStack{
                                    Text("**Privacy & Security > Accessibility** permission has been granted.")
                                        .multilineTextAlignment(.center)
                                        .font(.subheadline)
                                    Text("Select a JavaScript Patch in the Origami Studio Patch Editor and hit the shortcut.")
                                        .multilineTextAlignment(.center)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                
                            } else {
                                Button("Grant Accessibility Permission") {
                                    openAccessibilityPermissionPrompt()
                                }
                                .buttonStyle(CustomButtonStyle(buttonType: .primary, py: 2.0, px: 8.0))
                            }
                        }
                        .frame(
                            minWidth: 0,
                            maxWidth: .infinity,
                            minHeight: 0,
                            maxHeight: .infinity
                        )
                    }
                    .frame(height: 100)
                    .background(colorScheme == .light ? .white.opacity(0.25) : .white.opacity(0.05))
                    .cornerRadius(8.0)
                }
            }
        }
        .padding()
        .onAppear {
            userHasGrantedAccessibilityPermission = checkIfUserHasGrantedAccessibilityPermission()
        }
        .onReceive(pollAccessibilityAccessTimer) { _ in
            userHasGrantedAccessibilityPermission = checkIfUserHasGrantedAccessibilityPermission()
        }
    }
}

//
//  ┌──────────────┐
//  │ API Tab      |
//  └──────────────┘
//
struct ApiTabView: View {
    private let debouncer = Debouncer()
    
    /* @AppStorage */
    @AppStorage(AppStorageKey.apiKey) var appStorage_apiKey: String = "..."
    @AppStorage(AppStorageKey.orgId) var appStorage_orgId: String = ""
    @AppStorage(AppStorageKey.modelPreference) var appStorage_modelPreference: String = DEFAULT_MODEL
    @AppStorage(AppStorageKey.customModelString) var appStorage_customModelName: String = ""
    @AppStorage(AppStorageKey.instructionText) var appStorage_instructionText: String = DEFAULT_INSTRUCTION
    
    /* Local state */
    @State private var apiKeyValidationErrorMessage: String = ""
    @State var apiKeyValidationState: ValidationState = .pending
    @State private var tempInstructionText: String = ""
    
    /* Computed */
    var apiModelOptions: [ApiModelPickerOption] {
        let cmName = appStorage_customModelName
        let customDisplayName = appStorage_customModelName.isEmpty ? "Custom" : "Custom (\(cmName))"
        let customOption = ApiModelPickerOption(displayName: customDisplayName, value: "custom")
        
        let options = [
            ApiModelPickerOption(displayName: "gpt-4-1106-preview", value: "gpt-4-1106-preview"),
            ApiModelPickerOption(displayName: "gpt-4", value: "gpt-4"),
            ApiModelPickerOption(displayName: "gpt-4-32k", value: "gpt-4-32k"),
            ApiModelPickerOption(displayName: "gpt-4-0613", value: "gpt-4-0613"),
            ApiModelPickerOption(displayName: "gpt-4-32k-0613", value: "gpt-4-32k-0613"),
            ApiModelPickerOption(displayName: "gpt-3.5-turbo-1106", value: "gpt-3.5-turbo-1106"),
            ApiModelPickerOption(displayName: "gpt-3.5-turbo", value: "gpt-3.5-turbo"),
            customOption,
        ]
        return options
    }
    
    var apiKeySubtitleText: AttributedString {
        let urlWithoutHttps = "platform.openai.com/account/api-keys"
        var result = AttributedString("Enter your OpenAI API Key. You can find your API key at \(urlWithoutHttps).")
        let linkRange = result.range(of: urlWithoutHttps)!
        result[linkRange].link = URL(string: "https://\(urlWithoutHttps)")
        result[linkRange].underlineStyle = Text.LineStyle(pattern: .solid)
        result[linkRange].foregroundColor = .secondary
        return result
    }
    
    var modelSubtitleText: AttributedString {
        let urlWithoutHttps = "platform.openai.com/docs/models/continuous-model-upgrades"
        var result = AttributedString("Model to be used for code generation. A list of all models can be found at \(urlWithoutHttps).")
        let linkRange = result.range(of: urlWithoutHttps)!
        result[linkRange].link = URL(string: "https://\(urlWithoutHttps)")
        result[linkRange].underlineStyle = Text.LineStyle(pattern: .solid)
        result[linkRange].foregroundColor = .secondary
        return result
    }
    
    var instructionSubtitleText: AttributedString {
        let url = "https://origami.design/documentation/concepts/scriptingapi"
        let urlText = "Origami JavaScript Patch API documentation"
        var result = AttributedString("System instruction sent along with the prompt. The default instruction is a truncated version of the \(urlText).\n\nAny Markdown syntax (Backticks) is automatically stripped from the response.")
        let linkRange = result.range(of: urlText)!
        result[linkRange].link = URL(string: url)
        result[linkRange].underlineStyle = Text.LineStyle(pattern: .solid)
        result[linkRange].foregroundColor = .secondary
        return result
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .top) {
                HStack {
                    Spacer()
                    Text("API Key")
                        .font(.headline)
                }
                .frame(width: SETTINGS_LABEL_WIDTH)
                VStack {
                    ValidateApiKeyView(apiKey: $appStorage_apiKey, validationState: $apiKeyValidationState, errorMessage: $apiKeyValidationErrorMessage, canDismiss: false, hasDismissed: .constant(false))
                        .settingsInputBackground()
                    ZStack {
                        switch apiKeyValidationState {
                        case .pending, .validating:
                            HStack {
                                Text(apiKeySubtitleText)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                        case .invalid:
                            HStack {
                                Text(apiKeyValidationErrorMessage)
                                    .font(.subheadline)
                                    .foregroundColor(.red)
                                Spacer()
                            }
                        case .valid:
                            HStack {
                                Text("Your API Key has been saved.")
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                                Spacer()
                            }
                        }
                    }
                }
            }
        
            
            HStack(alignment: .top) {
                HStack {
                    Spacer()
                    Text("Organization ID")
                        .font(.headline)
                }
                .frame(width: SETTINGS_LABEL_WIDTH)
                VStack {
                    TextField("Optional", text: $appStorage_orgId)
                        .textFieldStyle(PlainTextFieldStyle())
                        .padding(EdgeInsets(top: 0, leading: 8, bottom: 0, trailing: 8))
                        .font(.system(size: 12, design: .monospaced))
                        .frame(height: 34)
                        .settingsInputBackground()
                }
            }
            
            Divider()
            
            /* Model Preference */
            HStack(alignment: .top) {
                HStack {
                    Spacer()
                    Text("Model")
                        .font(.headline)
                }
                .frame(width: SETTINGS_LABEL_WIDTH)
                
                VStack(alignment: .leading) {
                    HStack {
                        Picker(selection: $appStorage_modelPreference, label: EmptyView()) {
                            ForEach(apiModelOptions, id: \.value) { option in
                                Text(option.displayName).tag(option.value)
                            }
                        }
                        .frame(maxWidth: 196)
                        .id(appStorage_customModelName)
                        if(appStorage_modelPreference == "custom") {
                            TextField("Model Name", text: $appStorage_customModelName)
                                .textFieldStyle(PlainTextFieldStyle())
                                .padding(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
                                .background()
                                .cornerRadius(4.0)
                        }
                    }
                    HStack {
                        Text(modelSubtitleText)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Divider()
            
            /* Instruction Text */
            HStack(alignment: .top) {
                HStack {
                    Spacer()
                    Text("Instruction")
                        .font(.headline)
                }
                .frame(width: SETTINGS_LABEL_WIDTH)
                VStack {
                    CustomTextEditor(text: $tempInstructionText)
                        .textStyle(.sansBody)
                        .textColor(.primary)
                        .padding(EdgeInsets(top: 8, leading: 4, bottom: 0, trailing: 4))
                        .settingsInputBackground()
                        .onChange(of: tempInstructionText) { _, newValue in
                            debouncer.callback = {
                                appStorage_instructionText = newValue
                            }
                            debouncer.debounce(delay: 0.05)
                        }
                        .onAppear() {
                            tempInstructionText = appStorage_instructionText
                        }
                    VStack {
                        HStack {
                            Text(instructionSubtitleText)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        if(appStorage_instructionText != DEFAULT_INSTRUCTION) {
                            Button("Reset to Default Instruction") {
                                appStorage_instructionText = DEFAULT_INSTRUCTION
                                tempInstructionText = appStorage_instructionText
                            }
                            .buttonStyle(.borderless)
                            .foregroundColor(.blue)
                            .font(.subheadline)
                        }
                    }
                }
            }
        }
        .padding()
    }
}

//
//  ┌──────────────┐
//  │ About Tab    |
//  └──────────────┘
//
struct AboutTabView: View {
    var body: some View {
        
        HStack(alignment: .top, spacing: 32.0) {
            Image(nsImage: NSImage(named: "AppIcon") ?? NSImage())
                .offset(y: -12)
            VStack(alignment: .leading, spacing: 20.0) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2.0) {
                        Text("Kami")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.primary)
                        Spacer().frame(height: 8)
                        Text("Author")
                            .font(.system(size: 11, weight: .regular))
                            .foregroundColor(.secondary.opacity(0.5))
                        Text("Acknowledgements")
                            .font(.system(size: 11, weight: .regular))
                            .foregroundColor(.secondary.opacity(0.5))
                    }
                    Spacer()
                    VStack(alignment: .leading, spacing: 2.0) {
                        Text("\(APP_VERSION)")
                            .font(.system(size: 14, weight: .light))
                            .foregroundColor(.primary.opacity(0.5))
                        Spacer().frame(height: 8)
                        Text("Alex Widua")
                            .font(.system(size: 11, weight: .regular))
                            .foregroundColor(.secondary)
                        Text("Luke Haddock, George Kedenburg III for their Origami-GPT-4 experiments and instruction texts, Matthew Mang for their GPT-4 Origami Patch.")
                            .font(.system(size: 11, weight: .regular))
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: 300)
                HStack {
                    Button("View Project on GitHub") {
                        // TODO: Insert URL
                        if let url = URL(string: URL_GITHUB) {
                            NSWorkspace.shared.open(url)
                        }
                    }
                    .buttonStyle(CustomButtonStyle(buttonType: .primary, py: 2.0, px: 8.0))
                    Button("Origami Community") {
                        // TODO: Insert URL
                        if let url = URL(string: URL_ORIGAMI_COMMUNITY) {
                            NSWorkspace.shared.open(url)
                        }
                    }
                    .buttonStyle(CustomButtonStyle(buttonType: .regular, py: 2.0, px: 8.0))
                }
                .padding(.top, 8)
            }
        }
        .offset(x: -16) // nudge view to the left for visual balance
    }
}

//
// Misc
//
struct SettingsInputBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(RoundedRectangle(cornerRadius: 0)
                .foregroundStyle(
                    .background
                        .shadow(.inner(color: .black.opacity(0.125), radius: 0, x: 0, y: 1))
                        .shadow(.inner(color: .white.opacity(0.1), radius: 1, x: 0, y: -1))
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(.white.opacity(0.25), lineWidth: 0.5)
            )
            .cornerRadius(8.0)
    }
}

extension View {
    func settingsInputBackground() -> some View {
        self.modifier(SettingsInputBackground())
    }
}
