## How to publish an update

Field notes to my future self (and anyone else who might run into this).
Starting with `1.1.0`, the app uses [Sparkle](https://sparkle-project.org/) to remotely push and receive updates. This requires a few steps because updates have to be properly signed, notarized and published.

## Instructions

1. In Xcode, make sure that the app has the proper version and build number
2. Archive the app and make it ready for distribution (**Product** > **Archive** > **Distribute app** > **Direct Distribution**)
3. Wait for the app's notarization through Apple, then export the `.app` file
4. Package the `.app` file as `.dmg` using [create-dmg](https://github.com/create-dmg/create-dmg) and the template script inside this repository's `misc/create-dmg` folder
5. Create a new folder (e.g. `/Desktop/kami-update`) and put the new `.dmg` file and previous `appcast.xml` file inside
6. Next, create a EdDSA (ed25519) signature (for Sparkle) and create a new `appcast.xml` file by running the `generate_appcast` utility script inside Sparkle's `/artifacts/sparkle/Sparkle/bin` folder. The easiest way to find the folder is to reveal the Sparkle package source code in Finder (In Xcode, right click the Sparkle dependency) and navigate to the parent folder. You should find a `artifacts` folder with the script inside.
7. Inside the `/artifacts/sparkle/Sparkle/` folder, run the `generate_appcast` script: `./bin/generate_appcast /path/to/folder/created/in/step/5/`
8. Open the newly created/updated `appcast.xml` file and update the `<enclosure url="https://alexwidua.github.io./Kami/Kami.dmg" .../>` and point it to `https://github.com/alexwidua/Kami/releases/latest/download/Kami.dmg`
9. Commit the newly updated `appcast.xml` to the root of this repository (where the previous existing appcast file should be located)
10. Create a new GitHub release with the `.dmg` file generated in Step 4 (Make sure that the file is called `Kami.dmg`)
11. The new update should show up in the Kami app. It might take a few minutes for GitHub pages to refresh the `appcast.xml` file (you can check that at `https://alexwidua.github.io./Kami/appcast.xml`)
