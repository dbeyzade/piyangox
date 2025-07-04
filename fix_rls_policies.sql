-- RLS Devre Dışı Bırakma Scripti
-- Bu script test amaçlı RLS'yi devre dışı bırakır

-- Tickets tablosu için RLS'yi devre dışı bırak
ALTER TABLE tickets DISABLE ROW LEVEL SECURITY;

-- Campaigns tablosu için RLS'yi devre dışı bırak
ALTER TABLE campaigns DISABLE ROW LEVEL SECURITY;

-- Real-time için publication'a tabloları ekle (eğer yoksa)
ALTER PUBLICATION supabase_realtime ADD TABLE tickets;
ALTER PUBLICATION supabase_realtime ADD TABLE campaigns;

PRINT '✅ RLS başarıyla devre dışı bırakıldı! Artık tüm işlemler izin verilecek.'; 