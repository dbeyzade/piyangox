-- Tickets tablosuna draw_date alanını ekle
ALTER TABLE tickets ADD COLUMN IF NOT EXISTS draw_date timestamptz;

-- Mevcut biletlere varsayılan draw_date değeri ata (yarın saat 20:00)
UPDATE tickets 
SET draw_date = (CURRENT_DATE + INTERVAL '1 day' + INTERVAL '20 hours')
WHERE draw_date IS NULL; 