#!/bin/bash

set -x

echo "sh <branch> <commit comment>"

#if [ "$1" = "main" ]; then
#echo 'export const userBranch = "main";' > src/userbranch.js
#elif [ "$1" = "feature" ]; then
#echo 'export const userBranch = "feature";' > src/userbranch.js
#elif [ "$1" = "test" ]; then
#echo 'export const userBranch = "test";' > src/userbranch.js
#elif [ "$1" = "testf" ]; then
#echo 'export const userBranch = "testf";' > src/userbranch.js
#fi

git add .
git commit -m $2
git push origin "$1"

#rm -f src/userbranch.js

