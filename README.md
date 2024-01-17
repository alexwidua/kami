<img src="media/hero.png" width="100%" max-width="600px"/>

Kami is a tiny copilot for [Origami Studio](https://origami.design/) that helps to create [JavaScript Patches](https://origami.design/documentation/concepts/scriptingapi) using [GPT-4](https://openai.com/gpt-4).  
Select a JavaScript Patch, invoke the app's overlay using the shortcut and describe the logic of your patch.

_Kami is a native macOS menu bar app. You have to provide your [own OpenAI API Key](https://help.openai.com/en/articles/4936850-where-do-i-find-my-api-key) to use the app. Your API key is stored locally on your machine._

<video src='media/video.mp4' width='600'/>

## Background

- [JavaScript Patches](https://origami.design/documentation/concepts/scriptingapi) are a fantastic way to prototype more complex logic inside Origami Studio
- OpenAI's GPT-4 is very capable of writing JavaScript code
- I experimented with ways to combine these two tools into a single surface and primitive

The result is a tiny app that sits ‘on top' of Origami Studio. Think of it as a tiny, rudimentary code editor that lets you open, generate and save JavaScript files without leaving the Origami Studio surface.

## Installation

[Download the App](https://github.com/alexwidua/Kami/releases/latest/download/Kami.dmg) from the release page.

## Usage

1. Launch the app, provide your [OpenAI API Key](https://help.openai.com/en/articles/4936850-where-do-i-find-my-api-key)
2. To pen a JavaScript patch...

- ⚡ **Using the Shortcut**: Select the JavaScript Patch and hit the shortcut (Default: Cmd+J)
- 🗄️ **Using the Context Menu**: Right-click the JavaScript Patch > Open with ... > Kami

## Caveats

### Experimental

Consider this experimental software. One thing to figure out is how to further improve the app's prompt and improve the resulting code/patch quality. If you run into any issues, open an Issue or reach out via [Mail](mailto:alex@alexwidua.com)/[Twitter](https://twitter.com/alexwidua).

### Cost

With every request to GPT-4, the app prepends (a truncated version of) the [Origami Studio JavaScript Patch API documentation](https://origami.design/documentation/concepts/scriptingapi) to the prompt. This is needed to generate the Origami-flavoured JavaScript that drives the patch. This adds an overhead of around 2000 input tokens to every request. In the future, API requests might become cheaper that this becomes negligible, or new APIs such as the [Assistant API](https://platform.openai.com/docs/assistants/overview) might make prepending the documentation not necessary anymore.

### Permissions

One neat thing is the ability to open JavaScript Patches using the keyboard shortcut. It's quick and simple. For this to work though, the app requires system-level Accessibility Permissions because it emulates a ⌘+C keystroke to copy the JavaScript patch to the clipboard (and then read the Patch data from the clipboard). This is pretty invasive permission to ask for. For what it's worth, the permission is only eber used for that specific purpose. See the `PasteboardHandler` file for more.

If you don't want to (or can't) give this permission, JavaScript Patches can also be opened via the ‘Open with…’ right-click menu (no permissions are required for that).

## Acknowledgements

[Luke Haddock](https://lukehaddock.com), [George Kedenburg III](https://gk3.website) for their Origami-GPT-4 experiments and instruction texts, [Matthew Mang](https://www.matthewmang.com) for their GPT-4 Origami Patch.
