// SPDX-FileCopyrightText: 2022 Devin Lin <devin@kde.org>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15 as Controls

import org.kde.kirigami 2.19 as Kirigami
import org.kde.kirigamiaddons.labs.mobileform 0.1 as MobileForm

MobileForm.FormButtonDelegate {
    id: root
    
    property string textValue
    
    signal textSaved(string savedText)
    
    description: textValue === "" ? i18n("Enter a value…") : "●●●●●"
    
    onClicked: {
        textField.text = root.textValue;
        dialog.open();
        textField.forceActiveFocus();
    }
    
    Kirigami.Dialog {
        id: dialog
        standardButtons: Kirigami.Dialog.Cancel | Kirigami.Dialog.Apply
        title: root.text
        
        padding: Kirigami.Units.largeSpacing
        bottomPadding: Kirigami.Units.largeSpacing + Kirigami.Units.smallSpacing
        preferredWidth: Kirigami.Units.gridUnit * 20
        
        onApplied: {
            root.textSaved(textField.text);
            dialog.close();
        }
        
        Kirigami.PasswordField {
            id: textField
            text: root.textValue
            onAccepted: dialog.applied()
        }
    }
}

