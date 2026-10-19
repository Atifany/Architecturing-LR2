# Скрипт дампа keydb снаруди контейенра

#!/bin/bash

CONTAINER_NAME="keydb"
OUTPUT_FILE="docker_keydb_dump.txt"

# log
echo "Экспорт данных из Docker-контейнера $CONTAINER_NAME..."

# сканирование контейнера
docker exec -i "$CONTAINER_NAME" keydb-cli --eval /dev/stdin <<< '
local cursor = "0"
local result = {}
repeat
    local scan_res = redis.call("SCAN", cursor, "COUNT", 1000)
    cursor = scan_res[1]
    for _, key in ipairs(scan_res[2]) do
        local type_res = redis.call("TYPE", key)["ok"]
        local val = ""
        if type_res == "string" then val = redis.call("GET", key)
        elseif type_res == "hash" then val = table.concat(redis.call("HGETALL", key), ", ")
        else val = "[" .. type_res .. "]" end
        table.insert(result, "Key: " .. key .. " | Val: " .. tostring(val))
    end
until cursor == "0"
return result
' > "$OUTPUT_FILE"

# log
echo "Готово! Данные в файле $OUTPUT_FILE"