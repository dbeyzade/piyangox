#!/bin/bash
cd /home/ghost/Belgeler/piyango-projesi

# Sessizce arka planda başlat
nohup flutter run -d linux --release >/dev/null 2>&1 &

# Process ID'yi kaydet
echo $! > /tmp/piyangox.pid

# Biraz bekle ki uygulama açılsın
sleep 5

# Başarı bildirimi göster
notify-send "PiyangoX" "Uygulama başlatıldı!" -i /home/ghost/Belgeler/piyango-projesi/assets/images/yonca.png -t 3000
