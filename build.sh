#!/usr/bin/env bash
# Builds the package, tests and demo for x86_64-linux and runs the tests; the counterpart of build.cmd.
# Set FRESNEL_DIR when Fresnel is not next to this repository. Set RIBBON_LAZBUILD to use another lazbuild.
# Exit codes: 0 ok, 1 tests failed, 2 tools or Fresnel missing, 3 architecture rule broken, 4 build failed.
# The last line is BUILD OK, TESTS PASSED only when everything succeeded.

set -u
cd "$(dirname "$0")"

LAZBUILD="${RIBBON_LAZBUILD:-lazbuild}"
export FRESNEL_DIR="${FRESNEL_DIR:-$(cd .. && pwd)/fresnel}"
# Its own Lazarus configuration, so the package links never touch the one of the user.
LAZCONFIG="$PWD/out/lazconfig"
TARGET=x86_64-linux
SKIADIR="$FRESNEL_DIR/bin/Binary/Shared/Linux64"
OUT="out/$TARGET"
LOG="$PWD/out/build.log"
TESTLOG="$PWD/out/tests.log"

command -v "$LAZBUILD" >/dev/null || { echo "lazbuild not found: $LAZBUILD"; exit 2; }
[ -f "$FRESNEL_DIR/src/fresnel.lpk" ] || { echo "Fresnel not found: $FRESNEL_DIR"; exit 2; }
[ "$(uname -m)" = x86_64 ] || { echo "Only x86_64 has a Skia library in Fresnel: $(uname -m)"; exit 2; }

mkdir -p "$OUT/icons"
: >"$LOG"
: >"$TESTLOG"

# Architecture rule (RB-NFR-101): src/model stays free of UI units.
if grep -Eiq 'Fresnel\.|[ ,]Forms[ ,;]|[ ,]Controls[ ,;]|[ ,]Graphics[ ,;]|[ ,]LCL' src/model/*.pas; then
  echo "Architecture rule broken: src/model uses a UI unit."
  exit 3
fi
# src/ uses no LCL units directly.
if grep -Eiq '[ ,]Interfaces[ ,;]|[ ,]Forms[ ,;]|[ ,]LCLType|[ ,]LCLIntf' src/*.pas; then
  echo "Architecture rule broken: src uses an LCL unit."
  exit 3
fi

echo "=== $TARGET"
for package in "$FRESNEL_DIR/src/base/fresnelbase.lpk" "$FRESNEL_DIR/src/fresnel.lpk" src/ohsribbon.lpk; do
  if ! "$LAZBUILD" --pcp="$LAZCONFIG" --add-package-link "$package" >>"$LOG" 2>&1; then
    echo "Build failed: registering $package, see out/build.log"
    exit 4
  fi
done
for project in src/ohsribbon.lpk test/ohsribbontests.lpi demo/ribbondemo.lpi; do
  if ! "$LAZBUILD" --pcp="$LAZCONFIG" --cpu=x86_64 --os=linux "$project" >>"$LOG" 2>&1; then
    echo "Build failed: $project for $TARGET, see out/build.log"
    exit 4
  fi
done

cp "$SKIADIR/libsk4d.so" "$OUT/"
cp demo/icons/*.png "$OUT/icons/"

echo "=== $TARGET" >>"$TESTLOG"
# The Fresnel test harness registers its own tests too, so run the ribbon suites by name.
for suite in TTestSizing TTestKeyTips TTestRibbon TTestTitleBar; do
  if ! LD_LIBRARY_PATH="$PWD/$OUT" "$OUT/ohsribbontests" --suite="$suite" --format=plain >>"$TESTLOG" 2>&1; then
    echo "Tests failed for $TARGET in $suite, see out/tests.log"
    exit 1
  fi
done

echo "BUILD OK, TESTS PASSED"
