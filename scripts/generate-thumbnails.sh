#!/bin/sh
#
# Runs before commit message is added
# Exit non-zero to abort commit
# bypass with git commit --no-verify
# Needs executable permissions
# No arguments are passed to pre-commit

echo "Starting Commit Hook"

# Locate AllSpice
unameOut="$(uname -s)"
case "${unameOut}" in
    Linux*)     machine=Linux;;
    Darwin*)    machine=Mac;;
    CYGWIN*)    machine=Cygwin;;
    MINGW*)     machine=MinGw;;
    MSYS*)      machine=Win;;
    *)          machine="UNKNOWN:${unameOut}"
esac

if [ ${machine} == Win ] || [ ${machine} == MinGw ] || [ ${machine} == Cygwin ]; then 
  ALLSPICE=~/AppData/Local/Programs/allspice/resources/utils/allspice.dist/allspice
elif [ ${machine} == Mac ] || [ ${machine} == Linux ]; then 
  ALLSPICE=/Applications/allspice/MacOS/allspice/resources/utils/allspice.dist/allspice
else
  echo "Unsupported machine ${machine}"; exit 1
fi

[ -f $ALLSPICE ] || echo "AllSpice not found. Download at www.allspice.io/download"

# Handle initial commit: diff against an empty tree object
if git rev-parse --verify HEAD >/dev/null 2>&1; then
  against=HEAD
else
  against=$(git hash-object -t tree /dev/null)
fi

modifiedSchematics=$(git diff --cached --diff-filter=M --name-only $against | grep -iE -- '\**.schdoc$|\**.pcbdoc$')
allSchematics=$(git ls-files --cached | grep -iE -- '\**.schdoc$|\**.pcbdoc$')

IFS=$(echo -en "\n\b")

# Render each modified schematic file
for f in $modifiedSchematics; do 
  outfile=".allspice/$f"
  echo "Generating ${outfile}.svg"
  "${ALLSPICE}" convert --svg --no-json --output "$outfile" "$f"
  git add --force "${outfile}.svg"
done

# Render each schematic file that does not have an svg
for f in $allSchematics; do
  outfile=".allspice/$f"
  if [ ! -f "${outfile}.svg" ]; then
    echo "Generating ${outfile}.svg"
    mkdir -p "$(dirname "${outfile}")"
    "${ALLSPICE}" convert --svg --no-json --output "$outfile" "$f"
    git add --force "${outfile}.svg"
  fi
done