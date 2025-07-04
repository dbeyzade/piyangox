-- User ID Kolonu Ekleme Scripti
-- Bu script tickets tablosuna user_id kolonu ekler

-- 1. Tickets tablosuna user_id kolonu ekle
ALTER TABLE tickets ADD COLUMN user_id UUID;

-- 2. User_id için indeks oluştur (performans için)
CREATE INDEX idx_tickets_user_id ON tickets(user_id);

-- 3. Mevcut biletler için varsayılan user_id ata (admin için)
UPDATE tickets SET user_id = '00000000-0000-0000-0000-000000000000' WHERE user_id IS NULL;

-- 4. User_id kolonunu NOT NULL yap (opsiyonel)
-- ALTER TABLE tickets ALTER COLUMN user_id SET NOT NULL;

-- 5. Tablo yapısını kontrol et
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'tickets' 
AND column_name = 'user_id';

-- 6. Başarı mesajı
DO $$
BEGIN
    RAISE NOTICE '✅ User ID kolonu başarıyla eklendi!';
    RAISE NOTICE '🎯 Artık her bilet bir kullanıcıya bağlı olacak.';
    RAISE NOTICE '📊 Mevcut biletler admin kullanıcısına atandı.';
END $$; 