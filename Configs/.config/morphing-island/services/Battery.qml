pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.UPower

// Battery via UPower (native, over D-Bus). Uses UPower's "display device", which aggregates the
// laptop's batteries; on a machine without a battery `available` stays false.
Singleton {
    id: root

    readonly property var device: UPower.displayDevice
    readonly property bool available: (device?.isLaptopBattery ?? false) && (device?.isPresent ?? false)
    // In Quickshell the percentage comes as 0..1 (a fraction), despite the name; if some version gives
    // it as 0..100 (the raw D-Bus value), it is used as is.
    readonly property real percent: available ? Math.max(0, Math.min(100, device.percentage > 1 ? device.percentage : device.percentage * 100)) : 0
    readonly property bool charging: available && device.state === UPowerDeviceState.Charging
    // On AC power: charging, fully charged or waiting to charge (charge limit).
    readonly property bool plugged: available && (!UPower.onBattery || [UPowerDeviceState.Charging, UPowerDeviceState.FullyCharged, UPowerDeviceState.PendingCharge].includes(device.state))
    // Seconds (0 while UPower has no estimate yet).
    readonly property real timeToEmpty: available ? device.timeToEmpty : 0
    readonly property real timeToFull: available ? device.timeToFull : 0
}
