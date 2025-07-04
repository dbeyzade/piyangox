# 🚀 Supabase Kurulum Rehberi - PiyangoX

## 1. Supabase Hesabı Oluşturma

1. **https://supabase.com** adresine gidin
2. **"Start your project"** butonuna tıklayın
3. **GitHub** ile giriş yapın (ücretsiz)
4. **"New project"** butonuna tıklayın

## 2. Proje Ayarları

- **Project name:** `piyangox-database`
- **Database Password:** Güçlü bir şifre oluşturun (KAYDEDIN!)
- **Region:** Europe West (Ireland) - en yakın
- **Pricing Plan:** Free tier (0$/ay)

## 3. Veritabanı Tabloları

Proje oluştuktan sonra **SQL Editor**'e gidin ve şu kodları çalıştırın:

```sql
-- Campaigns tablosu
CREATE TABLE campaigns (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  ticket_count INTEGER NOT NULL,
  last_digit_count INTEGER NOT NULL,
  chance_count INTEGER NOT NULL,
  ticket_price REAL NOT NULL,
  prize_amount TEXT NOT NULL,
  upper_prize TEXT NOT NULL,
  lower_prize TEXT NOT NULL,
  prize_currency TEXT NOT NULL,
  custom_currency TEXT,
  draw_date TIMESTAMP NOT NULL,
  is_completed BOOLEAN DEFAULT FALSE,
  winning_number TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Tickets tablosu
CREATE TABLE tickets (
  id TEXT PRIMARY KEY,
  campaign_id TEXT REFERENCES campaigns(id) ON DELETE CASCADE,
  numbers TEXT[] NOT NULL,
  price REAL NOT NULL,
  status TEXT NOT NULL,
  buyer_name TEXT,
  buyer_phone TEXT,
  sold_at TIMESTAMP,
  paid_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW(),
  is_winner BOOLEAN DEFAULT FALSE,
  winner_type TEXT,
  win_amount REAL,
  draw_date TIMESTAMP,
  auto_cancel BOOLEAN DEFAULT TRUE
);

-- İndeksler (performans için)
CREATE INDEX idx_campaigns_created_at ON campaigns(created_at);
CREATE INDEX idx_tickets_campaign_id ON tickets(campaign_id);
CREATE INDEX idx_tickets_status ON tickets(status);
CREATE INDEX idx_tickets_created_at ON tickets(created_at);
```

## 4. Proje Bilgilerini Alma

1. **Settings** > **API** bölümüne gidin
2. **Project URL** ve **anon public** anahtarını kopyalayın
3. Bu bilgileri `lib/services/supabase_service.dart` dosyasına yapıştırın

## 5. Güvenlik Ayarları (Row Level Security)

```sql
-- RLS'i etkinleştir
ALTER TABLE campaigns ENABLE ROW LEVEL SECURITY;
ALTER TABLE tickets ENABLE ROW LEVEL SECURITY;

-- Herkese okuma izni ver (demo için)
CREATE POLICY "Allow public read access" ON campaigns FOR SELECT USING (true);
CREATE POLICY "Allow public read access" ON tickets FOR SELECT USING (true);

-- Herkese yazma izni ver (demo için)
CREATE POLICY "Allow public write access" ON campaigns FOR ALL USING (true);
CREATE POLICY "Allow public write access" ON tickets FOR ALL USING (true);
```

## 6. Test Verisi (Opsiyonel)

```sql
-- Test kampanyası
INSERT INTO campaigns (
  id, name, ticket_count, last_digit_count, chance_count, 
  ticket_price, prize_amount, upper_prize, lower_prize, 
  prize_currency, draw_date
) VALUES (
  'test-campaign-1', 'Test Kampanyası', 1000, 2, 3, 
  10.0, '100000', '50000', '25000', 
  'tl', NOW() + INTERVAL '7 days'
);
```

## 7. Bağlantı Testi

Uygulamayı çalıştırın ve console'da şu mesajı görmelisiniz:
```
✅ Supabase bağlantısı başarılı
```

## 🎯 Sonuç

- **Depolama:** 500MB ücretsiz (milyonlarca kayıt)
- **API çağrıları:** Sınırsız
- **Gerçek zamanlı:** Otomatik senkronizasyon
- **Backup:** Otomatik yedekleme
- **Güvenlik:** Enterprise düzeyde

Artık verileriniz bulutta güvenli! 🎉
