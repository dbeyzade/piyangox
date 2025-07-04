#!/bin/bash

# PiyangoX Desktop Installer
# Masaüstü uygulamasını sistem ile entegre eder

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DESKTOP_FILE="piyangox-desktop.desktop"
ICON_FILE="assets/icons/piyangox_icon.png"

# Renkli output için
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

echo_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

echo_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

echo_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Root kontrolü
if [[ $EUID -eq 0 ]]; then
    echo_error "Bu script root olarak çalıştırılmamalı!"
    exit 1
fi

echo_info "PiyangoX Desktop Installer başlatılıyor..."
echo_info "Kurulum dizini: $SCRIPT_DIR"
echo

# Gerekli dizinleri oluştur
echo_info "Gerekli dizinler oluşturuluyor..."
mkdir -p "$HOME/.local/share/applications"
mkdir -p "$HOME/.local/share/icons"
mkdir -p "$SCRIPT_DIR/logs"
mkdir -p "$SCRIPT_DIR/pids"

# Desktop entry kopyala
echo_info "Desktop entry kuruluyor..."
if [[ -f "$SCRIPT_DIR/$DESKTOP_FILE" ]]; then
    # Dosyadaki yolları güncelle
    sed "s|/home/ghost/Belgeler/piyango-projesi|$SCRIPT_DIR|g" "$SCRIPT_DIR/$DESKTOP_FILE" > "$HOME/.local/share/applications/$DESKTOP_FILE"
    chmod +x "$HOME/.local/share/applications/$DESKTOP_FILE"
    echo_success "Desktop entry kuruldu"
else
    echo_error "Desktop entry dosyası bulunamadı: $DESKTOP_FILE"
    exit 1
fi

# Icon kopyala
echo_info "Icon kuruluyor..."
if [[ -f "$SCRIPT_DIR/$ICON_FILE" ]]; then
    cp "$SCRIPT_DIR/$ICON_FILE" "$HOME/.local/share/icons/piyangox_icon.png"
    echo_success "Icon kuruldu"
else
    echo_error "Icon dosyası bulunamadı: $ICON_FILE"
    exit 1
fi

# Desktop dosyasını güncelle
update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true

# Sistem gereksinimlerini kontrol et
echo_info "Sistem gereksinimleri kontrol ediliyor..."

# Flutter kontrolü
if command -v flutter >/dev/null; then
    flutter_version=$(flutter --version | head -1)
    echo_success "Flutter mevcut: $flutter_version"
else
    echo_error "Flutter bulunamadı!"
    echo_info "Flutter yüklemek için: https://flutter.dev/docs/get-started/install/linux"
    exit 1
fi

# GTK kontrolü (Linux)
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    if pkg-config --exists gtk+-3.0; then
        gtk_version=$(pkg-config --modversion gtk+-3.0)
        echo_success "GTK+ 3.0 mevcut: $gtk_version"
    else
        echo_warning "GTK+ 3.0 development libraries eksik!"
        echo_info "Yüklemek için: sudo apt-get install libgtk-3-dev"
    fi
fi

# Dependencies yükle
echo_info "Flutter dependencies yükleniyor..."
cd "$SCRIPT_DIR"
flutter pub get || {
    echo_error "Flutter pub get başarısız!"
    exit 1
}
echo_success "Dependencies yüklendi"

# İlk build
echo_info "İlk build yapılıyor... (Bu biraz zaman alabilir)"
flutter build linux --release || {
    echo_error "Build başarısız!"
    exit 1
}
echo_success "Build tamamlandı!"

# Masaüstü kısayolu oluştur (isteğe bağlı)
echo_info "Masaüstü kısayolu oluşturmak ister misiniz? (y/n)"
read -r create_shortcut
if [[ "$create_shortcut" =~ ^[Yy]$ ]]; then
    if [[ -d "$HOME/Desktop" ]]; then
        cp "$HOME/.local/share/applications/$DESKTOP_FILE" "$HOME/Desktop/"
        chmod +x "$HOME/Desktop/$DESKTOP_FILE"
        echo_success "Masaüstü kısayolu oluşturuldu"
    else
        echo_warning "Desktop dizini bulunamadı"
    fi
fi

# Start menüsü yenile
if command -v gtk-update-icon-cache >/dev/null; then
    gtk-update-icon-cache -t "$HOME/.local/share/icons" 2>/dev/null || true
fi

echo
echo_success "🎉 PiyangoX Desktop kurulumu tamamlandı!"
echo
echo_info "Uygulamayı başlatmanın yolları:"
echo "  📱 Aplikasyon menüsünden: PiyangoX Desktop"
echo "  🖥️  Terminal'den: $SCRIPT_DIR/run-desktop.sh"
echo "  🔧 Admin modu: $SCRIPT_DIR/run-desktop.sh --admin"
echo "  🏪 Bayi modu: $SCRIPT_DIR/run-desktop.sh --bayi"
echo
echo_info "Kısayol tuşları (uygulama çalışırken):"
echo "  🔑 Ctrl+Shift+P: Pencereyi göster/gizle"
echo "  👨‍💼 Ctrl+Shift+A: Admin panel"
echo "  🏪 Ctrl+Shift+B: Bayi panel"
echo "  ⚙️ Ctrl+Shift+S: Ayarlar"
echo
echo_info "Log dosyaları: $SCRIPT_DIR/logs/"
echo
echo_success "Kurulum başarılı! Uygulamayı kullanmaya başlayabilirsiniz."

