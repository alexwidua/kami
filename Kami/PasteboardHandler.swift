//
// The Pasteboard logic that allows the app to open Origami Studio JavaScript patches via a shortcut.
//
// A detailed breakdown is commented in the code, TL;DR:
//
// 1. The app uses the Accessibility Permission to emulate a Cmd + C keystroke and copy a selected JavaScript Patch to the clipboard.
// 2. After emulating the keystroke, the app reads the clipboard data and looks for the the specific Origami Patch clipboard data format
// 3. If the data is present in the clipboard, it gets converted to a parseable format (Property List) and the filePath of the Javascript patch is read from the data
// 4. The app tries to open the .js file at the given file path... this is the same as the user manually opening the file via the [Open with...] context menu inside Origami.

import SwiftUI

enum OrigamiJavaScriptPatchHandlerError: Error {
    case couldNotPostCommandCopyDownEvent
    case timeout
    case invalidPatchType
    case couldNotConvertBinaryDataToPropertyList
    case couldNotFindPathPropertyInOrigamiPropertyList
    case couldNotFindJavaScriptFileInsideFileDirectory
}

class OrigamiJavaScriptPatchHandler {
    private var startTime: Date?
    private let timeoutInterval: TimeInterval = 1.5
    private let pollInterval: CGFloat = 0.05
    
    func tryToCopyOrigamiJavaScriptPatchAndReadFilePathFromPasteboard() async -> Result<String, OrigamiJavaScriptPatchHandlerError> {
        let pasteboard = NSPasteboard.general
        var tempPasteboard: [NSPasteboardItem] = []
        
        // 1. Store current clipboard and clear it
        if let items = pasteboard.pasteboardItems {
                for item in items {
                    let copiedItem = NSPasteboardItem()
                    for type in item.types {
                        if let data = item.data(forType: type) {
                            copiedItem.setData(data, forType: type)
                        }
                    }
                    tempPasteboard.append(copiedItem)
                }
            }
        pasteboard.clearContents()
        
        // 2. Trigger copy action by emulating ⌘ + C.
        guard postCommandCopyDownEvent() else {
            return .failure(.couldNotPostCommandCopyDownEvent)
        }
        
        // 3. Do the thing
        let result = await withCheckedContinuation { continuation in
            //
            // I. Poll Pasteboard for pasteboard data that matches the pastboard type "com.facebook.diamond.resourceInfo.v1"
            //
            // The copied data is not immediately available in the Pasteboard hence we poll for it (and exit if polling takes too long).
            //
            DispatchQueue.main.async {
                self.startTime = Date.now
                
                Timer.scheduledTimer(withTimeInterval: self.pollInterval, repeats: true) { timer in
                    if Date().timeIntervalSince(self.startTime!) >= self.timeoutInterval {
                        timer.invalidate()
                        continuation.resume(returning: Result<String, OrigamiJavaScriptPatchHandlerError>.failure(.timeout))
                    }  
                    if let origamiBinaryData = self.readOrigamiBinaryDataFromPasteboard() {
                        //
                        // II. Convert binary hex data to a Binary Property List
                        //
                        if let propertyList = self.convertBinaryDataToPropertyList(origamiBinaryData) {
                            //
                            // III. Read file path property from list
                            //
                            if let filePathPropertyString = self.accessProperty(propertyList, key: "file-path") {
                                //
                                // IV. Traverse file path directory and find respective js file
                                //
                                // We have to traverse the directory because the filePathProperty doesn't equal the true file path.
                                //
                                //      filePathPropertyString:  /var/folders/abcdefgh/1234567890.js
                                //      Actual file path:        /var/folders/abcdefgh/XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX/1234567890.js
                                //
                                // The actual file path contains a UUID of the current open file, which we cannot read from the clipboard data.
                                // Because we know the parent directory name 'abcdefgh' and the file name '1234567890.js' we can traverse & search for it.
                                //
                                
                                let nsString = NSString(string: filePathPropertyString)
                                let directoryPath = nsString.deletingLastPathComponent
                                let fileName = nsString.lastPathComponent

                                if let filePathString = self.traverseDirectory(directoryPath: directoryPath, fileName: fileName) {
                                    timer.invalidate()
                                    continuation.resume(returning: .success(filePathString))
                                }
                                else {
                                    timer.invalidate()
                                    continuation.resume(returning: .failure(.couldNotFindJavaScriptFileInsideFileDirectory))
                                }
                            }
                            else {
                                timer.invalidate()
                                continuation.resume(returning: .failure(.couldNotFindPathPropertyInOrigamiPropertyList))
                            }
                        }
                        else {
                            timer.invalidate()
                            continuation.resume(returning: .failure(.couldNotConvertBinaryDataToPropertyList))
                        }
                    }
                }
            }
        }
        
        // 4. Restore previous pasteboard
        pasteboard.clearContents()
        for item in tempPasteboard {
            pasteboard.writeObjects([item])
        }
        return result
    }
    
    /* Emulate Command + C keyboard to copy current selected patch inside Origami */
    private func postCommandCopyDownEvent() -> Bool {
        let commandKey = CGEventFlags.maskCommand
        let cKey = CGKeyCode(8) // c key
        
        guard let downEvent = CGEvent(keyboardEventSource: nil, virtualKey: cKey, keyDown: true) else {
            return false
        }
        
        downEvent.flags = commandKey

        // make sure to only post the keyboard event to the current key application (assumed to be Origami)
        if let pid = NSWorkspace.shared.frontmostApplication?.processIdentifier {
            downEvent.postToPid(pid)
            return true
        }
        return false
    }
    
    /* Try to read the custom pasteboard data type 'com.facebook.diamond.resourceInfo.v1' which contains meta data about the patch in binary hex format */
    private func readOrigamiBinaryDataFromPasteboard() -> Data? {
        let pasteboard = NSPasteboard.general
        let customType = NSPasteboard.PasteboardType(rawValue: "com.facebook.diamond.resourceInfo.v1")
        if pasteboard.canReadItem(withDataConformingToTypes: [customType.rawValue]) {
            return pasteboard.data(forType: customType)
        }
        return nil
    }
    
    private func traverseDirectory(directoryPath: String, fileName: String) -> String? {
        let fileManager = FileManager.default
        do {
            let directoryURL = URL(fileURLWithPath: directoryPath)
            let directoryContents = try fileManager.contentsOfDirectory(atPath: directoryPath)
            
            for dir in directoryContents {
                let dirURL = directoryURL.appendingPathComponent(dir)
                let fileURL = dirURL.appendingPathComponent(fileName)
                
                if fileManager.fileExists(atPath: fileURL.path) {
                    let prependSystemPath = "file:///private\(fileURL.path)"
                    return prependSystemPath
                }
            }
        } catch {
            print("*** [traverseDirectory] Error: \(error)")
        }
        return nil
    }
    
    /*                            */
    /* Binary Property List Stuff */
    /*                            */
    private func convertBinaryDataToPropertyList(_ binaryData: Data) -> Any? {
        do {
            let plist = try PropertyListSerialization.propertyList(from: binaryData, options: [], format: nil)
            return plist
        } catch {
            print("*** [convertBinaryDataToPropertyList] Error converting binary plist to property list object: \(error)")
            return nil
        }
    }
    
    /* Access property in BPList. Iterate through array of dictionaries to find the first .js file with type-name "Patch Script" */
    private func accessProperty(_ plist: Any, key: String) -> String? {
        guard let array = plist as? [[String: Any]] else { return nil }

        for item in array {
            if let typeName = item["type-name"] as? String, typeName == "Patch Script",
               let filePath = item[key] as? String, filePath.hasSuffix(".js") {
                return filePath
            }
        }
        return nil
    }


}

