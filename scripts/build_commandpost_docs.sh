#!/bin/bash

# ---------------------------------------------------------
#  Shell Script will exit immediately on a failed command:
# ---------------------------------------------------------
set -e

# -----------------------------
#  Go to CommandPost-App Path:
# -----------------------------
cd ../CommandPost-App/

# --------------------------------------
#  Build CommandPost-App Documentation:
# --------------------------------------
scripts/docs/bin/build_docs.py -o build/CommandPost-Docs/hs/ --markdown Hammerspoon/ extensions/
rm -R ../CommandPost-DeveloperGuide/api/hs/
mkdir ../CommandPost-DeveloperGuide/api/hs/
cp build/CommandPost-Docs/hs/markdown/* ../CommandPost-DeveloperGuide/api/hs/

# ----------------------------------
#  Build CommandPost Documentation:
# ----------------------------------
scripts/docs/bin/build_docs.py -o build/CommandPost-Docs/cp/ --standalone --debug --markdown ../CommandPost/src/extensions/cp/
rm -R ../CommandPost-DeveloperGuide/api/cp/
mkdir ../CommandPost-DeveloperGuide/api/cp/
cp build/CommandPost-Docs/cp/markdown/* ../CommandPost-DeveloperGuide/api/cp/