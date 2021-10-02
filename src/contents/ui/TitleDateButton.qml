import QtQuick 2.15
import QtQuick.Controls 2.0 as QQC2
import QtQuick.Layouts 1.7
import org.kde.kirigami 2.12 as Kirigami

QQC2.ToolButton {
    id: root
    implicitHeight: titleText.implicitHeight
    implicitWidth: titleText.implicitWidth

    property bool range: false
    property date date
    property date lastDate

    contentItem: Kirigami.Heading {
        id: titleText
        topPadding: Kirigami.Units.smallSpacing
        bottomPadding: Kirigami.Units.smallSpacing
        leftPadding: Kirigami.Units.largeSpacing + Kirigami.Units.smallSpacing
        rightPadding: Kirigami.Units.largeSpacing + Kirigami.Units.smallSpacing

        horizontalAlignment: Text.AlignHCenter
        text: if(!root.range) {
            return root.date.toLocaleDateString(Qt.locale(), "<b>MMMM</b> yyyy");
        } else {
            if(root.date.getFullYear() !== root.lastDate.getFullYear()) {
                return root.date.toLocaleDateString(Qt.locale(), "<b>MMMM</b> yyyy") + " - " + root.lastDate.toLocaleDateString(Qt.locale(), "<b>MMMM</b> yyyy");
            } else if(root.date.getMonth() !== root.lastDate.getMonth()) {
                root.date.toLocaleDateString(Qt.locale(), "<b>MMMM</b>") + " - " + root.lastDate.toLocaleDateString(Qt.locale(), "<b>MMMM</b> yyyy");
            } else {
                return root.date.toLocaleDateString(Qt.locale(), "<b>MMMM</b> yyyy");
            }
        }
    }
}
