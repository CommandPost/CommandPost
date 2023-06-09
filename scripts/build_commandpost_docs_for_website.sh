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
scripts/docs/bin/build_docs.py --title "CommandPost" --source_url_base "https://github.com/CommandPost/CommandPost-App/blob/master/" --templates ../CommandPost/scripts/templates --output_dir build/CommandPost-Docs/hs/ --markdown Hammerspoon/ extensions/
echo " - Documentation Created Successfully!"
echo " - Removing Old Files in CommandPost-Website"
rm -R ../CommandPost-Website/docs/api-references/hammerspoon/
echo " - Recreating Directory in CommandPost-Website"
mkdir ../CommandPost-Website/docs/api-references/hammerspoon/
echo " - Copying New Files to CommandPost-Website"
cp build/CommandPost-Docs/hs/markdown/* ../CommandPost-Website/docs/api-references/hammerspoon/
cp /Users/chrishocking/Documents/GitHub/CommandPost-Website/docs/api-references/hammerspoon.yml /Users/chrishocking/Documents/GitHub/CommandPost-Website/docs/api-references/hammerspoon/index.yml


# ---------------------------------------------
#  Build CommandPost Extensions Documentation:
# ---------------------------------------------
echo "Building CommandPost Extensions Documentation..."
scripts/docs/bin/build_docs.py --title "CommandPost" --source_url_base "https://github.com/CommandPost/CommandPost/blob/master/" --templates ../CommandPost/scripts/templates --output_dir build/CommandPost-Docs/cp/ --standalone --markdown ../CommandPost/src/extensions/cp/
echo " - Documentation Created Successfully!"
echo " - Removing Old Files in CommandPost-Website"
rm -R ../CommandPost-Website/docs/api-references/commandpost/
echo " - Recreating Directory in CommandPost-Website"
mkdir ../CommandPost-Website/docs/api-references/commandpost/
echo " - Copying New Files to CommandPost-Website"
cp build/CommandPost-Docs/cp/markdown/* ../CommandPost-Website/docs/api-references/commandpost/
cp /Users/chrishocking/Documents/GitHub/CommandPost-Website/docs/api-references/commandpost.yml /Users/chrishocking/Documents/GitHub/CommandPost-Website/docs/api-references/commandpost/index.yml

# ------------------------------------------
#  Build CommandPost Plugins Documentation:
# ------------------------------------------
echo "Building CommandPost Plugins Documentation..."
scripts/docs/bin/build_docs.py --title "CommandPost" --source_url_base "https://github.com/CommandPost/CommandPost/blob/master/" --templates ../CommandPost/scripts/templates --output_dir build/CommandPost-Docs/plugins/ --standalone --markdown ../CommandPost/src/plugins/
echo " - Documentation Created Successfully!"
echo " - Removing Old Files in CommandPost-Website"
rm -R ../CommandPost-Website/docs/api-references/plugins/
echo " - Recreating Directory in CommandPost-Website"
mkdir ../CommandPost-Website/docs/api-references/plugins/
echo " - Copying New Files to CommandPost-Website"
cp build/CommandPost-Docs/plugins/markdown/* ../CommandPost-Website/docs/api-references/plugins/
cp /Users/chrishocking/Documents/GitHub/CommandPost-Website/docs/api-references/plugins.yml /Users/chrishocking/Documents/GitHub/CommandPost-Website/docs/api-references/plugins/index.yml