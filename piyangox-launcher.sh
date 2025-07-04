#!/bin/bash
# PiyangoX Başlatıcı Script

# Uygulama dizinine geç
cd /home/ghost/Belgeler/piyango-projesi

# Uygulamayı başlat
./build/linux/x64/release/bundle/piyangox

# Hata durumunda bekle
if [ $? -ne 0 ]; then
    echo "Uygulama başlatılamadı. Bir tuşa basın..."
    read -n 1
fi 