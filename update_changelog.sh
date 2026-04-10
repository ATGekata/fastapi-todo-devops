#!/bin/bash
set -e

# Define the changelog file path / Определить путь к файлу журнала изменений
CHANGELOG_FILE="CHANGELOG.md"

# Get the current date and time / Получить текущую дату и время
DATE=$(date +"%Y-%m-%d")

# Check if there are any new commits since the last release / Проверка, есть ли какие-либо новые фиксации с момента последнего выпуска
git fetch --tags >/dev/null 2>&1 || true
LATEST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || true)

# Get the current version from the latest tag or start with v0.0.1 if no tags exist / Получить текущую версию по последнему тегу или начать с версии 0.1.0, если тегов не существует
if [ -n "$LATEST_TAG" ]; then
  VERSION="$LATEST_TAG"
  COMMITS=$(git log "${LATEST_TAG}..HEAD" --oneline)
else
  VERSION="v0.1.0"
  COMMITS=$(git log --oneline)
fi

cat > "$CHANGELOG_FILE" <<EOF
# CHANGELOG

## Unreleased

EOF

if [ -n "$COMMITS" ]; then
  echo "$COMMITS" | while read -r commit; do
    echo "- $commit" >> "$CHANGELOG_FILE"
  done
else
  echo "- No new changes" >> "$CHANGELOG_FILE"
fi

cat >> "$CHANGELOG_FILE" <<EOF

## ${VERSION} - ${DATE}

EOF

if [ -n "$COMMITS" ]; then
  echo "$COMMITS" | while read -r commit; do
    echo "- $commit" >> "$CHANGELOG_FILE"
  done
else
  echo "- Initial release state" >> "$CHANGELOG_FILE"
fi

echo "CHANGELOG.md успешно обновлён"