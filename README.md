# Ubuntu Updates Indicator for KDE Plasma

A KDE Plasma widget that monitors and displays available package updates for Ubuntu and other Debian-based systems. Similar to the GNOME Shell Debian Updates Indicator, but designed specifically for KDE Plasma.

## Features

- System tray icon with update count badge (beside icon, not overlaid)
- Automatic periodic checking for updates
- Desktop notifications when new updates are available
- Optional sound notifications for new updates
- List view of all available updates
- One-click access to update manager (Discover or Software Properties)
- Configurable check intervals (5 minutes to 24 hours)
- Toggle badge visibility
- No sudo/root privileges required for checking
- Fully compatible with Plasma 6

## Screenshots

The widget appears in the system tray and shows:
- An icon with the number of available updates
- A popup listing all packages that can be updated
- Package names and new version numbers

## Installation

### Method 1: From Repository (Recommended)

1. Clone this repository:
```bash
git clone https://github.com/zonaston/ubuntu-update-plasma.git
cd ubuntu-update-plasma
```

2. Install the widget:
```bash
kpackagetool6 -i package
```

4. Add the widget to your panel:
   - Right-click on your panel
   - Select "Add Widgets"
   - Search for "Ubuntu Updates Indicator"
   - Add it to your panel

### Method 2: Install from Local Package
```bash
kpackagetool6 -t Plasma/Applet -i package
```

### Updating the Widget

If you already have the widget installed and want to update it:
```bash
cd ubuntu-update-plasma
git pull
kpackagetool6 -u package
```

## Uninstallation

To remove the widget:
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

The widget uses the `apt list --upgradable` command to check for available package updates. This command does not require root privileges and provides a reliable list of packages that can be updated.

The checking process:
1. Runs `apt list --upgradable` in the background
2. Parses the output to extract package names and versions
3. Updates the system tray icon with the count
4. Displays the list in the popup when clicked

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

## Development

### Building from Source

The widget is written in QML and doesn't require compilation. The structure is:
```
package/
├── metadata.json           # Widget metadata
└── contents/
    ├── config/
    │   ├── main.xml       # Configuration schema
    │   └── config.qml     # Configuration structure
    └── ui/
        ├── main.qml       # Main widget UI
        └── configGeneral.qml  # Configuration UI
```

### Testing

To test changes without installing:
```bash
plasmoidviewer -a package
```

### Debug Output

To see debug messages:
```bash
journalctl -f | grep plasma
```

Or run from terminal:
```bash
QT_LOGGING_RULES="*.debug=true" plasmoidviewer -a package
```

## Contributing

Contributions are welcome! Please feel free to submit pull requests or open issues for bugs and feature requests.

## Inspiration

This widget is inspired by the [GNOME Shell Debian Updates Indicator](https://gitlab.gnome.org/glerro/gnome-shell-extension-debian-updates-indicator) by Gianni Lerro, adapted for the KDE Plasma desktop environment.

## License

This project is licensed under the GNU General Public License v3.0 or later - see the [LICENSE](LICENSE) file for details.

## Authors

Created for the Ubuntu/KDE community.

## Changelog

### Version 1.1.0
- **Plasma 6 Compatibility**: Full migration to Plasma 6 APIs
  - Replaced `PlasmaCore.DataSource` with `Plasma5Support.DataSource`
  - Replaced `PlasmaCore.IconItem` with `Kirigami.Icon`
  - Replaced `PlasmaCore.Units` and `PlasmaCore.Theme` with `Kirigami` equivalents
  - Migrated from `Item` to `PlasmoidItem` root element
  - Fixed `compactRepresentation` and `fullRepresentation` for Plasma 6
- **New Features**:
  - Toggle badge visibility (show/hide update count)
  - Sound notifications for new updates
  - Better icon selection (update-high/update-none)
- **UI Improvements**:
  - Badge now appears beside icon instead of overlaid on top
  - Better theme color integration
  - Improved tooltip information
  - Proper width calculation for badge to prevent icon overlap
- **Code Cleanup**:
  - Removed nala support (provides no benefit for listing updates)
  - Simplified codebase and configuration options

### Version 1.0.1
- Updated for KDE Plasma 6 (Plasma 5 deprecated)
- Modernized QML imports (removed version numbers)
- Fixed metadata format for Plasma 6
- Simplified installation instructions
- Fixed installation path to use kpackagetool6 with -t flag

### Version 1.0.0
- Initial release
- System tray integration
- Configurable check intervals
- Desktop notifications
- Update list view
