#!/bin/bash
# Параметры
TARGET_MOUNT="/media/pi/dns_ssd"
#THRESHOLD=85          # порог в процентах — если >=, запускаем очистку
THRESHOLD=60          # порог в процентах — если >=, запускаем очистку
TARGET_DIR="/media/pi/dns_ssd/camera.snt/upload"   # папка, в которой удаляем файлы
MIN_FREE_BELOW=45      # хотим снизить заполнение ниже этого значения
#MIN_FREE_BELOW=80      # хотим снизить заполнение ниже этого значения
# Дополнительно: макс. число файлов за один проход (опционально)
MAX_DELETE=1000

# Получаем процент заполнения (без %), для указанного монтирования
USAGE=$(df --output=pcent "$TARGET_MOUNT" | tail -1 | tr -dc '0-9')

timestamp(){ date '+%Y-%m-%d %H:%M:%S'; }
#log(){ echo "$(timestamp) $*" | tee -a "$LOGFILE"; }
log(){ echo "$(timestamp): $*"; }

# Функция для проверки и удаления
if [ -z "$USAGE" ]; then
  log "Не удалось получить использование диска"
  exit 1
fi

if [ "$USAGE" -ge "$THRESHOLD" ]; then
  log "Использование $USAGE% >= $THRESHOLD%, запускаю очистку в $TARGET_DIR"
  # Удаляем по одному (или пачкой) самым старым файлам, пока usage < MIN_FREE_BELOW или пока не удалим MAX_DELETE
  COUNT=0

  # Собираем список файлов (старые первые), один раз. Безопасно для имён с пробелами/спецсимволами.
  # Выводим только путь, NUL-терминированный.
  mapfile -d '' files < <(
    find "$TARGET_DIR" -type f -printf '%T@ %p\0' 2>/dev/null | 
    # сортируем по метке времени (число секунд с плавающей точкой)
    sort -z -n |
    # Берем только путь
    awk -v RS='\0' '{ split($0, a, " "); t=a[1]; sub(/^[^ ]+ /,"",$0); printf "%s\0", $0 }'
  )

  # Отладочный вывод найденных файлов
  # printf "%s\n" ${files[@]}

  if [ "${#files[@]}" -eq 0 ]; then
    log "Нет файлов для удаления в $TARGET_DIR"
    exit 2
  fi

  for FILE in "${files[@]}"; do
    rm -f -- "$FILE"
    log "удалён $FILE"
    COUNT=$((COUNT + 1))

    rem=$(( COUNT % 10 ))
    if ((rem == 0)); then
      USAGE=$(df --output=pcent "$TARGET_MOUNT" | tail -1 | tr -dc '0-9')
    fi

    if [ "$USAGE" -le "$MIN_FREE_BELOW" ]; then
      log "Диск очищен - остановка"
      break
    fi

    if [ "$COUNT" -gt "$MAX_DELETE" ]; then
      log "Максимальное число удаляемых файлов достигнуто остановка"
      break
    fi

  done
  log "Очистка завершена, текущее использование $USAGE%"
else
  log "Использование $USAGE% < $THRESHOLD%, ничего не делаю"
fi
