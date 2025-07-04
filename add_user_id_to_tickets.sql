-- Tickets tablosuna userId sütunu ekleme
-- Bu scripti Supabase Dashboard > SQL Editor'da çalıştırın

-- 1. userId sütununu ekle
ALTER TABLE tickets ADD COLUMN IF NOT EXISTS user_id UUID;

-- 2. Mevcut kayıtları admin kullanıcısına ata (admin kullanıcısının ID'sini buraya yazın)
-- Önce admin kullanıcısının ID'sini bulun:
-- SELECT id FROM auth.users WHERE email = 'admin@piyangox.com';

-- Sonra bu ID'yi kullanarak mevcut kayıtları güncelleyin:
UPDATE tickets SET user_id = '00000000-0000-0000-0000-000000000000' WHERE user_id IS NULL;

-- 3. user_id sütununu NOT NULL yap
ALTER TABLE tickets ALTER COLUMN user_id SET NOT NULL;

-- 4. Index ekle
CREATE INDEX IF NOT EXISTS idx_tickets_user_id ON tickets(user_id);

-- 5. Schema cache'i yenilemek için:
-- Supabase Dashboard > Settings > API > Refresh Schema Cache butonuna tıklayın 