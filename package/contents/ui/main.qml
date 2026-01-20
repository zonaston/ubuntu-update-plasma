import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents3
import org.kde.plasma.extras as PlasmaExtras
import org.kde.notification
import org.kde.plasma.plasma5support as Plasma5Support
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    property int updateCount: 0
    property var updateList: []
    property bool checking: false
    property string lastCheck: ""
    property int aptUpdatesCount: 0
    property int flatpakUpdatesCount: 0

    Plasmoid.status: updateCount > 0 ? PlasmaCore.Types.ActiveStatus : PlasmaCore.Types.PassiveStatus
    Plasmoid.icon: updateCount > 0 ? "update-high" : "update-none"
    toolTipMainText: updateCount > 0 ? i18n("%1 updates available", updateCount) : i18n("System is up to date")
    toolTipSubText: lastCheck ? i18n("Last checked: %1", lastCheck) : i18n("Checking for updates...")

    // Configuration properties
    property int checkInterval: plasmoid.configuration.checkInterval || 60
    property bool notifyOnUpdates: plasmoid.configuration.notifyOnUpdates || true
    property bool checkOnStartup: plasmoid.configuration.checkOnStartup || true
    property bool showBadge: plasmoid.configuration.showBadge !== undefined ? plasmoid.configuration.showBadge : true
    property bool playSound: plasmoid.configuration.playSound || false

    Component.onCompleted: {
        if (checkOnStartup) {
            checkForUpdates()
        }

        // Start the update check timer
        updateTimer.start()
    }

    Timer {
        id: updateTimer
        interval: checkInterval * 60 * 1000 // Convert minutes to milliseconds
        repeat: true
        running: true
        onTriggered: checkForUpdates()
    }

    Plasma5Support.DataSource {
        id: executable
        engine: "executable"
        connectedSources: []

        onNewData: function(sourceName, data) {
            var exitCode = data["exit code"]
            var stdout = data["stdout"]
            var stderr = data["stderr"]

            disconnectSource(sourceName)

            if (sourceName.indexOf("check-apt-updates") !== -1) {
                processAptUpdateCheck(stdout, exitCode)
            } else if (sourceName.indexOf("check-flatpak-updates") !== -1) {
                processFlatpakUpdateCheck(stdout, exitCode)
            }
        }
    }

    function checkForUpdates() {
        if (checking) return

        checking = true
        updateList = []
        aptUpdatesCount = 0
        flatpakUpdatesCount = 0

        // Command to check for apt updates without requiring sudo
        var aptCmd = "check-apt-updates|LANG=C apt list --upgradable 2>/dev/null | grep -v 'Listing' | grep '/'  || true"
        executable.connectSource(aptCmd)

        // Command to check for flatpak updates
        var flatpakCmd = "check-flatpak-updates|flatpak remote-ls --updates 2>/dev/null || true"
        executable.connectSource(flatpakCmd)
    }

    function processAptUpdateCheck(stdout, exitCode) {
        var lines = stdout.trim().split('\n')
        var aptUpdates = []

        for (var i = 0; i < lines.length; i++) {
            var line = lines[i].trim()
            if (line && line !== "" && line.indexOf("/") !== -1) {
                // Parse apt list output
                // Format: package/repo version arch [upgradable from: old_version]
                var parts = line.split(/\s+/)
                if (parts.length >= 2) {
                    var pkgInfo = parts[0].split('/')
                    var packageName = pkgInfo[0]
                    var newVersion = parts[1]

                    aptUpdates.push({
                        name: packageName,
                        version: newVersion,
                        source: "APT",
                        fullLine: line
                    })
                }
            }
        }

        aptUpdatesCount = aptUpdates.length
        updateList = updateList.concat(aptUpdates)
        finalizeUpdateCheck()
    }

    function processFlatpakUpdateCheck(stdout, exitCode) {
        var lines = stdout.trim().split('\n')
        var flatpakUpdates = []

        for (var i = 0; i < lines.length; i++) {
            var line = lines[i].trim()
            if (line && line !== "") {
                // Parse flatpak remote-ls --updates output
                // Format: Name	Application ID	Version	Branch	Remote	Installation
                var parts = line.split('\t')
                if (parts.length >= 3) {
                    var appName = parts[0]
                    var appId = parts.length >= 2 ? parts[1] : ""
                    var version = parts.length >= 3 ? parts[2] : ""

                    // Use application name if available, otherwise use ID
                    var displayName = appName || appId

                    flatpakUpdates.push({
                        name: displayName,
                        version: version,
                        source: "Flatpak",
                        fullLine: line
                    })
                }
            }
        }

        flatpakUpdatesCount = flatpakUpdates.length
        updateList = updateList.concat(flatpakUpdates)
        finalizeUpdateCheck()
    }

    function finalizeUpdateCheck() {
        // Only finalize when both apt and flatpak checks are done
        // We check if we have processed both by seeing if both counts are set (>= 0)
        if (!checking) return

        // Both checks should have completed by now
        var previousCount = updateCount
        updateCount = aptUpdatesCount + flatpakUpdatesCount

        checking = false

        var now = new Date()
        lastCheck = Qt.formatDateTime(now, "hh:mm")

        // Show notification if new updates are found
        if (notifyOnUpdates && updateCount > 0 && updateCount > previousCount) {
            showNotification()
        }
    }

    Notification {
        id: updateNotification
        componentName: "plasma_applet_org.kde.plasma.ubuntu-updates"
        eventId: "updates-available"
        iconName: "system-software-update"
    }

    function showNotification() {
        updateNotification.title = i18n("Ubuntu Updates Available")
        updateNotification.text = i18np("1 package update is available", "%1 package updates are available", updateCount)
        updateNotification.sendEvent()

        // Play sound if enabled
        if (playSound) {
            executable.connectSource("play-sound|paplay /usr/share/sounds/freedesktop/stereo/message.oga || canberra-gtk-play -i message || true")
        }
    }

    function openUpdateManager() {
        executable.connectSource("open-updater|discover --mode update || software-properties-gtk --open-tab=3 || (notify-send 'Ubuntu Updates' 'Please run: sudo apt update && sudo apt upgrade' -i system-software-update) &")
    }

    compactRepresentation: Item {
        id: compactRoot

        Layout.minimumWidth: {
            var baseWidth = Kirigami.Units.iconSizes.smallMedium
            if (showBadge && updateCount > 0) {
                // Add space for badge: estimated 2 digits + spacing
                return baseWidth + Kirigami.Units.gridUnit * 1.5
            }
            return baseWidth
        }
        Layout.minimumHeight: Kirigami.Units.iconSizes.smallMedium

        RowLayout {
            anchors.fill: parent
            spacing: Kirigami.Units.smallSpacing

            Kirigami.Icon {
                id: icon
                Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
                Layout.preferredHeight: Kirigami.Units.iconSizes.smallMedium
                source: updateCount > 0 ? "update-high" : "update-none"
                active: mouseArea.containsMouse
            }

            PlasmaComponents3.Label {
                id: badgeLabel
                visible: updateCount > 0 && showBadge
                text: updateCount > 99 ? "99+" : updateCount
                font.bold: true
                font.pixelSize: Kirigami.Theme.defaultFont.pixelSize * 1.1
                color: Kirigami.Theme.textColor
                Layout.fillWidth: true
            }
        }

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            onClicked: root.expanded = !root.expanded
        }
    }

    fullRepresentation: PlasmaComponents3.Page {
        Layout.minimumWidth: Kirigami.Units.gridUnit * 20
        Layout.minimumHeight: Kirigami.Units.gridUnit * 20
        Layout.preferredWidth: Kirigami.Units.gridUnit * 25
        Layout.preferredHeight: Kirigami.Units.gridUnit * 30

        header: PlasmaExtras.PlasmoidHeading {
            RowLayout {
                anchors.fill: parent

                PlasmaComponents3.Label {
                    Layout.fillWidth: true
                    text: updateCount > 0 ?
                          i18np("1 Update Available", "%1 Updates Available", updateCount) :
                          i18n("No Updates Available")
                    font.weight: Font.Bold
                }

                PlasmaComponents3.Button {
                    icon.name: "view-refresh"
                    text: i18n("Refresh")
                    enabled: !checking
                    onClicked: checkForUpdates()

                    PlasmaComponents3.BusyIndicator {
                        anchors.centerIn: parent
                        running: checking
                        visible: checking
                    }
                }
            }
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: Kirigami.Units.smallSpacing

            PlasmaComponents3.ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true

                ListView {
                    id: updateListView
                    model: updateList
                    clip: true

                    delegate: PlasmaComponents3.ItemDelegate {
                        width: updateListView.width

                        contentItem: ColumnLayout {
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: Kirigami.Units.smallSpacing

                                PlasmaComponents3.Label {
                                    Layout.fillWidth: true
                                    text: modelData.name
                                    font.weight: Font.Bold
                                    elide: Text.ElideRight
                                }

                                PlasmaComponents3.Label {
                                    text: modelData.source || "APT"
                                    font.pointSize: Kirigami.Theme.smallestFont.pointSize
                                    padding: Kirigami.Units.smallSpacing
                                    color: Kirigami.Theme.highlightedTextColor
                                    background: Rectangle {
                                        color: Kirigami.Theme.highlightColor
                                        radius: 3
                                    }
                                }
                            }

                            PlasmaComponents3.Label {
                                Layout.fillWidth: true
                                text: i18n("Version: %1", modelData.version)
                                font.pointSize: Kirigami.Theme.smallestFont.pointSize
                                opacity: 0.6
                                elide: Text.ElideRight
                            }
                        }
                    }

                    PlasmaExtras.PlaceholderMessage {
                        anchors.centerIn: parent
                        width: parent.width - (Kirigami.Units.largeSpacing * 4)
                        visible: updateList.length === 0 && !checking
                        iconName: "checkmark"
                        text: i18n("Your system is up to date!")
                    }

                    PlasmaExtras.PlaceholderMessage {
                        anchors.centerIn: parent
                        width: parent.width - (Kirigami.Units.largeSpacing * 4)
                        visible: checking
                        iconName: "system-search"
                        text: i18n("Checking for updates...")
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true

                PlasmaComponents3.Label {
                    Layout.fillWidth: true
                    text: lastCheck ? i18n("Last checked: %1", lastCheck) : ""
                    font.pointSize: Kirigami.Theme.smallestFont.pointSize
                    opacity: 0.6
                }

                PlasmaComponents3.Button {
                    visible: updateCount > 0
                    text: i18n("Open Update Manager")
                    icon.name: "system-software-update"
                    onClicked: {
                        openUpdateManager()
                        root.expanded = false
                    }
                }
            }
        }
    }
}
