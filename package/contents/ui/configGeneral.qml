import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Kirigami.FormLayout {
    id: generalPage

    property alias cfg_checkInterval: checkIntervalSpinBox.value
    property alias cfg_notifyOnUpdates: notifyCheckBox.checked
    property alias cfg_checkOnStartup: checkOnStartupCheckBox.checked
    property alias cfg_showBadge: showBadgeCheckBox.checked
    property alias cfg_playSound: playSoundCheckBox.checked

    QQC2.SpinBox {
        id: checkIntervalSpinBox
        Kirigami.FormData.label: i18n("Check interval (minutes):")
        from: 5
        to: 1440
        stepSize: 5
        textFromValue: function(value) {
            if (value < 60) {
                return i18np("%1 minute", "%1 minutes", value)
            } else {
                var hours = Math.floor(value / 60)
                return i18np("%1 hour", "%1 hours", hours)
            }
        }
        valueFromText: function(text) {
            return parseInt(text)
        }
    }

    QQC2.CheckBox {
        id: checkOnStartupCheckBox
        Kirigami.FormData.label: i18n("Startup:")
        text: i18n("Check for updates on startup")
    }

    QQC2.CheckBox {
        id: notifyCheckBox
        Kirigami.FormData.label: i18n("Notifications:")
        text: i18n("Show notification when updates are available")
    }

    Item {
        Kirigami.FormData.isSection: true
    }

    QQC2.CheckBox {
        id: showBadgeCheckBox
        Kirigami.FormData.label: i18n("Display:")
        text: i18n("Show update count badge on icon")
    }

    QQC2.CheckBox {
        id: playSoundCheckBox
        Kirigami.FormData.label: i18n("Audio:")
        text: i18n("Play sound notification for new updates")
    }

    Item {
        Kirigami.FormData.isSection: true
    }

    QQC2.Label {
        Layout.fillWidth: true
        text: i18n("This widget checks for Ubuntu package updates using apt.\nThe widget displays the number of available updates in the system tray.")
        wrapMode: Text.WordWrap
        font.pointSize: Kirigami.Theme.smallFont.pointSize
        opacity: 0.6
    }
}
