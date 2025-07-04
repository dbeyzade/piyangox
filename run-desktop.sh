#!/bin/bash

# PiyangoX Desktop Launcher Script
# Enhanced desktop version with system tray and window management

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$SCRIPT_DIR/logs/piyangox-desktop.log"
PID_FILE="$SCRIPT_DIR/pids/piyangox-desktop.pid"

# Gerekli dizinleri oluştur
mkdir -p "$SCRIPT_DIR/logs" "$SCRIPT_DIR/pids"

# Logging fonksiyonu
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# PID kontrolü - çoklu instance önleme
check_running() {
    if [[ -f "$PID_FILE" ]]; then
        local pid=$(cat "$PID_FILE")
        if ps -p "$pid" > /dev/null 2>&1; then
            log "⚠️  PiyangoX zaten çalışıyor (PID: $pid)"
            # Mevcut pencereyi göster
            if command -v wmctrl >/dev/null; then
                wmctrl -a "PiyangoX" 2>/dev/null || true
            fi
            exit 1
        else
            rm -f "$PID_FILE"
        fi
    fi
}

# Cleanup fonksiyonu
cleanup() {
    log "🧹 Temizlik yapılıyor..."
    [[ -f "$PID_FILE" ]] && rm -f "$PID_FILE"
    exit 0
}

# Signal handlers
trap cleanup SIGTERM SIGINT

# System gereksinimlerini kontrol et
check_requirements() {
    log "🔍 Sistem gereksinimleri kontrol ediliyor..."
    
    # Flutter kontrolü
    if ! command -v flutter >/dev/null; then
        log "❌ Flutter bulunamadı! Lütfen Flutter'ı yükleyin."
        exit 1
    fi
    
    # GTK geliştirme kütüphaneleri kontrolü (Linux için)
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if ! pkg-config --exists gtk+-3.0; then
            log "⚠️  GTK+ 3.0 development libraries eksik!"
            log "📦 Yüklemek için: sudo apt-get install libgtk-3-dev"
        fi
    fi
    
    log "✅ Sistem gereksinimleri tamam"
}

# Flutter build fonksiyonu
build_if_needed() {
    local build_dir="$SCRIPT_DIR/build/linux/x64/release/bundle"
    local main_file="$SCRIPT_DIR/lib/main.dart"
    
    # Build gerekli mi kontrol et
    if [[ ! -d "$build_dir" ]] || [[ "$main_file" -nt "$build_dir" ]]; then
        log "🔨 Uygulama build ediliyor..."
        
        cd "$SCRIPT_DIR"
        
        # Dependencies yükle
        flutter pub get || {
            log "❌ Flutter pub get başarısız!"
            exit 1
        }
        
        # Linux için build
        flutter build linux --release || {
            log "❌ Flutter build başarısız!"
            exit 1
        }
        
        log "✅ Build tamamlandı"
    else
        log "✅ Build güncel, tekrar build gerekmiyor"
    fi
}

# Uygulama çalıştırma fonksiyonu
run_app() {
    local mode="$1"
    local app_path="$SCRIPT_DIR/build/linux/x64/release/bundle/piyangox"
    
    if [[ ! -f "$app_path" ]]; then
        log "❌ Uygulama dosyası bulunamadı: $app_path"
        exit 1
    fi
    
    log "🚀 PiyangoX Desktop başlatılıyor..."
    log "📁 Çalışma dizini: $SCRIPT_DIR"
    log "🎯 Mod: ${mode:-normal}"
    
    # Uygulama argümanları
    local args=()
    case "$mode" in
        "admin")
            args+=("--admin-mode")
            log "👨‍💼 Admin modunda başlatılıyor"
            ;;
        "bayi")
            args+=("--bayi-mode")
            log "🏪 Bayi modunda başlatılıyor"
            ;;
        "settings")
            args+=("--settings-mode")
            log "⚙️ Ayarlar modunda başlatılıyor"
            ;;
    esac
    
    # PID kaydet
    cd "$SCRIPT_DIR"
    
    # Uygulamayı başlat
    "$app_path" "${args[@]}" &
    local app_pid=$!
    echo "$app_pid" > "$PID_FILE"
    
    log "✅ PiyangoX başlatıldı (PID: $app_pid)"
    log "🔑 Kısayollar:"
    log "   📋 Ctrl+Shift+P: Pencereyi göster/gizle"
    log "   👨‍💼 Ctrl+Shift+A: Admin panel"
    log "   🏪 Ctrl+Shift+B: Bayi panel"
    log "   ⚙️ Ctrl+Shift+S: Ayarlar"
    
    # Uygulama bitene kadar bekle
    wait "$app_pid"
    local exit_code=$?
    
    log "🔚 PiyangoX sonlandı (Exit code: $exit_code)"
    rm -f "$PID_FILE"
    
    return $exit_code
}

# Ana fonksiyon
main() {
    log "🎯 PiyangoX Desktop Launcher başlatıldı"
    log "💻 İşletim sistemi: $OSTYPE"
    log "📂 Proje dizini: $SCRIPT_DIR"
    
    # Argüman parse et
    local mode=""
    case "$1" in
        "--admin"|"-a")
            mode="admin"
            ;;
        "--bayi"|"-b")
            mode="bayi"
            ;;
        "--settings"|"-s")
            mode="settings"
            ;;
        "--help"|"-h")
            echo "PiyangoX Desktop Launcher"
            echo "Kullanım: $0 [options]"
            echo ""
            echo "Seçenekler:"
            echo "  --admin, -a     Admin modunda başlat"
            echo "  --bayi, -b      Bayi modunda başlat"
            echo "  --settings, -s  Ayarlar modunda başlat"
            echo "  --help, -h      Bu yardım mesajını göster"
            exit 0
            ;;
    esac
    
    # Kontroller ve başlatma
    check_running
    check_requirements
    build_if_needed
    run_app "$mode"
}

# Script'i çalıştır
main "$@"
