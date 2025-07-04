#!/bin/bash
while true; do
  inotifywait -e modify,create,delete -r lib/ assets/ pubspec.yaml
  echo "Kod değişti, yeni build alınıyor..."
  flutter build linux
  echo "Build tamamlandı."
done 