//
//  The app's main content window
//
//  ┌──────────────────────────────┐
//  │ Onboarding                   •─── Displayed until API key is set for the first time
//  ├──────────────────────────────┤
//  │ Prompt Input                 •─── Resizeable prompt Input with [Enter] button
//  ├──────────────────────────────┤
//  │ Code Editor                  •─── (Rudimentary) Code editor with syntax highlighting
//  ├──────────────────────────────┤
//  │ Toolbar                      •─── [Open settings], [Open with...] and [Save] and optional file information
//  └──────────────────────────────┘
//

import SwiftUI
import OpenAI

#Preview {
    ContentView(windowRef: nil)
}

struct ContentView: View {
    @Environment(\.colorScheme) var colorScheme
    @StateObject var appState = AppState.shared
    let windowRef: AppWindow?
    
    /* AppStorage */
    @AppStorage(appearancePreferenceStorageKey) var appStorage_appearance: AppearancePreference = .system
    @AppStorage(apiKeyStorageKey) var appStorage_apiKey: String = ""
    @AppStorage(instructionStorageKey) var appStorage_instructionText: String = DEFAULT_INSTRUCTION
    @AppStorage(modelPreferenceStorageKey) var appStorage_modelPreference: String = DEFAULT_MODEL
    @AppStorage(customModelPreferenceStorageKey) var appStorage_customModelName: String = ""
    @AppStorage(showOpenWithPreferenceStorageKey) var appStorage_showOpenWithBtn: Bool = DEFAULT_SHOW_OPEN_WITH_BTN
    @AppStorage(showFileNamePreferenceStorageKey) var appStorage_showFileName: Bool = DEFAULT_SHOW_FILE_NAME
    
    /* API Call Stuff */
    @State private var streamResponseTask: Task<Void, Never>?
    @State private var isLoadingResponse: Bool = false
    @State private var hasCancelledTask: Bool = false
    
    /* Prompt Input Things */
    let promptInputMinHeight: CGFloat = 100
    let promptInputMaxHeight: CGFloat = 200
    @State private var promptInputHeight: CGFloat = 200
    @State private var promptInputText: String = ""
    
    /* Misc UI Thingz */
    @State private var showNotificationBanner: Bool = false
    @State private var notificationBannerMsg: String = ""
    
    @State private var animateCodeEditorLoadingState: Bool = false
    let bottomBarHeight: CGFloat = 36
    
    /* Computed */
    var currentFileName: String {
        return getFileNameFromPathString(appState.filePathString)
    }
    
    var selectedModel: String {
        if(appStorage_modelPreference == "custom") {
            return appStorage_customModelName
        }
        else {
            return appStorage_modelPreference
        }
    }
    
    
    var inputForegroundColor: Color {
        if(!appStorage_hasCompletedOnboarding || isLoadingResponse || promptInputText.isEmpty) { return .secondary }
        else { return .primary }
    }
    
    var inputDisabled: Bool {
        return (!appStorage_hasCompletedOnboarding || isLoadingResponse || appState.isParsingPasteboardFile)
    }
    
    var submitPromptButtonDisabled: Bool {
        return !appStorage_hasCompletedOnboarding || promptInputText.isEmpty || appState.isParsingPasteboardFile
    }
    
    var saveButtonDisabled: Bool {
        return (!appStorage_hasCompletedOnboarding || appState.hasSavedFile || appState.isSavingFile || appState.filePathString.isEmpty || appState.fileContent.isEmpty) || appState.isParsingPasteboardFile
    }
    
    var openWithButtonDisabled: Bool {
        return (!appStorage_hasCompletedOnboarding || appState.hasSavedFile || appState.isSavingFile || appState.filePathString.isEmpty || appState.fileContent.isEmpty) || appState.isParsingPasteboardFile
    }
    
    /* Onboarding specific stuff */
    //        @AppStorage(hasCompletedOnboardingStorageKey) var appStorage_hasCompletedOnboarding: Bool = false
    // TODO:
    @State var appStorage_hasCompletedOnboarding: Bool = true
    @State private var onboardingValidationState: ValidationState = .pending
    @State private var onboardingErrorMessage: String = ""
    @State private var onboardingHasInteractedWithDismissButton: Bool = false
    
    var onboardingSubtitleText: AttributedString {
        let urlWithoutHttps = "platform.openai.com/account/api-keys"
        var result = AttributedString("Enter your OpenAI API Key. You can find your API key at \(urlWithoutHttps).\nYour API key is only stored locally on your machine.")
        let linkRange = result.range(of: urlWithoutHttps)!
        result[linkRange].link = URL(string: "https://\(urlWithoutHttps)")
        result[linkRange].underlineStyle = Text.LineStyle(pattern: .solid)
        result[linkRange].foregroundColor = .white
        return result
    }
    
    private var onboardingBackground: Color {
        switch onboardingValidationState {
        case .pending:
            return .blue
        case .validating:
            return .blue
        case .invalid:
            return .red
        case .valid:
            return .green
        }
    }
    
    var body: some View {
        VStack(spacing:0) {
            //
            //  ┌──────────────────┐
            //  │ Onboarding Flow  |
            //  └──────────────────┘
            //
            //  Onboarding flow that is displayed until user has entered a valid API key for the first time.
            //  Consecutive API key changes are done via the settings menu, which can be invoked via the toolbar icon
            //  or the tray icon at the top.
            //
            if(!appStorage_hasCompletedOnboarding) {
                VStack(spacing:0) {
                    ZStack {
                        ValidateApiKeyView(apiKey: $appStorage_apiKey, validationState:  $onboardingValidationState, errorMessage: $onboardingErrorMessage, canDismiss: true, hasDismissed: $onboardingHasInteractedWithDismissButton, validationInputStyle: .onboarding)
                            .onChange(of: onboardingHasInteractedWithDismissButton) { _, hasDismissed in
                                if(hasDismissed) {
                                    appStorage_hasCompletedOnboarding = true
                                }
                            }
                    }
                    .padding(0.0)
                    ZStack {
                        switch onboardingValidationState {
                        case .pending, .validating:
                            HStack {
                                Text(onboardingSubtitleText)
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                                Spacer()
                            }
                        case .invalid:
                            HStack {
                                Text(onboardingErrorMessage)
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                                Spacer()
                            }
                        case .valid:
                            HStack {
                                Text("Your API Key has been saved. You can change it in the settings anytime.")
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                                Spacer()
                            }
                        }
                    }
                    .padding([.leading, .bottom, .trailing], 8.0)
                    
                }
                .padding(0.0)
                .background(onboardingBackground)
            }
            //
            //  ┌──────────────────┐
            //  │ Prompt Input     |
            //  └──────────────────┘
            //
            //  Prompt Input for prompt that gets emitted to the GPT model.
            //  Prompt is emitted by either clicking the [􀅇 Enter] button or hitting the Enter key.
            //  Input is resizeable on the Y-axis (although the resize constrained to 100dp ...
            //  TODO: Increase resize constraints?
            //
            VStack(spacing: 0) {
                ZStack {
                    /* Title bar */
                    VStack(spacing: 0) {
                        HStack {
                            Text(APP_NAME.uppercased())
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.primary.opacity(0.2))
                            Spacer()
                        }
                        .padding(.top, 10.0)
                        .padding(.horizontal, 12.0)
                        /* Prompt Editor */
                        HStack(alignment: .top) {
                            ZStack {
                                if promptInputText.isEmpty {
                                    CustomTextEditor(text:.constant("Prompt..."))
                                        .disabled(true)
                                        .textStyle(.sansLarge)
                                        .textColor(inputForegroundColor)
                                        .padding(EdgeInsets(top: 2, leading: 4, bottom: 0, trailing: 4))
                                }
                                CustomTextEditor(text: isLoadingResponse ? .constant(promptInputText) : $promptInputText)
                                    .disabled(inputDisabled)
                                    .textStyle(.sansLarge)
                                    .textColor(inputForegroundColor)
                                    .padding(EdgeInsets(top: 2, leading: 4, bottom: 0, trailing: 4))
                                    .onChange(of: promptInputText) { oldValue, newValue in
                                        // intercept enter/line break and use as shortcut, bc regular shortuts do not work while text editor is focussed
                                        if let lastChar = newValue.last, lastChar == "\n", oldValue != newValue {
                                            promptInputText.removeLast()
                                            handleCompletion()
                                        }
                                    }
                                    .onChange(of: appState.filePathString) { _, _ in
                                        promptInputText = ""
                                    }
                            }
                            .padding(.horizontal, 0.0)
                            
                            /* Submit Prompt Button */
                            ZStack {
                                Button(action: {
                                    if(isLoadingResponse) {  handleCancelCurrentCompletionTask() }
                                    else { handleCompletion() }
                                }) {
                                    HStack {
                                        if isLoadingResponse {
                                            // ProgressView()
                                            // .controlSize(.small)
                                            // Spacer().frame(width:8)
                                            Text("Cancel")
                                        }
                                        else {
                                            Image(systemName: "return")
                                        }
                                    }
                                }
                                .disabled(submitPromptButtonDisabled)
                                .buttonStyle(CustomButtonStyle(buttonType: isLoadingResponse ? .regular : .primary))
                            }
                            .padding(8.0)
                        }
                        Spacer()
                    }
                    
                    /* Resize Handle */
                    VStack(spacing: 0) {
                        Spacer()
                        VStack(spacing: 0) {
                            Rectangle()
                                .fill(.clear)
                                .frame(height: 4)
                                .allowsHitTesting(true)
                                .contentShape(Rectangle())
                            Rectangle()
                                .fill(Color("ResizeGutter"))
                                .frame(height: 1)
                        }
                        .gesture(
                            DragGesture()
                                .onChanged { gesture in
                                    $promptInputHeight.wrappedValue += gesture.translation.height
                                    if $promptInputHeight.wrappedValue < promptInputMinHeight {
                                        $promptInputHeight.wrappedValue = promptInputMinHeight
                                    }
                                    else if $promptInputHeight.wrappedValue > promptInputMaxHeight {
                                        $promptInputHeight.wrappedValue = promptInputMaxHeight
                                    }
                                }
                        )
                        .onHover(perform: { hovering in
                            DispatchQueue.main.async {
                                if let window = windowRef {
                                    if (hovering) {
                                        window.isMovable = false
                                        
                                        if($promptInputHeight.wrappedValue == promptInputMinHeight) {
                                            NSCursor.resizeDown.set()
                                        }
                                        else if ($promptInputHeight.wrappedValue == promptInputMaxHeight) {
                                            NSCursor.resizeUp.set()
                                        }
                                        else {
                                            NSCursor.resizeUpDown.set()
                                        }
                                    } else {
                                        window.isMovable = true
                                        NSCursor.arrow.set()
                                    }
                                }
                                
                            }
                        })
                    }
                }
                .background(.ultraThickMaterial)
                .frame(height: promptInputHeight)
                //
                //  ┌──────────────────┐
                //  │ Code Editor      |
                //  └──────────────────┘
                //
                //  Rudimentary code editor with JavaScript syntax highlighting,
                //  line numbers and auto-indent/auto-brackets.
                //
                ZStack {
                    CustomJavascriptEditor(text: $appState.fileContent)
                        .frame(minHeight: 0)
                        .disabled(inputDisabled)
                        .onChange(of: appState.fileContent) { oldValue, newValue in
                            if(oldValue != newValue) {
                                appState.hasSavedFile = false
                            }
                        }
                        .id(appState.filePathString)
                        .blur(radius: animateCodeEditorLoadingState ? 16 : 0)
                        .opacity(animateCodeEditorLoadingState ? 0 : 1)
                        .opacity(inputDisabled ? 0.125 : 1)
                    VStack {
                        Spacer()
                        NotificationBannerView(isShowing: $showNotificationBanner, message: notificationBannerMsg, notifStyle: .warning)
                    }
                    .onAppear {
                        NotificationCenter.default.addObserver(forName: .bannerNotification, object: nil, queue: .main) { notification in
                            if let msg = notification.userInfo?["msg"] as? String {
                                showNotificationBanner = true
                                notificationBannerMsg = msg
                            }
                        }
                    }
                    if(isLoadingResponse) {
                        ZStack {
                            ProgressView()
                                .controlSize(.small)
                        }
                    }
                }
                .background(.windowBackground)
            }
            if(appState.isParsingPasteboardFile) {
                ZStack {
                    Color(.black.opacity(0.5))
                    ProgressView()
                        .controlSize(.small)
                }
            }
            //
            //  ┌──────────────────┐
            //  │ Toolbar          |
            //  └──────────────────┘
            //
            //  Bottom Toolbar with [􀍢 Settings], [Open with...] and [Save] button.
            //  Right-clicking the toolbar invokes a context menu to show/hide certain information
            //
            HStack(alignment: .center, spacing: 0.0) {
                Menu {
                    Button("Settings...") {
                        handleOpenSettingsWindow()
                    }
                    Button("Quit") {
                        handleQuitApp()
                    }
                } label: {
                    Image(systemName: "ellipsis.circle.fill")
                        .foregroundStyle(.primary, .primary.opacity(0.1))
                }
                .menuStyle(.borderlessButton)
                .fixedSize()
                .menuIndicator(.hidden)
                // it doesn't seem possible to adjust the Button/Label size of menu buttons on macOS – hacky workaround using scaleEffect and manual offsetting
                .scaleEffect(1.5)
                .offset(x: -2 ,y: 0)
                if(appStorage_showFileName && !appState.filePathString.isEmpty) {
                    Text(currentFileName)
                        .font(.system(size: 12, weight: .regular, design: .monospaced))
                        .foregroundColor(.secondary.opacity(0.5))
                }
                Spacer()
                if(appStorage_showOpenWithBtn) {
                    OpenWithMenuView()
                        .frame(width: 100)
                        .disabled(openWithButtonDisabled)
                        .buttonStyle(CustomButtonStyle(buttonType: .regular, py: 2.0, px: 8.0))
                }
                Button(appState.isSavingFile ? "Saving..." : appState.hasSavedFile ? "Saved" : "Save") {
                    handleSaveFile()
                }
                .disabled(saveButtonDisabled)
                .buttonStyle(CustomButtonStyle(buttonType: .primary, py: 2.0, px: 8.0))
                
            }
            .onTapGesture(count: 2, perform: {
            })
            .contentShape(Rectangle())
            .contextMenu {
                Button {
                    appStorage_showFileName = !appStorage_showFileName
                } label: {
                    // Sonoma doesn't show label icons properly, so we cheese it for now...
                    Text("\(appStorage_showFileName ? "􀆅" : "    ") File Name")
                }
                
                Button {
                    appStorage_showOpenWithBtn = !appStorage_showOpenWithBtn
                } label: {
                    Text("\(appStorage_showOpenWithBtn ? "􀆅" : "    ") Open With...")
                }
            }
            .padding(.horizontal, 8.0)
            .frame(height: bottomBarHeight)
            .background(.windowBackground)
            
        }
        // If the user opens another patch while the API call is still running, cancel...
        // TODO: This might be redundant as we already safeguard against that inside the fetchStreamCompletion() fn
        .onChange(of: appState.filePathString) {
            if(isLoadingResponse) {
                handleCancelCurrentCompletionTask()
            }
        }
        // Respond to Appearance Preference changes made in the app's settings window
        .onChange(of: appStorage_appearance) {
            if let window = windowRef {
                window.appearance = getPreferredAppearance(pref: appStorage_appearance)
            }
        }
    }
    
    func handleCompletion() {
        hasCancelledTask = false
        // remove focus from TextEditor
        DispatchQueue.main.async {
            NSApp.keyWindow?.makeFirstResponder(nil)
        }
        isLoadingResponse = true
        fetchStreamCompletion()
    }
    
    // Fetch and stream the code completion.
    // We prepend the Prompt and Patch's Script ID.
    func fetchStreamCompletion() {
        let ogFileContent = appState.fileContent
        let documentHead = fileDocumentHead(fileContent: appState.fileContent)
        appState.fileContent = documentHead
        
        animateCodeEditorLoadingState = true
        Task {
            let queryFileName = currentFileName
            var hasApiError = false
            
            for await streamResult in streamCompletion(task: $streamResponseTask, apiKey: appStorage_apiKey, instructionText: appStorage_instructionText, inputText: promptInputText, model: selectedModel) {
                
                
                switch streamResult {
                case .completion(let completion):
                    
                    if(completion.tokenIndex == 0) {
                        withAnimation(.linear(duration: 1.5)) {
                            animateCodeEditorLoadingState = false
                        }
                    }
                    
                    appState.fileContent += completion.token
                case .error(let error):
                    showNotificationBanner = true
                    notificationBannerMsg = error.message
                    hasApiError = true
                    
                }
            }
            isLoadingResponse = false
            
            // Catch if new files was opened while generating
            if(queryFileName != currentFileName) {
                appState.fileContent = ogFileContent
                showNotificationBanner = true
                notificationBannerMsg = "JavaScript Patch changed while generating. Previous file was restored."
            }
            
            if(hasApiError) {
                appState.fileContent = ogFileContent
            }
            else {
                handleSaveFile()
            }
        }
    }
    
    func handleCancelCurrentCompletionTask() {
        print("*** [handleCancelCurrentCompletionTask] Asked Task (Handle Fetch Response) to be cancelled...")
        streamResponseTask?.cancel()
        isLoadingResponse = false
        hasCancelledTask = true
    }
    
    /* Assemble file head with the original prompt and script id */
    func fileDocumentHead(fileContent: String) -> String {
        let prompt = promptInputText
        let firstLine = "// Prompt: \(prompt) \n"
        var secondLine = ""
        if let scriptId = extractScriptID(from: fileContent) {
            secondLine = "//\n// Script ID: \(scriptId) \n"
        }
        return "\(firstLine)\(secondLine)"
    }
    
    func handleSaveFile() {
        if(hasCancelledTask) {
            print("*** [handleSaveFile] Cancelled task, skipped saving")
            return
        }
        saveFile(filePathString: $appState.filePathString, isSavingFile: $appState.isSavingFile, hasSavedFile: $appState.hasSavedFile, fileContent: $appState.fileContent)
    }
    
    func handleQuitApp() {
        NSApplication.shared.terminate(nil)
    }
    
    func handleOpenSettingsWindow() {
        let _ = setupSettingsWindow(openAppWindowAfterClose: true)
    }
}


