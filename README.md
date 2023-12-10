# Firefox GTK Controls

On Linux, if you try to use a theme from an addon, Firefox will use the default Adwaita window control buttons. This is [intentional](https://bugzilla.mozilla.org/show_bug.cgi?id=1832975).

The only supported way to use your custom window controls (close, maximize, restore, minimize) is to use the System theme. So addon themes are effectively broken on Linux.

But there's another way!

Using custom stylesheets, you can enable Firefox to use your configured window decorations.

## Installing

Before starting, you need to open `about:config` and manually set `toolkit.legacyUserProfileCustomization.stylesheets = true`. This will tell Firefox to look for your stylesheets when starting.

### Installer Script

Using the `install.sh` script is the recommended way to install. It will copy assets, update the `userChrome.css` file, and create a symbolic link to `~/.config/gtk-3.0`. It will also optionally allow firefox under flatpak to access the gtk assets.

To run it, simply clone this repo and run the `install.sh` script.

```
$ ./install.sh
```

### Manual Installation

Follow these steps in case you want to do a manual install.

You will need your profile path, so visit `about:profiles` in firefox and write down your profile's root directory.

- If you are using flatpak, it will be relative to `~/.var/app/org.mozilla.firefox`
- If you are using snap, it will be relative to `~/snap/firefox/common`

#### TL;DR

Run this bash snippet with your own `profilepath` variable, then restart Firefox.

```sh
profilepath="<paste path>"
mkdir "$profilepath/chrome"
ln -s ~/.config/gtk-3.0 "$profilepath/chrome/gtk-3.0"
cp firefox-csd.css "$profilepath/chrome/"
echo '@import "./firefox-csd.css";' >> "$profilepath/userChrome.css"
```

#### Steps

1. Create the directory `$profilepath/chrome` if it does not exist.

2. Create a symbolic link in the same directory to `~/.config/gtk-3.0` named `gtk-3.0`

3. Copy the `firefox-csd.css` file to the newly created directory.

4. Create a new file called `userChrome.css` with the following content. If you need to, you can include other imports in the file.

   ```css
   @import "./firefox-csd.css";
   ```

5. Restart firefox if it is open.

## Troubleshooting

### The installer isn't finding my profile

The installer looks in the following locations for Firefox profiles.

- `$HOME/.mozilla/firefox`
- `$HOME/.var/app/org.mozilla.firefox/.mozilla/firefox`
- `$HOME/snap/firefox/common/.mozilla/firefox`

Fix: If your profile isn't located in one of these folders, follow the manual install instructions.

If you think your profile should be included in the search path, open an issue.

### After running the installer and restarting firefox, nothing changes

Firefox will not pick up the user chrome if you didn't set the correct variable in `about:config`.

Fix: Set the variable `toolkit.legacyUserProfileCustomization.stylesheets` to `true` and restart Firefox.

### The variable `toolkit.legacyUserProfileCustomization.stylesheets` is set to true, but nothing changes

If you followed the manual instructions, make sure you wrote down the correct profile path from `about:profiles`. It should be in the `.mozilla/firefox` directory, not `.cache/mozilla/firefox`.

Fix: Redo the installation steps with the *correct* profile path.

### My window control buttons are invisible

This is either because the assets don't exist, the symbolic link wasn't created, or flatpak doesn't have the correct filesystem override.

Fix: Re-run the installer script.

If you did a manual install with flatpak, run this command to expose the gtk-3.0 configuration to Firefox.

```sh
flatpak override --user org.mozilla.firefox --filesystem=xdg-config/gtk-3.0:ro
```
