// SPDX-FileCopyrightText: 2016 Michael Bohlender <michael.bohlender@kdemail.net>
// SPDX-License-Identifier: GPL-2.0-or-later


import QtQuick 2.7
import QtQuick.Controls 2.15 as QQC2
import QtWebEngine 1.4
import QtQuick.Window 2.0

import org.kde.kalendar 1.0
import org.kde.kalendar.mail 1.0
import org.kde.kirigami 2.19 as Kirigami

Item {
    id: root
    objectName: "htmlPart"
    property string content
    //We have to give it a minimum size so the html content starts to expand
    property int minimumSize: 10
    property int contentHeight: minimumSize
    property int contentWidth: minimumSize
    property string searchString
    property bool autoLoadImages: false

    onSearchStringChanged: {
        htmlView.findText(searchString)
    }
    onContentChanged: {
        htmlView.loadHtml(content, "file:///");
    }

    QQC2.ScrollView {
        anchors.fill: parent
        Flickable {
            id: flickable

            clip: true
            boundsBehavior: Flickable.StopAtBounds

            WebEngineView {
                id: htmlView
                objectName: "htmlView"
                anchors.fill: parent

                Component.onCompleted: loadHtml(content, "file:///")
                onLoadingChanged: {
                    if (loadRequest.status == WebEngineView.LoadFailedStatus) {
                        console.warn("Failed to load html content.")
                        console.warn("Error is ", loadRequest.errorString)
                    }
                    root.contentWidth = Math.max(contentsSize.width, flickable.minimumSize)

                    if (loadRequest.status == WebEngineView.LoadSucceededStatus) {
                        runJavaScript("[document.body.scrollHeight, document.body.scrollWidth, document.documentElement.scrollHeight]", function(result) {
                            root.contentHeight = Math.min(Math.max(result[0], result[2]), 4000);
                            root.contentWidth = Math.min(Math.max(result[1], flickable.width), 2000)
                        });
                    }
                }
                onLinkHovered: {
                    console.debug("Link hovered ", hoveredUrl)
                }
                onNavigationRequested: {
                    console.debug("Nav request ", request.navigationType, request.url)
                    if (request.navigationType == WebEngineNavigationRequest.LinkClickedNavigation) {
                        Qt.openUrlExternally(request.url)
                        request.action = WebEngineNavigationRequest.IgnoreRequest
                    }
                }
                onNewViewRequested: {
                    console.debug("New view request ", request, request.requestedUrl)
                    //We ignore requests for new views and open a browser instead
                    Qt.openUrlExternally(request.requestedUrl)
                }
                settings {
                    webGLEnabled: false
                    touchIconsEnabled: false
                    spatialNavigationEnabled: false
                    screenCaptureEnabled: false
                    pluginsEnabled: false
                    localStorageEnabled: false
                    localContentCanAccessRemoteUrls: false
                    localContentCanAccessFileUrls: false
                    linksIncludedInFocusChain: false
                    javascriptEnabled: true
                    javascriptCanOpenWindows: false
                    javascriptCanAccessClipboard: false
                    hyperlinkAuditingEnabled: false
                    fullScreenSupportEnabled: false
                    errorPageEnabled: false
                    //defaultTextEncoding: ???
                    autoLoadImages: root.autoLoadImages
                    autoLoadIconsForPage: false
                    accelerated2dCanvasEnabled: false
                    //The webview should not steal focus
                    focusOnNavigationEnabled: false
                }
                profile {
                    offTheRecord: true
                    httpCacheType: WebEngineProfile.NoCache
                    persistentCookiesPolicy: WebEngineProfile.NoPersistentCookies
                }
                onContextMenuRequested: function(request) {
                    request.accepted = true
                }
            }
        }
    }
}
