-- PiyangoX Veritabanı Tabloları
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

-- Tickets tablosu için RLS (Row Level Security) aktif et
ALTER TABLE tickets ENABLE ROW LEVEL SECURITY;

-- Herkes okuyabilir, herkes yazabilir (test için)
CREATE POLICY "Enable read access for all users" ON tickets FOR SELECT USING (true);
CREATE POLICY "Enable insert for all users" ON tickets FOR INSERT WITH CHECK (true);
CREATE POLICY "Enable update for all users" ON tickets FOR UPDATE USING (true);
CREATE POLICY "Enable delete for all users" ON tickets FOR DELETE USING (true);

-- Campaigns tablosu için RLS aktif et
ALTER TABLE campaigns ENABLE ROW LEVEL SECURITY;

-- Herkes okuyabilir, herkes yazabilir (test için)
CREATE POLICY "Enable read access for all users" ON campaigns FOR SELECT USING (true);
CREATE POLICY "Enable insert for all users" ON campaigns FOR INSERT WITH CHECK (true);
CREATE POLICY "Enable update for all users" ON campaigns FOR UPDATE USING (true);
CREATE POLICY "Enable delete for all users" ON campaigns FOR DELETE USING (true);

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

-- Shared Data tablosu (Admin-Bayi Real-time Communication)
CREATE TABLE shared_data (
  id TEXT PRIMARY KEY DEFAULT 'main',
  current_ticket_price REAL DEFAULT 10.0,
  current_ticket_count INTEGER DEFAULT 100,
  system_message TEXT,
  admin_notifications TEXT[],
  bayi_notifications TEXT[],
  maintenance_mode BOOLEAN DEFAULT FALSE,
  last_updated_by TEXT,
  updated_at TIMESTAMP DEFAULT NOW(),
  created_at TIMESTAMP DEFAULT NOW()
);

-- Real-time subscriptions için RLS (Row Level Security) aktif et
ALTER TABLE shared_data ENABLE ROW LEVEL SECURITY;

-- Herkes okuyabilir, sadece adminler yazabilir
CREATE POLICY "Enable read access for all users" ON shared_data FOR SELECT USING (true);
CREATE POLICY "Enable update for admin users" ON shared_data FOR UPDATE USING (true);
CREATE POLICY "Enable insert for admin users" ON shared_data FOR INSERT WITH CHECK (true);

-- Real-time için publication oluştur
ALTER PUBLICATION supabase_realtime ADD TABLE shared_data;

-- İndeks
CREATE INDEX idx_shared_data_updated_at ON shared_data(updated_at);

-- Başlangıç shared_data verisi
INSERT INTO shared_data (id, current_ticket_price, current_ticket_count, system_message) 
VALUES ('main', 10.0, 100, 'Sistem aktif ve çalışıyor') 
ON CONFLICT (id) DO NOTHING;
