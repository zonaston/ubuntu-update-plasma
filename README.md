# Ubuntu Updates Indicator for KDE Plasma

A KDE Plasma widget that monitors and displays available package updates for Ubuntu and other Debian-based systems. Similar to the GNOME Shell Debian Updates Indicator, but designed specifically for KDE Plasma.

## Features

- System tray icon with update count badge
- Automatic periodic checking for updates
- **Desktop notifications when new updates are available** (now working with Plasma 6!)
- Optional sound notifications for new updates
- List view of all available updates
- **Flatpak application updates support** (in addition to APT packages)
- One-click access to update manager
- Configurable check intervals
- Toggle badge visibility
- No sudo/root privileges required for checking
- Fully compatible with Plasma 6

## Screenshots

The widget appears in the system tray and shows:
- An icon with the number of available updates
- A popup listing all packages that can be updated
- Package names and new version numbers

## Installation

### Fresh Installation

1. Clone this repository:
```bash
cd ~
git clone https://github.com/zonaston/ubuntu-update-plasma.git
cd ubuntu-update-plasma
```

2. Install the widget:
```bash
kpackagetool6 -t Plasma/Applet -i package
```

3. Restart Plasma Shell to load the widget:
```bash
killall plasmashell ; kstart plasmashell
```

4. Add the widget to your panel:
   - Right-click on your panel
   - Select "Add Widgets"
   - Search for "Ubuntu Updates Indicator"
   - Add it to your panel

### Updating the Widget

If you already have the widget installed and want to update it:

```bash
# Remove old installation
rm -rf ~/.local/share/plasma/plasmoids/org.kde.plasma.ubuntu-updates

# Clean up and re-clone
cd ~
rm -rf ubuntu-update-plasma
git clone https://github.com/zonaston/ubuntu-update-plasma.git
cd ubuntu-update-plasma

# Install fresh
kpackagetool6 -t Plasma/Applet -i package

# Restart Plasma Shell
killall plasmashell ; kstart plasmashell
```

**Note:** After updating, you may need to re-add the widget to your panel.

## Uninstallation

To remove the widget:
```bash
rm -rf ~/.local/share/plasma/plasmoids/org.kde.plasma.ubuntu-updates
killall plasmashell ; kstart plasmashell
```

Or using kpackagetool6:
```bash
kpackagetool6 -r org.kde.plasma.ubuntu-updates
```

## Configuration

Right-click on the widget and select "Configure" to access settings:

- **Check Interval**: How often to check for updates (5 minutes to 24 hours)
- **Check on Startup**: Automatically check for updates when the widget starts
- **Show Notifications**: Display desktop notifications when updates are found
- **Show Badge**: Display update count beside the icon (can be disabled for minimal look)
- **Play Sound**: Play a sound notification when new updates are detected

## Requirements

- KDE Plasma 6.0 or later
- Ubuntu, Debian, or any Debian-based distribution
- `apt` package manager (pre-installed on Ubuntu/Debian)

## How It Works

The widget checks for updates from multiple sources:
- Uses `apt list --upgradable` to check for system package updates
- Uses `flatpak remote-ls --updates` to check for Flatpak application updates
- Neither command requires root privileges

The checking process:
1. Runs both commands in the background
2. Parses the output to extract package/app names and versions
3. Updates the system tray icon with the total count
4. Displays the combined list in the popup when clicked
5. Shows the source (APT/Flatpak) for each update

## Opening the Update Manager

Clicking "Open Update Manager" will attempt to launch one of the following (in order):
1. KDE Discover (in update mode)
2. GNOME Software Properties
3. Falls back to showing a notification with manual update instructions

You can then run updates using apt:
```bash
sudo apt update && sudo apt upgrade
```

## Privacy

This widget:
- Does NOT automatically download or install updates
- Does NOT require internet access beyond standard apt repository connections
- Does NOT collect or transmit any usage data
- Only reads publicly available package information from your system

## Troubleshooting

### Widget doesn't show updates

1. Make sure your package lists are up to date:
```bash
sudo apt update
```

2. Verify updates are available:
```bash
apt list --upgradable
```

3. Check the widget is running (it should appear in the system tray)

### Widget won't install

Make sure you have the required dependencies:
```bash
sudo apt install plasma-workspace plasma-framework
```

### Widget disappeared after update

Plasma sometimes removes widgets during updates. Simply re-add it from the widget menu.

## Contributing

Contributions are welcome! Please feel free to submit pull requests or open issues for bugs and feature requests.

## Inspiration

This widget is inspired by the [GNOME Shell Debian Updates Indicator](https://gitlab.gnome.org/glerro/gnome-shell-extension-debian-updates-indicator) by Gianni Lerro, adapted for the KDE Plasma desktop environment.

## License

This project is licensed under the GNU General Public License v3.0 or later - see the [LICENSE](LICENSE) file for details.
