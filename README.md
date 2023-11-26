## Intro WIP

Kami is a tiny copilot for Origami Studio that helps you create JavaScript Patches using GPT-4.
Select a JavaScript Patch, hit the shortcut and describe the logic of your patch.

Kami is a native macOS menu bar app. You have to provide your own API Key to use the app. Your API Key is stored locally on your machine.

## Background

- In Origami Studio, JavaScript Patches are a fantastic way to prototype more complex logic
- OpenAI's GPT-4 is very good at writing JavaScript Code
- = I wanted to find a way to work with these two on the same surface
- The result is a little single-purpose app that sits ‘on top' of Origami Studio. Think of it as a tiny, rudimentary code editor that lets you open, generate and save JavaScript files without leaving Origami Studio.

## Installation

Download the app from the release page (TODO), unzip the archive and drag the app into your Application folder.

## Usage

1. Launch the app, provide a OpenAI API Key
2. Open a JavaScript patch

- **Shortcut**: Select the patch and hit the shortcut (Default: Cmd+J)
- or: **Open with**: Right-click the patch > Open with ... > Kami

## Caveats

# Cost

With every request to the GPT-4 API, the app prepends (a truncated version of) the Origami Studio JavaScript Patch API Docs to the prompt. This is needed to generate the Origami-flavoured JavaScript that fuels the patch (TODO). This adds an overhead of ≈2000 Tokens to every request. In the future, API requests might become cheaper that this becomes negligible or new APIs such as the Assistant API (TODO) might make prepending the docs redundant.

# System Permissions

The main primitive of the app is opening a selected JavaScript patch via the keyboard shortcut. For this to work, the app requires system-level Accessibility Permissions because it emulates a Cmd+C keystroke to programmatically copy the JavaScript patch to the clipboard. This is a very invasive permission to ask for. The permission is only used for that specific purpose.

Alternatively, JavaScript Patches can be opened via the patches ‘Open with…’ right-click menu (no permissions required).

## Acknowledgements

Luke Haddock, George Kedenburg III for their Origami-GPT-4 experiments and instruction texts, Matthew Mang for their GPT-4 Origami Patch.
