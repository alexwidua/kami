## create-dmg Script

Script to package the Kami `.app` file using [create-dmg](https://github.com/create-dmg/create-dmg). Make sure to replace `<DEVELOPER PROFILE>`, `<NOTARY PROFILE>`, `<OUTPUT FOLDER>` and `<INPUT FOLDER>`.

- You can find the developer profile by running `security find-identity` in the terminal
- You can find/create the notary profile by running ([Create specific app password](https://appleid.apple.com/account/manage), [Check Team ID](https://developer.apple.com/account/#!/membership/)):

```
xcrun notarytool store-credentials “<DEVELOPER PROFILE>” — apple-id “yourappleide@mail.com” — password “your_specific_app_password” — team-id “your_team_id
```

## Script

```
create-dmg \
  --volname "Kami Installer" \
  --background "background.png" \
  --window-pos 200 120 \
  --window-size 700 500 \
  --icon-size 100 \
  --icon "Kami.app" 240 220 \
  --hide-extension "Kami.app" \
  --app-drop-link 460 220 \
  --codesign "<DEVELOPER PROFILE>" \
  --notarize "<NOTARY PROFILE>" \
  "<OUTPUT FOLDER>" \
  "<INPUT FOLDER>"
```
