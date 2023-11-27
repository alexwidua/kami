## Intro WIP

Kami is a tiny copilot for Origami Studio that helps create JavaScript Patches using GPT-4.
Select a JavaScript Patch, invoke the app's overlay usig the shortcut and describe the logic of your patch.

Kami is a native macOS menu bar app. You have to provide your own OpenAI API Key to use the app. Your API key is stored locally on your machine.

## Background

- JavaScript Patches are a fantastic way to prototype more complex logic in Origami Studio
- OpenAI's GPT-4 is very capable of writing JavaScript code
- I tried to find a way to combine these two tools into a single surface

The result is a single-purpose app that sits ‘on top' of Origami Studio. Think of it as a tiny, rudimentary code editor that lets you open, generate and save JavaScript files without leaving Origami Studio.

## Installation

Download the app from the release page (TODO), unzip the archive and drag the app into your Application folder.

## Usage

1. Launch the app, provide a OpenAI API Key
2. Open a JavaScript patch

- **Using the Shortcut**: Select the JavaScript Patch and hit the shortcut (Default: Cmd+J)
- or: **Using the Context Menu**: Right-click the JavaScript Patch > Open with ... > Kami

## Caveats

# Cost

Every request to the GPT-4 API, the app prepends (a truncated version of) the Origami Studio JavaScript Patch API documentation to the prompt. This is needed to generate the Origami-flavoured JavaScript that drives the patch (TODO). This adds an overhead of around 2000 input tokens to every request. In the future, API requests might become cheaper that this becomes negligible, or new APIs such as the Assistant API (TODO) might make prepending the documentation not necessary anymore.

# Permissions

One neat thing about the app is to open javaScript Patches using the shortcut. It's quick. For this to work, the app requires system-level Accessibility Permissions because it emulates a Cmd+C keystroke to programmatically copy the JavaScript patch to the clipboard (and then read the Patch data from the clipboard). This is a very invasive permission to ask for. For what it's worth, the permission is only eber used for that specific purpose. See the PasteboardHandler file for more.

If you don't or can't give this permission, JavaScript Patches can also be opened via the ‘Open with…’ right-click menu (no permissions are required for that).

## Acknowledgements

Luke Haddock, George Kedenburg III for their Origami-GPT-4 experiments and instruction texts, Matthew Mang for their GPT-4 Origami Patch.
