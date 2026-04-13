#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="${PROJECT_DIR:-/opt/fastapi-todo-devops}"
TARGET_USER="${TARGET_USER:-$USER}"

echo "[bootstrap] Updating apt index..."
sudo apt-get update #Если минимальный Debian как у меня - сначала накатить sudo "apt install sudo", потом дать группу УЗ "sudo usermod -aG УЗ"

echo "[bootstrap] Installing base packages..."
sudo apt-get install -y   ca-certificates   curl   git   gnupg   lsb-release

if ! command -v docker >/dev/null 2>&1; then
  echo "[bootstrap] Installing Docker..."
  sudo install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  sudo chmod a+r /etc/apt/keyrings/docker.gpg

  echo     "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian     $(. /etc/os-release && echo "$VERSION_CODENAME") stable"     | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

  sudo apt-get update
  sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
else
  echo "[bootstrap] Docker already installed"
fi

echo "[bootstrap] Ensuring docker group membership..."
if getent group docker >/dev/null 2>&1; then
  sudo usermod -aG docker "$TARGET_USER" || true
fi

echo "[bootstrap] Creating project directory..."
sudo mkdir -p "$PROJECT_DIR"
sudo chown -R "$TARGET_USER":"$TARGET_USER" "$PROJECT_DIR"

echo "[bootstrap] Done"
echo "[bootstrap] Re-login may be required for docker group changes"