#!/bin/bash
cd /home/ghost/Belgeler/piyango-projesi

# Bildirim göster
notify-send "PiyangoX" "Hızlı başlatılıyor..." -i /home/ghost/Belgeler/piyango-projesi/assets/images/yonca.png -t 2000

# Derlenmiş uygulamayı direkt çalıştır (çok hızlı!)
nohup ./build/linux/x64/release/bundle/piyangox >/dev/null 2>&1 &

# Process ID'yi kaydet
echo $! > /tmp/piyangox.pid

# Kısa bekle
sleep 1

# Başarı bildirimi
notify-send "PiyangoX" "✅ Uygulama açıldı!" -i /home/ghost/Belgeler/piyango-projesi/assets/images/yonca.png -t 2000
