-- RLS aktif et
ALTER TABLE tickets ENABLE ROW LEVEL SECURITY;

-- Sadece kendi user_id'siyle ekleme (INSERT)
CREATE POLICY "Allow insert for authenticated users"
ON tickets
FOR INSERT
USING (user_id = auth.uid());

-- Kullanıcıya sadece kendi biletlerini göster
CREATE POLICY "Allow select for authenticated users"
ON tickets
FOR SELECT
USING (user_id = auth.uid());

-- Sadece kendi user_id'siyle güncelleme (UPDATE)
CREATE POLICY "Allow update for authenticated users"
ON tickets
FOR UPDATE
USING (user_id = auth.uid());

-- Sadece kendi user_id'siyle silme (DELETE)
CREATE POLICY "Allow delete for authenticated users"
ON tickets
FOR DELETE
USING (user_id = auth.uid());

-- Admin'e tüm biletleri göster (ADMIN_UUID'yi kendi admin UUID'inle değiştir)
CREATE POLICY "Allow select for admin"
ON tickets
FOR SELECT
USING (auth.uid() = 'ADMIN_UUID'); 