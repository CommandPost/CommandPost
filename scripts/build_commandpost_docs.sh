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
echo "Building CommandPost-App Documentation..."
scripts/docs/bin/build_docs.py -e ../CommandPost/scripts/docs/templates -o build/CommandPost-Docs/hs/ --markdown Hammerspoon/ extensions/
echo " - Documentation Created Successfully!"
echo " - Removing Old Files in CommandPost-DeveloperGuide"
rm -R ../CommandPost-DeveloperGuide/api/hs/
echo " - Recreating Directory in CommandPost-DeveloperGuide"
mkdir ../CommandPost-DeveloperGuide/api/hs/
echo " - Copying New Files to CommandPost-DeveloperGuide"
cp build/CommandPost-Docs/hs/markdown/* ../CommandPost-DeveloperGuide/api/hs/

# ---------------------------------------------
#  Build CommandPost Extensions Documentation:
# ---------------------------------------------
echo "Building CommandPost Extensions Documentation..."
scripts/docs/bin/build_docs.py -e ../CommandPost/scripts/docs/templates -o build/CommandPost-Docs/cp/ --standalone --debug --markdown ../CommandPost/src/extensions/cp/
echo " - Documentation Created Successfully!"
echo " - Removing Old Files in CommandPost-DeveloperGuide"
rm -R ../CommandPost-DeveloperGuide/api/cp/
echo " - Recreating Directory in CommandPost-DeveloperGuide"
mkdir ../CommandPost-DeveloperGuide/api/cp/
echo " - Copying New Files to CommandPost-DeveloperGuide"
cp build/CommandPost-Docs/cp/markdown/* ../CommandPost-DeveloperGuide/api/cp/

# ------------------------------------------
#  Build CommandPost Plugins Documentation:
# ------------------------------------------
echo "Building CommandPost Plugins Documentation..."
scripts/docs/bin/build_docs.py -e ../CommandPost/scripts/docs/templates -o build/CommandPost-Docs/plugins/ --standalone --debug --markdown ../CommandPost/src/plugins/
echo " - Documentation Created Successfully!"
echo " - Removing Old Files in CommandPost-DeveloperGuide"
rm -R ../CommandPost-DeveloperGuide/api/plugins/
echo " - Recreating Directory in CommandPost-DeveloperGuide"
mkdir ../CommandPost-DeveloperGuide/api/plugins/
echo " - Copying New Files to CommandPost-DeveloperGuide"
cp build/CommandPost-Docs/plugins/markdown/* ../CommandPost-DeveloperGuide/api/plugins/