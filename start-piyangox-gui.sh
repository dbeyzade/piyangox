#!/bin/bash

# PiyangoX GUI Başlatıcı
cd /home/ghost/Belgeler/piyango-projesi

# Bildirim göster
notify-send "PiyangoX" "Uygulama başlatılıyor..." -i /home/ghost/Belgeler/piyango-projesi/assets/images/yonca.png

# Flutter uygulamasını başlat
exec flutter run -d linux
