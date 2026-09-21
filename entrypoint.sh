#!/bin/sh
set -e

CONFIG_TEMPLATE="/etc/dendrite/dendrite.yaml.template"
CONFIG_FILE="/etc/dendrite/dendrite.yaml"
KEY_PATH="/etc/dendrite/matrix_key.pem"

# --- 1. Генерация ключа (если нет) ---
if [ ! -f "$KEY_PATH" ]; then
    echo "⚠️  Matrix key not found, generating..."
    /usr/bin/generate-keys -private-key "$KEY_PATH"
else
    echo "✅ Matrix key found, skipping generation."
fi

# --- 2. Подстановка переменных в конфиг ---
# Railway даёт PORT и DATABASE_URL. Если их нет — используем дефолты.
export PORT="${PORT:-8008}"
export DATABASE_URL="${DATABASE_URL:-file:/var/dendrite/dendrite.db?cache=shared&_pragma=busy_timeout(5000)}"
export DENDRITE_SERVER_NAME="${DENDRITE_SERVER_NAME:-localhost}"
export MATRIX_REGISTRATION_SECRET="${MATRIX_REGISTRATION_SECRET:-changeme}"

echo "🔧 Rendering config (PORT=$PORT, SERVER_NAME=$DENDRITE_SERVER_NAME)..."
envsubst < "$CONFIG_TEMPLATE" > "$CONFIG_FILE"

# --- 3. Запуск Dendrite ---
echo "🚀 Starting Dendrite Monolith on port $PORT..."
exec /usr/bin/dendrite-monolith-server \
    -config "$CONFIG_FILE" \
    -http-bind-address ":$PORT"