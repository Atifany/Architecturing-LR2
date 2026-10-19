import time
from flask import Flask, jsonify
import redis

app = Flask(__name__)

# Подключаемся к Redis (в докере хостом будет имя сервиса - 'cache')
cache = redis.Redis(host='cache', port=6379, decode_responses=True)

# Симуляция тяжелой базы данных
def get_data_from_heavy_db():
    time.sleep(2.0) # Имитируем долгий запрос в 2 секунды
    return "Секретные данные из тяжелой БД"

@app.route('/data')
def get_data():
    # --- СТРАТЕГИЯ CACHE-ASIDE ---
    
    # 1. Пытаемся взять данные из кэша
    cached_value = cache.get("my_key")
    
    if cached_value:
        # Cache Hit! Данные нашлись в кэше, отдаем мгновенно
        return jsonify({"source": "CACHE (Redis)", "data": cached_value})
    
    # 2. Cache Miss! Данных в кэше нет -> идем в тяжелую БД
    db_value = get_data_from_heavy_db()
    
    # 3. Сохраняем данные в кэш на будущее (задаем TTL 10 секунд)
    cache.set("my_key", db_value, ex=10)
    
    # Отдаем пользователю медленные данные из БД
    return jsonify({"source": "HEAVY DATABASE", "data": db_value})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
