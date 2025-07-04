#!/bin/bash

# PiyangoX - Milli Piyango Yönetim Sistemi Başlatıcı
# Oluşturma Tarihi: $(date)

echo "🎯 PiyangoX Başlatılıyor..."

# Proje dizinine git
cd /home/ghost/Belgeler/piyango-projesi

# Flutter uygulamasını çalıştır
echo "📱 Flutter uygulaması açılıyor..."
flutter run -d linux --release

# Eğer hata olursa debug modda çalıştır
if [ $? -ne 0 ]; then
    echo "⚠️ Release modda hata, debug modda çalıştırılıyor..."
    flutter run -d linux
fi
