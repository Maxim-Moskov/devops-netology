#!/bin/bash

# --- Проверка запуска от root ---
if [[ $EUID -ne 0 ]]; then
    echo "Ошибка: скрипт должен быть запущен с правами root."
    exit 1
fi

# --- Проверка аргументов ---
if [[ $# -lt 2 ]]; then
    echo "Использование: $0 PREFIX INTERFACE [SUBNET] [HOST]"
    exit 1
fi

PREFIX="$1"
INTERFACE="$2"
SUBNET="$3"
HOST="$4"

# --- Проверка интерфейса ---
if ! ip link show "$INTERFACE" &>/dev/null; then
    echo "Ошибка: интерфейс '$INTERFACE' не найден. Доступные интерфейсы:"
    ip -o link show | awk -F': ' '{print $2}'
    exit 1
fi

# --- Проверка правильности префикса ---
if [[ ! "$PREFIX" =~ ^([0-9]{1,3})(\.[0-9]{1,3}){1,3}$ ]]; then
    echo "Ошибка: Некорректный префикс '$PREFIX'."
    exit 1
fi

# Разбор префикса на октеты
IFS='.' read -r o1 o2 o3 o4 <<< "$PREFIX"

# --- Функция сканирования одного IP ---
scan_ip() {
    local ip="$1"
    echo "Сканирование: $ip ..."
    if arping -c 1 -I "$INTERFACE" "$ip" &>/dev/null; then
        echo " [✔] Хост $ip доступен"
    else
        echo " [✘] Хост $ip недоступен"
    fi
}

# --- Логика выбора диапазона ---
if [[ -z "$SUBNET" ]]; then
    # Сканирование всех подсетей (192.168.{1..255}.{1..255})
    for s in {1..255}; do
        for h in {1..255}; do
            scan_ip "$PREFIX.$s.$h"
        done
    done
elif [[ -z "$HOST" ]]; then
    # Сканирование всех хостов внутри подсети (192.168.SUBNET.{1..255})
    for h in {1..255}; do
        scan_ip "$PREFIX.$SUBNET.$h"
    done
else
    # Сканирование одного IP
    scan_ip "$PREFIX.$SUBNET.$HOST"
fi
