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
    property string packageManager: "apt"

    Plasmoid.status: {
        if (updateCount > 0) {
            return PlasmaCore.Types.ActiveStatus
        }
        return autoHideWhenEmpty ? PlasmaCore.Types.PassiveStatus : PlasmaCore.Types.ActiveStatus
    }
    Plasmoid.icon: updateCount > 0 ? "update-high" : "update-none"
    toolTipMainText: updateCount > 0 ? i18n("%1 updates available", updateCount) : i18n("System is up to date")
    toolTipSubText: lastCheck ? i18n("Last checked: %1", lastCheck) : i18n("Checking for updates...")

    // Configuration properties
    property int checkInterval: plasmoid.configuration.checkInterval || 60
    property bool useNala: plasmoid.configuration.useNala || false
    property bool notifyOnUpdates: plasmoid.configuration.notifyOnUpdates || true
    property bool checkOnStartup: plasmoid.configuration.checkOnStartup || true
    property bool autoHideWhenEmpty: plasmoid.configuration.autoHideWhenEmpty || false
    property bool showBadge: plasmoid.configuration.showBadge !== undefined ? plasmoid.configuration.showBadge : true
    property bool playSound: plasmoid.configuration.playSound || false

    Component.onCompleted: {
        // Determine which package manager to use
        detectPackageManager()

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

            if (sourceName.indexOf("check-updates") !== -1) {
                processUpdateCheck(stdout, exitCode)
            } else if (sourceName.indexOf("detect-nala") !== -1) {
                processPackageManagerDetection(stdout, exitCode)
            }
        }
    }

    function detectPackageManager() {
        if (useNala) {
            executable.connectSource("detect-nala|which nala")
        } else {
            packageManager = "apt"
        }
    }

    function processPackageManagerDetection(stdout, exitCode) {
        if (exitCode === 0 && stdout.trim() !== "") {
            packageManager = "nala"
            console.log("Using nala as package manager")
        } else {
            packageManager = "apt"
            console.log("Using apt as package manager")
        }
    }

    function checkForUpdates() {
        if (checking) return

        checking = true
        updateList = []

        // Command to check for updates without requiring sudo
        var cmd = "check-updates|LANG=C apt list --upgradable 2>/dev/null | grep -v 'Listing' | grep '/'  || true"

        executable.connectSource(cmd)
    }

    function processUpdateCheck(stdout, exitCode) {
        checking = false

        var lines = stdout.trim().split('\n')
        var updates = []
        var count = 0

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

                    updates.push({
                        name: packageName,
                        version: newVersion,
                        fullLine: line
                    })
                    count++
                }
            }
        }

        var previousCount = updateCount
        updateCount = count
        updateList = updates

        var now = new Date()
        lastCheck = Qt.formatDateTime(now, "hh:mm")

        // Show notification if new updates are found
        if (notifyOnUpdates && updateCount > 0 && updateCount > previousCount) {
            showNotification()
        }
    }

    function showNotification() {
        var notification = Qt.createQmlObject('
            import org.kde.notification
            Notification {
                componentName: "plasma_applet_org.kde.plasma.ubuntu-updates"
                eventId: "updates-available"
                title: "' + i18n("Ubuntu Updates Available") + '"
                text: "' + i18np("1 package update is available", "%1 package updates are available", updateCount) + '"
                iconName: "system-software-update"
            }
        ', root)
        notification.sendEvent()

        // Play sound if enabled
        if (playSound) {
            executable.connectSource("play-sound|paplay /usr/share/sounds/freedesktop/stereo/message.oga || canberra-gtk-play -i message || true")
        }
    }

    function openUpdateManager() {
        executable.connectSource("open-updater|discover --mode update || software-properties-gtk --open-tab=3 || (notify-send 'Ubuntu Updates' 'Please run: sudo apt update && sudo apt upgrade' -i system-software-update) &")
    }

    compactRepresentation: Item {
        Kirigami.Icon {
            id: icon
            anchors.fill: parent
            source: updateCount > 0 ? "update-high" : "update-none"
            active: mouseArea.containsMouse

            PlasmaComponents3.Label {
                visible: updateCount > 0 && showBadge
                text: updateCount > 99 ? "99+" : updateCount
                anchors.centerIn: parent
                anchors.verticalCenterOffset: 4
                font.bold: true
                font.pixelSize: parent.height * 0.4
                color: "white"
                style: Text.Outline
                styleColor: "black"
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
        Layout.minimumWidth: PlasmaCore.Units.gridUnit * 20
        Layout.minimumHeight: PlasmaCore.Units.gridUnit * 20
        Layout.preferredWidth: PlasmaCore.Units.gridUnit * 25
        Layout.preferredHeight: PlasmaCore.Units.gridUnit * 30

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
            spacing: PlasmaCore.Units.smallSpacing

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
                            PlasmaComponents3.Label {
                                Layout.fillWidth: true
                                text: modelData.name
                                font.weight: Font.Bold
                                elide: Text.ElideRight
                            }

                            PlasmaComponents3.Label {
                                Layout.fillWidth: true
                                text: i18n("Version: %1", modelData.version)
                                font.pointSize: PlasmaCore.Theme.smallestFont.pointSize
                                opacity: 0.6
                                elide: Text.ElideRight
                            }
                        }
                    }

                    PlasmaExtras.PlaceholderMessage {
                        anchors.centerIn: parent
                        width: parent.width - (PlasmaCore.Units.largeSpacing * 4)
                        visible: updateList.length === 0 && !checking
                        iconName: "checkmark"
                        text: i18n("Your system is up to date!")
                    }

                    PlasmaExtras.PlaceholderMessage {
                        anchors.centerIn: parent
                        width: parent.width - (PlasmaCore.Units.largeSpacing * 4)
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
                    font.pointSize: PlasmaCore.Theme.smallestFont.pointSize
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
