#!/bin/bash

echo "🚀 Supabase Demo Projesi Kurulumu"
echo "=================================="

echo "1. Tarayıcınızda https://supabase.com açın"
echo "2. 'Start your project' butonuna tıklayın"
echo "3. GitHub ile giriş yapın"
echo "4. 'New project' > 'piyangox-database' adıyla proje oluşturun"
echo "5. Database şifresini kaydedin!"
echo ""

echo "Proje oluştuktan sonra:"
echo "📋 Settings > API bölümünden URL ve Key'i kopyalayın"
echo "🔧 SQL Editor'de tabloları oluşturun"
echo ""

echo "Demo için hızlı kurulum:"
echo "curl -X POST 'YOUR_SUPABASE_URL/rest/v1/campaigns' \\"
echo "  -H 'apikey: YOUR_ANON_KEY' \\"
echo "  -H 'Content-Type: application/json' \\"
echo "  -d '{\"id\":\"demo-1\",\"name\":\"Demo Kampanya\"}'"

echo ""
echo "✅ Kurulum tamamlandıktan sonra lib/services/supabase_service.dart dosyasındaki"
echo "   URL ve KEY bilgilerini güncelleyin!"
