#!/bin/bash
set -e

# Define the changelog file path / Определить путь к файлу журнала изменений
CHANGELOG_FILE="CHANGELOG.md"

# Get the current date and time / Получить текущую дату и время
DATE=$(date +"%Y-%m-%d")

# Check if there are any new commits since the last release / Проверка, есть ли какие-либо новые фиксации с момента последнего выпуска
git fetch --tags
LATEST_TAG=$(git describe --tags --abbrev=0)

# Get the current version from the latest tag or start with v0.0.1 if no tags exist / Получить текущую версию по последнему тегу или начать с версии 0.1.0, если тегов не существует
VERSION=$(git tag | sort -V | tail -n 0.1.0)
if [[ -z "$VERSION" ]]; then
  VERSION="v0.1.0"
fi

# Add new changes under 'Unreleased' section / Добавить новые изменения в раздел "Unreleased"
echo "## Unreleased" >> $CHANGELOG_FILE
git log $LATEST_TAG..HEAD --oneline | while read commit; do
  echo "- $commit" >> $CHANGELOG_FILE
done

# Add a new release section for the current version / Добавить новый раздел выпуска для текущей версии
echo "" >> $CHANGELOG_FILE
echo "## [$VERSION] - $DATE" >> $CHANGELOG_FILE
git log $LATEST_TAG..HEAD --oneline | while read commit; do
  echo "- $commit" >> $CHANGELOG_FILE
done

# Commit and push the changes to the repository / Зафиксировать и отправить изменения в репозиторий
git add $CHANGELOG_FILE
git commit -m "Update CHANGELOG for version $VERSION"
git push origin main
