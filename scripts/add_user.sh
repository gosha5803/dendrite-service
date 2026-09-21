#!/bin/bash
# Создание тестовых пользователей через Synapse-совместимый HTTP-эндпоинт.
# Работает снаружи контейнера — можно запускать с локальной машины.

set -e

# --- Конфигурация ---
HOMESERVER="${HOMESERVER:-https://your-app.up.railway.app}"
SHARED_SECRET="${MATRIX_REGISTRATION_SECRET:-changeme}"
INPUT_FILE="${INPUT_FILE:-$(dirname "$0")/users.csv}"

if [ ! -f "$INPUT_FILE" ]; then
    echo "❌ Файл $INPUT_FILE не найден."
    exit 1
fi

# --- Функция создания одного пользователя ---
create_user() {
    local username="$1"
    local password="$2"
    local is_admin="$3"

    # 1. Получаем nonce
    local nonce
    nonce=$(curl -s "$HOMESERVER/_synapse/admin/v1/register" | jq -r '.nonce')
    if [ -z "$nonce" ] || [ "$nonce" = "null" ]; then
        echo "❌ Не удалось получить nonce. Проверьте HOMESERVER и что registration_disabled: false."
        return 1
    fi

    # 2. Считаем HMAC-SHA1
    local user_type="notadmin"
    [ "$is_admin" = "1" ] && user_type="admin"

    local mac
    mac=$(printf '%s\0%s\0%s\0%s' "$nonce" "$username" "$password" "$user_type" \
        | openssl dgst -sha1 -hmac "$SHARED_SECRET" | awk '{print $2}')

    # 3. Отправляем POST
    local payload
    payload=$(jq -n \
        --arg nonce "$nonce" \
        --arg username "$username" \
        --arg password "$password" \
        --arg mac "$mac" \
        --argjson admin "$([ "$is_admin" = "1" ] && echo true || echo false)" \
        '{nonce: $nonce, username: $username, password: $password, mac: $mac, admin: $admin}')

    local response
    response=$(curl -s -X POST "$HOMESERVER/_synapse/admin/v1/register" \
        -H "Content-Type: application/json" \
        -d "$payload")

    if echo "$response" | jq -e '.user_id' >/dev/null 2>&1; then
        echo "✅ Пользователь $username создан ($(echo "$response" | jq -r '.user_id'))"
    else
        echo "❌ Ошибка при создании $username: $response"
        return 1
    fi
}

# --- Основной цикл ---
while IFS=',' read -r username password is_admin; do
    # Пропускаем пустые строки и комментарии
    [[ -z "$username" || "$username" == \#* ]] && continue

    # Убираем возможные \r (CRLF из Windows)
    username=$(echo "$username" | tr -d '\r')
    password=$(echo "$password" | tr -d '\r')
    is_admin=$(echo "$is_admin" | tr -d '\r')

    echo "Создание пользователя: $username"
    create_user "$username" "$password" "$is_admin" || true
done < "$INPUT_FILE"

echo "🎉 Готово."