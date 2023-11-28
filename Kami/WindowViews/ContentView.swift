//
//  The app's main content window
//  ┌──────────────────────────────┐
//  │ Prompt Input                 •─── Resizeable prompt Input with [Enter] button
//  ├──────────────────────────────┤
//  │ Code Editor                  •─── (Rudimentary) Code editor with syntax highlighting
//  ├──────────────────────────────┤
//  │ Toolbar                      •─── [Open settings], [Open with...] and [Save] and optional file information
//  └──────────────────────────────┘
//

import SwiftUI

#Preview {
    ContentView(window: nil, url: URL(string: "/")!)
}

struct ContentView: View {
    @Environment(\.controlActiveState) var controlActiveState
    @Environment(\.colorScheme) var colorScheme
    @StateObject var appState = AppState.shared
    
    /* AppStorage States */
    @AppStorage(AppStorageKey.finishedOnboarding) var appStorage_finishedOnboarding: Bool = false
    @AppStorage(AppStorageKey.appearancePref) var appStorage_appearance: AppearancePreference = DEFAULT_APPEARANCE_PREFERENCE
    @AppStorage(AppStorageKey.windowStylePref) var appStorage_windowStyle: WindowStylePreference = DEFAULT_WINDOW_STYLE_PREFERENCE
    @AppStorage(AppStorageKey.apiKey) var appStorage_apiKey: String = ""
    @AppStorage(AppStorageKey.instructionText) var appStorage_instructionText: String = DEFAULT_INSTRUCTION
    @AppStorage(AppStorageKey.modelPreference) var appStorage_modelPreference: String = DEFAULT_MODEL
    @AppStorage(AppStorageKey.customModelString) var appStorage_customModelName: String = ""
    @AppStorage(AppStorageKey.showOpenWithBtnPref) var appStorage_showOpenWithBtn: Bool = DEFAULT_SHOW_OPEN_WITH_BTN
    @AppStorage(AppStorageKey.showFileNamePref) var appStorage_showFileName: Bool = DEFAULT_SHOW_FILE_NAME
    
    /* Props */
    let window: AppWindow?
    var url: URL
    @State private var fileContent: String = ""
    
    /* API Call Stuff */
    @State private var streamResponseTask: Task<Void, Never>?
    @State private var isLoadingResponse: Bool = false
    @State private var hasCancelledTask: Bool = false
    
    /* Prompt Input Things */
    let promptInputMinHeight: CGFloat = 100
    let promptInputMaxHeight: CGFloat = 200
    @State private var promptInputHeight: CGFloat = 150
    @State private var promptInputText: String = ""
    
    /* Misc UI*/
    @State private var showNotificationBanner: Bool = false
    @State private var notificationBannerMsg: String = ""
    @State private var isSavingFile = false
    @State private var hasSavedFile = false
    @State private var animateCodeEditorLoadingState: Bool = false
    
    /* Computed */
    var currentFileName: String {
        return getFileNameFromPathString(url.absoluteString)
    }
    
    var selectedModel: String {
        if(appStorage_modelPreference == "custom") {
            return appStorage_customModelName
        }
        else {
            return appStorage_modelPreference
        }
    }
    
    var promptInputFgColor: Color {
        if(!appStorage_finishedOnboarding || isLoadingResponse || promptInputText.isEmpty) { return .secondary }
        else { return .primary }
    }
    
    var promptInputEdgeInset: EdgeInsets {
        switch appStorage_windowStyle {
        case .pinnable:
            return EdgeInsets(top: 14, leading: 4, bottom: 0, trailing: 4)
        case .windowed:
            return EdgeInsets(top: 10, leading: 4, bottom: 0, trailing: 4)
        }
    }
    
    var promptSubmitBtnYPadding: CGFloat {
        switch appStorage_windowStyle {
        case .pinnable:
            return 12.0
        case .windowed:
            return 8.0
        }
    }
    
    var inputDisabled: Bool { return (!appStorage_finishedOnboarding || isLoadingResponse) }
    var submitPromptButtonDisabled: Bool { return !appStorage_finishedOnboarding || promptInputText.isEmpty }
    var toolbarButtonDisabled: Bool { return (!appStorage_finishedOnboarding || hasSavedFile || isSavingFile) }
    
    /* Pinnable Window Titlebar Stuff */
    @State private var windowHovered: Bool = false
    @State private var isPinned: Bool = false
    @State private var titlebarButtonPressed: Bool = false
    @State private var titlebarButtonHover: Bool = false
    
    var body: some View {
        VStack(spacing:0) {
            //  ┌──────────────────┐
            //  │ Onboarding Hint  |
            //  └──────────────────┘
            if(!appStorage_finishedOnboarding) {
                HStack {
                    Text("Please enter a valid API key.")
                        .font(.subheadline)
                    if splashWindow == nil {
                        
                    }
                    Button("Enter API Key") {
                        createSplashWindow()
                    }
                    .font(.subheadline)
                    .buttonStyle(CustomButtonStyle(buttonType: .primary, py: 2.0, px: 8.0))
                    Spacer()
                }
                .padding(.horizontal, 12.0)
                .padding(.vertical, 8.0)
                .background(.blue)
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
                        if(appStorage_windowStyle == .pinnable) {
                            HStack {
                                Rectangle()
                                    .fill(.primary.opacity(titlebarButtonHover ? 0.1 : 0.0))
                                    .cornerRadius(6.0)
                                    .overlay {
                                        ZStack {
                                            Image(systemName: "pin.fill")
                                                .font(.system(size: 12))
                                                .foregroundColor(.primary.opacity(0.5))
                                                .rotationEffect(Angle(degrees: isPinned ? 0 : -45))
                                                .opacity(isPinned ? 0 : 1)
                                                .scaleEffect(isPinned ? 0 : 1)
                                            Image(systemName: "xmark")
                                                .font(.system(size: 12, weight: .medium))
                                                .foregroundColor(.primary.opacity(0.5))
                                                .rotationEffect(Angle(degrees: isPinned ? 0 : -45))
                                                .opacity(isPinned ? 1 : 0)
                                                .scaleEffect(isPinned ? 1 : 0)
                                        }
                                    }
                                    .scaleEffect(titlebarButtonPressed ? 0.9 : 1)
                                    .animation(.spring(duration: 0.4, bounce: 0.25), value: isPinned)
                                    .onHover(perform: { hovering in
                                        titlebarButtonHover = hovering
                                    })
                                    .modifier(MouseEvt(
                                        onMouseDown: {
                                            titlebarButtonPressed = true
                                        },
                                        onMouseUp: {
                                            titlebarButtonPressed = false
                                            if(!isPinned) {
                                                if let window = window {
                                                    window.pinWindow()
                                                    isPinned = true
                                                }
                                            }
                                            else {
                                                if let window = window {
                                                    window.close()
                                                }
                                            }
                                            
                                        }
                                    ))
                                    .offset(x: 6, y: 6)
                                    .frame(width: 24, height: 24)
                                Spacer()
                            }
                            .opacity(windowHovered && controlActiveState != .inactive ? 1 : 0)
                            .animation(.spring(duration: 0.2), value: windowHovered)
                            /* If window is dragged, automatically pin window */
                            .onAppear {
                                NotificationCenter.default.addObserver(forName: .windowDragged, object: nil, queue: .main) { _ in
                                    if let window = window {
                                        if window.isKeyWindow {
                                            isPinned = true
                                        }
                                    }
                                }
                            }
                        }
                        ZStack {
                            /* Prompt Editor */
                            HStack(alignment: .top) {
                                ZStack {
                                    if promptInputText.isEmpty {
                                        CustomTextEditor(text:.constant("Prompt..."))
                                            .disabled(true)
                                            .textStyle(.sansLarge)
                                            .textColor(promptInputFgColor)
                                            .padding(promptInputEdgeInset)
                                    }
                                    CustomTextEditor(text: isLoadingResponse ? .constant(promptInputText) : $promptInputText)
                                        .disabled(inputDisabled)
                                        .textStyle(.sansLarge)
                                        .textColor(promptInputFgColor)
                                        .padding(promptInputEdgeInset)
                                        .onChange(of: promptInputText) { oldValue, newValue in
                                            // intercept enter/line break and use as shortcut, bc regular shortuts do not work while text editor is focussed
                                            if let lastChar = newValue.last, lastChar == "\n", oldValue != newValue {
                                                promptInputText.removeLast()
                                                handleCompletion()
                                            }
                                        }
                                }
                                .padding(.horizontal, 0.0)
                                .opacity(isLoadingResponse ? 0.25 : 1.0)
                                
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
                                .padding(.horizontal, 8.0)
                                .padding(.vertical, promptSubmitBtnYPadding)
                            }
                            Spacer()
                            if(isLoadingResponse) {
                                ProgressView()
                                    .controlSize(.small)
                            }
                        }
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
                                if let window = window {
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
//                .background(.ultraThickMaterial)
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
                    CustomJavascriptEditor(text: $fileContent)
                        .isEditable(!isLoadingResponse)
                        .frame(minHeight: 32)
                        .onChange(of: fileContent) { oldValue, newValue in
                            if(oldValue != newValue) {
                                hasSavedFile = false
                            }
                        }
                        .blur(radius: animateCodeEditorLoadingState ? 16 : 0)
                        .opacity(animateCodeEditorLoadingState ? 0 : 1)
//                        .opacity(inputDisabled ? 0.125 : 1)
                    VStack {
                        Spacer()
                        NotificationBannerView(isShowing: $showNotificationBanner, message: notificationBannerMsg, notifStyle: .warning)
                    }
//                    if(isLoadingResponse) {
//                        ZStack {
//                            ProgressView()
//                                .controlSize(.small)
//                        }
//                    }
                }
                .background(.windowBackground)
            }
            Rectangle().fill(Color("Gutter")).frame(height: 1)
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
                if(appStorage_showFileName) {
                    Spacer().frame(width: 8.0)
                    Text(currentFileName)
                        .font(.system(size: 12, weight: .regular, design: .monospaced))
                        .foregroundColor(.secondary.opacity(0.5))
                }
                Spacer()
                if(appStorage_showOpenWithBtn && window != nil) {
                    OpenWithMenuView(url: url, window: window!)
                        .frame(width: 100)
                        .disabled(toolbarButtonDisabled)
                        .buttonStyle(CustomButtonStyle(buttonType: .regular, py: 2.0, px: 8.0))
                }
                Button(isSavingFile ? "Saving..." : hasSavedFile ? "Saved" : "Save") {
                    handleSaveFile()
                }
                .disabled(toolbarButtonDisabled)
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
            .frame(height: 36)
            .background(.windowBackground)
            
        }
        .background(.ultraThickMaterial)
        .onAppear {
            readFileContent()
        }
        .onAppear {
            NotificationCenter.default.addObserver(forName: .saveFileFromShortcut, object: nil, queue: .main) { _ in
                if let window = window {
                    if window.isKeyWindow {
                        saveFileContent()
                    }
                }
            }
            
        }
        .onHover(perform: { hovering in
            windowHovered = hovering
        })
        .if(appStorage_windowStyle == .pinnable) { view in
            view.edgesIgnoringSafeArea(.top)
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
        let ogFileContent  = fileContent
        let documentHead = fileDocumentHead(fileContent: fileContent)
        fileContent = documentHead
        animateCodeEditorLoadingState = true
        
        Task {
            var hasApiError = false
            
            for await streamResult in streamCompletion(task: $streamResponseTask, apiKey: appStorage_apiKey, instructionText: appStorage_instructionText, inputText: promptInputText, model: selectedModel) {
                
                switch streamResult {
                case .completion(let completion):
                    
                    if(completion.tokenIndex == 0) {
                        withAnimation(.linear(duration: 1.5)) {
                            animateCodeEditorLoadingState = false
                        }
                    }
                    fileContent += completion.token
                    
                case .error(let error):
                    showNotificationBanner = true
                    notificationBannerMsg = error.message
                    hasApiError = true
                }
            }
            isLoadingResponse = false
//            if(hasApiError) {
//                fileContent = ogFileContent
//            }
//            else {
//                handleSaveFile()
//            }
            if(!hasApiError) {
                handleSaveFile()
            }
        }
    }
    
    func handleCancelCurrentCompletionTask() {
        print("*** [handleCancelCurrentCompletionTask] Asked Task (Handle Fetch Response) to be cancelled...")
        streamResponseTask?.cancel()
        isLoadingResponse = false
        hasCancelledTask = true
        
        // cancel out the running blur animation by overriding it (the only way lol)
        withAnimation(.linear(duration: 0.0)) {
            animateCodeEditorLoadingState = true
        }
        withAnimation(.linear(duration: 0.0)) {
            animateCodeEditorLoadingState = false
        }
    }
    
    /* Assemble file head with the original prompt and script id */
    func fileDocumentHead(fileContent: String) -> String {
        let prompt = promptInputText
        let firstLine = "// \(prompt)\n"
        var secondLine = ""
        if let scriptId = extractScriptID(from: fileContent) {
            secondLine = "// Script ID: \(scriptId) \n"
        }
        return "\(firstLine)\(secondLine)"
    }
    
    func handleSaveFile() {
        if(hasCancelledTask) {
            print("*** [handleSaveFile] Cancelled task, skipped saving")
            return
        }
        
        saveFileContent()
    }
    
    func handleQuitApp() {
        NSApplication.shared.terminate(nil)
    }
    
    func handleOpenSettingsWindow() {
        let _ = createSettingsWindow()
    }
    
    // refactor
    private func readFileContent() {
        guard url.isFileURL else { return }
        do {
            fileContent = try String(contentsOf: url, encoding: .utf8)
        } catch {
            print("Error reading file: \(error)")
            fileContent = "Failed to read file"
        }
    }
    
    private func saveFileContent() {
        isSavingFile = true
        DispatchQueue.main.async {
            do {
                try fileContent.write(to: url, atomically: true, encoding: .utf8)
                print("*** [handleSaveFile] File saved successfully")
                isSavingFile = false
                hasSavedFile = true
            } catch {
                print("*** [handleSaveFile] Error saving file: \(error)")
                isSavingFile = false
                hasSavedFile = false
            }
        }
    }
}

