-- RLS'yi Tamamen Devre Dışı Bırakma Scripti
-- Bu script tüm tablolarda RLS'yi devre dışı bırakır

-- 1. Tüm tablolarda RLS'yi devre dışı bırak
ALTER TABLE tickets DISABLE ROW LEVEL SECURITY;
ALTER TABLE campaigns DISABLE ROW LEVEL SECURITY;
ALTER TABLE shared_data DISABLE ROW LEVEL SECURITY;

-- 2. Tüm mevcut politikaları sil
-- Tickets tablosu için
DROP POLICY IF EXISTS "Enable read access for all users" ON tickets;
DROP POLICY IF EXISTS "Enable insert for all users" ON tickets;
DROP POLICY IF EXISTS "Enable update for all users" ON tickets;
DROP POLICY IF EXISTS "Enable delete for all users" ON tickets;
DROP POLICY IF EXISTS "Allow insert for authenticated users" ON tickets;
DROP POLICY IF EXISTS "Allow read for authenticated users" ON tickets;
DROP POLICY IF EXISTS "Allow update for authenticated users" ON tickets;
DROP POLICY IF EXISTS "Allow delete for authenticated users" ON tickets;

-- Campaigns tablosu için
DROP POLICY IF EXISTS "Enable read access for all users" ON campaigns;
DROP POLICY IF EXISTS "Enable insert for all users" ON campaigns;
DROP POLICY IF EXISTS "Enable update for all users" ON campaigns;
DROP POLICY IF EXISTS "Enable delete for all users" ON campaigns;
DROP POLICY IF EXISTS "Allow insert for authenticated users" ON campaigns;
DROP POLICY IF EXISTS "Allow read for authenticated users" ON campaigns;
DROP POLICY IF EXISTS "Allow update for authenticated users" ON campaigns;
DROP POLICY IF EXISTS "Allow delete for authenticated users" ON campaigns;

-- Shared_data tablosu için
DROP POLICY IF EXISTS "Enable read access for all users" ON shared_data;
DROP POLICY IF EXISTS "Enable update for admin users" ON shared_data;
DROP POLICY IF EXISTS "Enable insert for admin users" ON shared_data;

-- 3. Real-time için publication'a tabloları ekle
ALTER PUBLICATION supabase_realtime ADD TABLE tickets;
ALTER PUBLICATION supabase_realtime ADD TABLE campaigns;
ALTER PUBLICATION supabase_realtime ADD TABLE shared_data;

-- 4. Tabloların durumunu kontrol et
SELECT 
    schemaname,
    tablename,
    rowsecurity
FROM pg_tables 
WHERE tablename IN ('tickets', 'campaigns', 'shared_data');

-- 5. Başarı mesajı
DO $$
BEGIN
    RAISE NOTICE '✅ RLS başarıyla devre dışı bırakıldı!';
    RAISE NOTICE '🎉 Artık tüm işlemler izin verilecek.';
    RAISE NOTICE '⚠️  Bu ayar sadece test amaçlıdır, production\'da RLS aktif olmalıdır.';
END $$; 