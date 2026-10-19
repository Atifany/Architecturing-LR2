# Скрипт дампа keydb внутри контейенра

#!/bin/bash
HOST="127.0.0.1"
PORT="6379"
OUTPUT_FILE="keydb_data.txt"
> "$OUTPUT_FILE"

echo "Начало чтения изнутри контейнера..."
CURSOR="0"

while true; do
    # Читаем порцию данных и СРАЗУ удаляем невидимые символы \r
    SCAN_RESULT=$(keydb-cli -h "$HOST" -p "$PORT" SCAN "$CURSOR" COUNT 1000 | tr -d '\r')
    
    # Получаем следующий курсор
    NEXT_CURSOR=$(echo "$SCAN_RESULT" | head -n 1)
    
    # Получаем список ключей
    KEYS=$(echo "$SCAN_RESULT" | tail -n +2)
    
    if [ ! -z "$KEYS" ]; then
        echo "$KEYS" | while read -r KEY; do
            # Пропускаем пустые строки
            [ -z "$KEY" ] && continue
            
            # Получаем тип и значение, также очищая от \r
            TYPE=$(keydb-cli -h "$HOST" -p "$PORT" TYPE "$KEY" | tr -d '\r')
            
            case "$TYPE" in
                string)
                    VALUE=$(keydb-cli -h "$HOST" -p "$PORT" GET "$KEY")
                    ;;
                hash)
                    VALUE=$(keydb-cli -h "$HOST" -p "$PORT" HGETALL "$KEY" | tr -d '\r' | paste -d: - -)
                    ;;
                list)
                    VALUE=$(keydb-cli -h "$HOST" -p "$PORT" LRANGE "$KEY" 0 -1)
                    ;;
                set)
                    VALUE=$(keydb-cli -h "$HOST" -p "$PORT" SMEMBERS "$KEY")
                    ;;
                zset)
                    VALUE=$(keydb-cli -h "$HOST" -p "$PORT" ZRANGE "$KEY" 0 -1 WITHSCORES | tr -d '\r' | paste -d: - -)
                    ;;
                *)
                    VALUE="[Пусто или не поддерживается]"
                    ;;
            esac
            
            echo "Ключ: $KEY | Тип: $TYPE | Значение: $VALUE" >> "$OUTPUT_FILE"
        done
    fi
    
    CURSOR="$NEXT_CURSOR"
    
    # Теперь проверка сработает идеально
    if [ "$CURSOR" = "0" ]; then
        break
    fi
done

echo "Готово! Данные сохранены в контейнере в файл: $(pwd)/$OUTPUT_FILE"
echo "Количество найденных строк: $(wc -l < $OUTPUT_FILE)"
EOF
