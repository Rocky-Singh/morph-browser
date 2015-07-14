/*
 * Copyright 2015 Canonical Ltd.
 *
 * This file is part of webbrowser-app.
 *
 * webbrowser-app is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * webbrowser-app is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.0
import Ubuntu.Components 1.2
import Ubuntu.Components.ListItems 1.0 as ListItems
import webbrowserapp.private 0.1

Item {
    id: historyViewLandscape

    property alias historyModel: historyTimeframeModel.sourceModel
    property alias count: lastVisitDateListView.count

    signal historyEntryClicked(url url)
    signal historyEntryRemoved(url url)
    signal done()

    Rectangle {
        anchors.fill: parent
    }

    Row {
        anchors {
            top: topBar.bottom
            left: parent.left
            bottom: bottomToolbar.top
            leftMargin: units.gu(2)
            rightMargin: units.gu(2)
        }

        spacing: units.gu(2)

        ListView {
            id: lastVisitDateListView

            property int selectedIndex: -1

            width: units.gu(40)
            height: parent.height

            model: HistoryLastVisitDateListModel {
                sourceModel: HistoryTimeframeModel {
                    id: historyTimeframeModel
                }
            }

            header: ListItem {
                anchors {
                    left: parent.left
                    right: parent.right
                }

                width: parent.width
                height: units.gu(4)

                color: lastVisitDateListView.selectedIndex == -1 ? highlightColor : "transparent"

                Label {
                    anchors {
                        top: parent.top
                        left: parent.left
                        topMargin: units.gu(1)
                        leftMargin: units.gu(2)
                    }

                    height: parent.height

                    text: i18n.tr("All days")
                    fontSize: "small"
                }

                onClicked: {
                    lastVisitDateListView.selectedIndex = -1
                    urlsListView.model = historyViewLandscape.historyModel
                }
            }

            delegate: ListItem {
                anchors {
                    left: parent.left
                    right: parent.right
                }

                width: parent.width
                height: units.gu(4)

                color: lastVisitDateListView.selectedIndex == index ? highlightColor : "transparent"

                Label {
                    anchors {
                        top: parent.top
                        left: parent.left
                        topMargin: units.gu(1)
                        leftMargin: units.gu(2)
                    }

                    height: parent.height

                    text: {
                        var today = new Date()
                        today.setHours(0, 0, 0, 0)

                        var yesterday = new Date()
                        yesterday.setDate(yesterday.getDate() - 1)
                        yesterday.setHours(0, 0, 0, 0)

                        var entryDate = new Date(lastVisitDate)
                        entryDate.setHours(0, 0, 0, 0)
                         
                        if (entryDate.getTime() == today.getTime()) {
                            return i18n.tr("Today")
                        } else if (entryDate.getTime() == yesterday.getTime()) {
                            return i18n.tr("Yesterday")
                        }
                        return Qt.formatDate(lastVisitDate, Qt.DefaultLocaleLongDate)
                    }

                    fontSize: "small"
                }

                onClicked: {
                    lastVisitDateListView.selectedIndex = index
                    urlsListView.model = entries
                    urlsListView.ViewItems.selectedIndices = []
                }
            }
        }

        ListView {
            id: urlsListView
            width: historyViewLandscape.width - lastVisitDateListView.width
            height: parent.height

            model: historyViewLandscape.historyModel

            section.property: "lastVisitDate"
            section.delegate: HistorySectionDelegate {
                width: parent.width - units.gu(2)
                anchors.left: parent.left
                anchors.leftMargin: units.gu(2)
            }

            delegate: UrlDelegate{
                width: parent.width
                height: units.gu(5)
   
                icon: model.icon
                title: model.title ? model.title : model.url
                url: model.url

                headerComponent: Component {
                    Item {
                        height: units.gu(3)
                        width: timeLabel.width

                        Label {
                            id: timeLabel
                            anchors.centerIn: parent
                            text: Qt.formatDateTime(model.lastVisit, "hh:mm AP")
                            fontSize: "xx-small"
                        }
                    }
                }

                onClicked: 
                if (selectMode) {
                    selected = !selected
                } else {
                    historyViewLandscape.historyEntryClicked(model.url)
                }
 
                onRemoved: {
                    if (urlsListView.count == 1) {
                        historyViewLandscape.historyEntryRemoved(model.url)
                        lastVisitDateListView.selectedIndex = -1
                        urlsListView.model = historyViewLandscape.historyModel
                    } else {
                        historyViewLandscape.historyEntryRemoved(model.url)
                    }
                }

                onPressAndHold: {
                    selectMode = !selectMode
                    if (selectMode) {
                        urlsListView.ViewItems.selectedIndices = [index]
                    }
                }
            }
        }
    }

    Toolbar {
        id: topBar

        height: units.gu(7)

        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
        }

        Label {
            visible: !urlsListView.ViewItems.selectMode

            anchors {
                top: parent.top
                left: parent.left
                topMargin: units.gu(2)
                leftMargin: units.gu(2)
            }

            text: i18n.tr("Last Visited")    
        }

        ToolbarAction {
            visible: urlsListView.ViewItems.selectMode 

            anchors {
                top: parent.top
                left: parent.left
                leftMargin: units.gu(2)
            }
            height: parent.height - units.gu(2)
 
            iconName: "back"
            text: i18n.tr("Cancel")

            onClicked: urlsListView.ViewItems.selectMode = false
        }

        ToolbarAction {
            visible: urlsListView.ViewItems.selectMode

            anchors {
                top: parent.top
                right: deleteButton.left
                rightMargin: units.gu(2)
            }
            height: parent.height - units.gu(2)
 
            iconName: "select"
            text: i18n.tr("Select all")

            onClicked: {
                if (urlsListView.ViewItems.selectedIndices.length === urlsListView.count) {
                    urlsListView.ViewItems.selectedIndices = []
                } else {
                    var indices = []
                    for (var i = 0; i < urlsListView.count; ++i) {
                        indices.push(i)
                    }
                    urlsListView.ViewItems.selectedIndices = indices
                }
            }
        }

        ToolbarAction {
            id: deleteButton

            visible: urlsListView.ViewItems.selectMode

            anchors {
                top: parent.top
                right: parent.right
                rightMargin: units.gu(2)
            }
            height: parent.height - units.gu(2)

            iconName: "delete"
            text: i18n.tr("Delete")
            enabled: urlsListView.ViewItems.selectedIndices.length > 0
            onClicked: {
                var indices = urlsListView.ViewItems.selectedIndices
                var urls = []
                for (var i in indices) {
                    urls.push(urlsListView.model.get(indices[i])["url"])
                }
                urlsListView.ViewItems.selectMode = false
                for (var j in urls) {
                    historyModel.removeEntryByUrl(urls[j])
                }
            }
        }

        ListItems.ThinDivider {
            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
                bottomMargin: units.gu(1)
            }
        }
    }

    Toolbar {
        id: bottomToolbar
        height: units.gu(7)

        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }

        Button {
            objectName: "doneButton"
            anchors {
                left: parent.left
                leftMargin: units.gu(2)
                verticalCenter: parent.verticalCenter
            }

            strokeColor: UbuntuColors.darkGrey

            text: i18n.tr("Done")

            onClicked: historyViewLandscape.done()
        }

        ToolbarAction {
            anchors {
                right: parent.right
                rightMargin: units.gu(2)
                verticalCenter: parent.verticalCenter
            }
            height: parent.height - units.gu(2)

            text: i18n.tr("New tab")
            iconName: "tab-new"

            onClicked: {
                browser.openUrlInNewTab("", true)
                historyViewLandscape.done()
            }
        }
    }
}
