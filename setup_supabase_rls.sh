#!/bin/bash

echo "🔧 Supabase RLS Politikalarını Düzeltme"
echo "========================================"

# Supabase URL ve API Key'i kontrol et
if [ -z "$SUPABASE_URL" ] || [ -z "$SUPABASE_ANON_KEY" ]; then
    echo "❌ Hata: SUPABASE_URL ve SUPABASE_ANON_KEY environment değişkenleri ayarlanmamış!"
    echo "Lütfen .env dosyasını kontrol edin veya environment değişkenlerini ayarlayın."
    exit 1
fi

echo "📡 Supabase'e bağlanılıyor..."
echo "URL: $SUPABASE_URL"

# SQL scriptini çalıştır
echo "🔧 RLS politikaları uygulanıyor..."

# curl ile SQL scriptini çalıştır
curl -X POST "$SUPABASE_URL/rest/v1/rpc/exec_sql" \
  -H "apikey: $SUPABASE_ANON_KEY" \
  -H "Authorization: Bearer $SUPABASE_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d @fix_rls_policies.sql

if [ $? -eq 0 ]; then
    echo "✅ RLS politikaları başarıyla uygulandı!"
    echo "🎉 Artık bilet ekleme işlemleri çalışacak."
else
    echo "❌ RLS politikaları uygulanırken hata oluştu!"
    echo "Manuel olarak Supabase Dashboard'dan uygulayabilirsiniz:"
    echo "1. Supabase Dashboard'a gidin"
    echo "2. SQL Editor'ü açın"
    echo "3. fix_rls_policies.sql dosyasının içeriğini yapıştırın"
    echo "4. Çalıştırın"
fi

echo ""
echo "📋 Manuel Uygulama Adımları:"
echo "1. Supabase Dashboard'a gidin"
echo "2. SQL Editor'ü açın"
echo "3. Aşağıdaki SQL'i yapıştırın ve çalıştırın:"
echo ""
cat fix_rls_policies.sql
echo ""
echo "✅ İşlem tamamlandı!" 