#!/bin/sh
# Build and exercise the native interfaces without linking Renaissance.
set -eu
cd "$(dirname "$0")/.."
test_dir=$(mktemp -d)
trap 'rm -rf "$test_dir"' EXIT HUP INT TERM
# gnustep-config emits compiler/linker argument lists intended for word splitting.
${CC:-clang} $(gnustep-config --objc-flags) -I. \
  Tests/NativeInterfaces.m EOModeler/EOMLayoutView.m \
  Apps/EOModelEditor/Resources/*Interface.m \
  Apps/EOModelEditor/Inspectors/*Interface.m \
  Apps/EOModelEditor/EOWindow.m \
  -o "$test_dir/native-interfaces" $(gnustep-config --gui-libs)
xvfb-run -a "$test_dir/native-interfaces"
${CC:-clang} $(gnustep-config --objc-flags) -I. -DLEGACY_EDITOR \
  Tests/NativeInterfaces.m EOModeler/EOMLayoutView.m \
  DBModeler/Resources/*Interface.m DBModeler/Inspectors/*Interface.m \
  -o "$test_dir/legacy-interfaces" $(gnustep-config --gui-libs)
xvfb-run -a "$test_dir/legacy-interfaces"
