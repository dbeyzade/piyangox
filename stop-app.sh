#!/bin/bash

# PiyangoX uygulamasını kapat
echo "PiyangoX kapatılıyor..."

# Derlenmiş uygulama process'ini bul ve kapat
pkill -f "piyangox"

# Flutter process'lerini de kapat (varsa)
pkill -f "flutter.*linux"

# PID dosyası varsa sil
if [ -f /tmp/piyangox.pid ]; then
    rm /tmp/piyangox.pid
fi

# Bildirim göster
notify-send "PiyangoX" "✅ Uygulama kapatıldı!" -i /home/ghost/Belgeler/piyango-projesi/assets/images/yonca.png -t 2000

echo "✅ PiyangoX kapatıldı!"
