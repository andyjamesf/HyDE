#!/usr/bin/env bash
# Prints the hardware packages this PC needs, one per line: CPU microcode and Intel/AMD GPU drivers
# (Vulkan, video decoding). NVIDIA is handled separately by nvidia_detect. Read by install.sh.
# The kernel's own drivers (i915/xe, amdgpu) and mesa (OpenGL) are there already; these are the
# parts a plain Arch install leaves out.
set -euo pipefail

case "$(grep -m1 '^vendor_id' /proc/cpuinfo 2>/dev/null | awk '{print $3}')" in
GenuineIntel) echo intel-ucode ;;
AuthenticAMD) echo amd-ucode ;;
esac

# GPU vendors from sysfs (no lspci needed): 0x8086 Intel, 0x1002 AMD.
for vendor in $(cat /sys/class/drm/card*/device/vendor 2>/dev/null | sort -u); do
    case "$vendor" in
    0x8086) printf '%s\n' vulkan-intel intel-media-driver ;;
    0x1002) printf '%s\n' vulkan-radeon ;;
    esac
done
