#!/bin/bash
# Assemble a thin AppDir/ for pj_bridge_ros2 that uses a system ROS 2 install.
# usage: make_ros_appdir.sh <ros_distro> [appdir]
set -euo pipefail

if (( $# < 1 || $# > 2 )); then
  echo "usage: $0 <ros_distro> [appdir]" >&2
  exit 2
fi

ROS_DISTRO_EXPECTED="$1"
APPDIR="${2:-AppDir}"

if [[ ! "$ROS_DISTRO_EXPECTED" =~ ^[a-z][a-z0-9_]*$ ]]; then
  echo "invalid ROS distribution: '$ROS_DISTRO_EXPECTED'" >&2
  exit 2
fi

SOURCE_BINARY="install/pj_bridge/lib/pj_bridge/pj_bridge_ros2"
if [[ ! -x "$SOURCE_BINARY" ]]; then
  echo "pj_bridge executable not found: $SOURCE_BINARY" >&2
  exit 1
fi

mkdir -p "$APPDIR"/usr/bin
cp "$SOURCE_BINARY" "$APPDIR/usr/bin/"

cat > "$APPDIR/pj_bridge.desktop" <<'DESKTOP'
[Desktop Entry]
Name=pj_bridge
Exec=pj_bridge_ros2
Icon=pj_bridge
Type=Application
Categories=Science;
DESKTOP

cp pj_bridge.png "$APPDIR/pj_bridge.png"

cat > "$APPDIR/AppRun" <<'APPRUN'
#!/bin/bash
set -e

SELF="$(readlink -f "$0")"
HERE="${SELF%/*}"
EXPECTED_ROS_DISTRO="@ROS_DISTRO@"

if [[ -n "${ROS_DISTRO:-}" && "$ROS_DISTRO" != "$EXPECTED_ROS_DISTRO" ]]; then
  echo "pj_bridge requires ROS 2 ${EXPECTED_ROS_DISTRO}; current ROS_DISTRO is '${ROS_DISTRO}'" >&2
  exit 1
fi

if [[ -z "${ROS_DISTRO:-}" ]]; then
  ROS_SETUP="/opt/ros/${EXPECTED_ROS_DISTRO}/setup.bash"
  if [[ ! -f "$ROS_SETUP" ]]; then
    echo "pj_bridge requires ROS 2 ${EXPECTED_ROS_DISTRO} at /opt/ros/${EXPECTED_ROS_DISTRO}" >&2
    exit 1
  fi
  # shellcheck disable=SC1090
  source "$ROS_SETUP"
fi

exec "${HERE}/usr/bin/pj_bridge_ros2" "$@"
APPRUN

sed -i "s/@ROS_DISTRO@/$ROS_DISTRO_EXPECTED/g" "$APPDIR/AppRun"
chmod +x "$APPDIR/AppRun"
