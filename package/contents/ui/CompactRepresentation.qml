import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami

// Panel / system tray icon: one bar per provider showing the remaining share
// of its 5-hour window (weekly when the provider has no 5-hour window).
MouseArea {
    id: compact

    readonly property bool vertical: Plasmoid.formFactor === PlasmaCore.Types.Vertical
    readonly property bool planar: Plasmoid.formFactor === PlasmaCore.Types.Planar
    // Remaining percentage per provider, -1 when unknown.
    readonly property var bars: {
        if (!root.usage || !root.usage.providers)
            return [];
        return root.usage.providers.map(p => {
            const windows = p.windows || [];
            const w = windows.find(x => x.key === "session") || windows.find(x => x.key === "weekly") || windows[0];
            return w ? 100 - w.usedPercent : -1;
        });
    }
    readonly property bool known: bars.some(left => left >= 0)

    function tone(left) {
        if (left < 15)
            return Kirigami.Theme.negativeTextColor;
        if (left <= 40)
            return Kirigami.Theme.neutralTextColor;
        return Kirigami.Theme.highlightColor;
    }

    readonly property real size: Math.min(width, height)

    Layout.minimumWidth: vertical ? Kirigami.Units.iconSizes.small : height
    Layout.minimumHeight: vertical ? width : Kirigami.Units.iconSizes.small
    Layout.preferredWidth: planar ? Kirigami.Units.iconSizes.large : (vertical ? -1 : height)
    Layout.preferredHeight: planar ? Kirigami.Units.iconSizes.large : (vertical ? width : -1)

    hoverEnabled: true
    acceptedButtons: Qt.LeftButton | Qt.MiddleButton
    onClicked: mouse => {
        if (mouse.button === Qt.MiddleButton)
            root.refresh();
        else
            root.expanded = !root.expanded;
    }

    Accessible.role: Accessible.Button
    Accessible.name: root.toolTipMainText

    // Fallback glyph while nothing is known yet.
    Kirigami.Icon {
        anchors.fill: parent
        visible: !compact.known
        source: "speedometer"
        active: compact.containsMouse
    }

    Column {
        id: lines

        readonly property real thickness: Math.max(2, Math.round(compact.size / 7))

        anchors.centerIn: parent
        width: compact.size
        spacing: Math.max(1, Math.round((compact.size - thickness * compact.bars.length) / (compact.bars.length + 1)))
        visible: compact.known
        opacity: compact.containsMouse ? 1 : 0.9

        Behavior on opacity {
            NumberAnimation { duration: Kirigami.Units.shortDuration }
        }

        Repeater {
            model: compact.bars

            // Track
            Rectangle {
                required property real modelData

                width: lines.width
                height: lines.thickness
                radius: height / 2
                color: Qt.alpha(Kirigami.Theme.textColor, 0.25)

                // Remaining share, from the left
                Rectangle {
                    visible: parent.modelData > 0
                    width: Math.max(height, parent.width * Math.min(1, parent.modelData / 100))
                    height: parent.height
                    radius: height / 2
                    color: compact.tone(parent.modelData)

                    Behavior on width {
                        NumberAnimation {
                            duration: Kirigami.Units.longDuration
                            easing.type: Easing.OutCubic
                        }
                    }
                }
            }
        }
    }
}
