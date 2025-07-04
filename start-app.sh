#!/bin/bash
cd /home/ghost/Belgeler/piyango-projesi

# Flutter uygulamasını başlat
flutter run -d linux --release &

# Biraz bekle
sleep 3

# Eğer process çalışmıyorsa debug modda dene
if ! pgrep -f "flutter.*linux" > /dev/null; then
    flutter run -d linux &
fi
