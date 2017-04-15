#!/bin/bash

cd ../CommandPost-App/

scripts/docs/bin/build_docs.py -o ../CommandPost-Releases/Docs/cp.finalcutpro/ --standalone --debug --markdown ../CommandPost/src/extensions/cp/finalcutpro/
scripts/docs/bin/build_docs.py -o ../CommandPost-Releases/Docs/cp.just/ --standalone --debug --markdown ../CommandPost/src/extensions/cp/just/
scripts/docs/bin/build_docs.py -o ../CommandPost-Releases/Docs/cp.bench/ --standalone --debug --markdown ../CommandPost/src/extensions/cp/bench/
scripts/docs/bin/build_docs.py -o ../CommandPost-Releases/Docs/cp.choices/ --standalone --debug --markdown ../CommandPost/src/extensions/cp/choices/
scripts/docs/bin/build_docs.py -o ../CommandPost-Releases/Docs/cp.commands/ --standalone --debug --markdown ../CommandPost/src/extensions/cp/commands/