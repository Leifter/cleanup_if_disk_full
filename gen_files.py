#!/usr/bin/env python3
# -*- coding: utf-8 -*-

from pathlib import Path
from datetime import datetime, timedelta
import argparse

def parse_dates(args):
    # Вариант 1: последовательные даты от start_date, count штук, шаг days_step
    if args.start_date:
        start = datetime.strptime(args.start_date, args.date_format)
        return [ (start + i*timedelta(days=args.step_days)).strftime(args.date_format) for i in range(args.count) ]
    # Вариант 2: список дат через запятую
    if args.dates_list:
        items = [s.strip() for s in args.dates_list.split(',') if s.strip()]
        # Если передана строка дат в том же формате, просто вернуть
        return items
    # Вариант 3: одна и та же дата count раз
    return [ datetime.now().strftime(args.date_format) ] * args.count

def make_files(target_dir: Path, dates, name_pattern, ext, content_template, overwrite=False):
    target_dir.mkdir(parents=True, exist_ok=True)
    created = []
    for i, d in enumerate(dates, start=1):
        # Подставляем дату и индекс в шаблон имени
        fname = name_pattern.replace("{date}", d).replace("{i}", str(i))
        if ext and not fname.endswith(ext):
            fname = f"{fname}.{ext.lstrip('.')}"
        path = target_dir / fname
        if path.exists() and not overwrite:
            # Пропустить или добавить суффикс
            suffix = 1
            while (target_dir / f"{path.stem}_{suffix}{path.suffix}").exists():
                suffix += 1
            path = target_dir / f"{path.stem}_{suffix}{path.suffix}"
        # Сформировать содержимое
        content = content_template.replace("{date}", d).replace("{i}", str(i))
        path.write_text(content, encoding='utf-8')
        created.append(str(path))
    return created

def main():
    parser = argparse.ArgumentParser(description="Generate files with specified dates")
    parser.add_argument("--dir", "-d", default="out_files", help="target directory")
    parser.add_argument("--count", "-n", type=int, default=10, help="number of files to create")
    parser.add_argument("--start-date", help="start date for sequence, format defined in --date-format")
    parser.add_argument("--dates-list", help="comma-separated list of dates (alternative to --start-date)")
    parser.add_argument("--date-format", default="%Y-%m-%d", help="strftime format for dates (default: %%Y-%%m-%%d)")
    parser.add_argument("--step-days", type=int, default=1, help="step in days between dates for sequence")
    parser.add_argument("--name-pattern", default="file_{i}_{date}", help="file name pattern, use {date} and {i}")
    parser.add_argument("--ext", default="txt", help="file extension")
    parser.add_argument("--content", default="Date: {date}\nIndex: {i}\n", help="file content template")
    parser.add_argument("--overwrite", action="store_true", help="overwrite existing files")
    args = parser.parse_args()

    target_dir = Path(args.dir)
    dates = parse_dates(args)
    created = make_files(target_dir, dates, args.name_pattern, args.ext, args.content, args.overwrite)
    print("Created files:")
    for p in created:
        print(p)

if __name__ == "__main__":
    main()