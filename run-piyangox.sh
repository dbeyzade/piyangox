#!/bin/bash

# PiyangoX - Milli Piyango Yönetim Sistemi Başlatıcı
# Oluşturma Tarihi: $(date)

echo "🎯 PiyangoX Başlatılıyor..."

# Proje dizinine git
cd /home/ghost/Belgeler/piyango-projesi

# Uygulamayı çalıştır
echo "📱 Uygulama açılıyor..."
./build/linux/x64/release/bundle/piyangox

echo "👋 PiyangoX kapatıldı." 