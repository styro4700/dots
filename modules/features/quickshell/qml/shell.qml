import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Io
import QtQuick

ShellRoot {
    property bool notifVisible: false

    ListModel { id: toastModel }

    // sweeps expired toasts every half second, cheap enough for a handful of items
    Timer {
        interval: 500
        running: toastModel.count > 0
        repeat: true
        onTriggered: {
            const now = Date.now();
            for (let i = toastModel.count - 1; i >= 0; i--) {
                const t = toastModel.get(i);
                // also drop toasts whose notification was dismissed elsewhere
                if (t.expiresAt <= now || !t.notifObj || !t.notifObj.tracked) toastModel.remove(i);
            }
        }
    }

    NotificationServer {
        id: notifServer
        onNotification: notification => {
            notification.tracked = true;
            // critical toasts stay until clicked; everything else lasts 5s
            const critical = notification.urgency === NotificationUrgency.Critical;
            toastModel.append({ notifObj: notification, expiresAt: critical ? 1e15 : Date.now() + 5000 });
        }
    }

    IpcHandler {
        target: "notifications"
        function toggle(): void {
            notifVisible = !notifVisible;
        }
    }

    Wallpaper {}
    Bar {
        server: notifServer
        onToggleRequested: notifVisible = !notifVisible
    }
    Popups {
        model: toastModel
    }
    NotificationCenter {
        server: notifServer
        visible: notifVisible
        onCloseRequested: notifVisible = false
    }
}
