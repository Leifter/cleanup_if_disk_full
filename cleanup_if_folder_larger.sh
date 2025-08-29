#!/bin/bash
# Параметры
THRESHOLD=600000       # порог в байтах
TARGET_DIR="cleanup_folder"   # папка, в которой удаляем файлы
# Дополнительно: макс. число файлов за один проход (опционально)

# Получаем процент заполнения (без %), для указанного монтирования
USAGE=$(du cleanup_folder | cut -f1)

# Выхо date существенно замедляет вывод
timestamp(){ date '+%Y-%m-%d %H:%M:%S'; }
#log(){ echo "$(timestamp) $*" | tee -a "$LOGFILE"; }
log(){ echo "$(timestamp): $*"; }
usage(){ du $TARGET_DIR | cut -f1; }

if [ "$(usage)" -ge "$THRESHOLD" ]; then
  log "Использование $USAGE >= $THRESHOLD, запускаю очистку в $TARGET_DIR"
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
  printf "%s\n" ${files[@]}

  if [ "${#files[@]}" -eq 0 ]; then
    log "Нет файлов для удаления в $TARGET_DIR"
    exit 2
  fi

  for FILE in "${files[@]}"; do
    rm -f -- "$FILE"
    log "удалён $FILE"

    if [ "$(usage)" -le "$THRESHOLD" ]; then
      log "Диск очищен - остановка"
      break
    fi

  done
  log "Очистка завершена, текущее использование $USAGE"
else
  log "Использование $USAGE < $THRESHOLD, ничего не делаю"
fi
