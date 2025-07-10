-- Supabase'de admin kullanıcısı oluşturma script'i
-- Bu script'i Supabase Dashboard > SQL Editor'da çalıştırın

-- 1. Admin kullanıcısını auth.users tablosuna ekle
INSERT INTO auth.users (
  id,
  email,
  encrypted_password,
  email_confirmed_at,
  created_at,
  updated_at,
  raw_app_meta_data,
  raw_user_meta_data,
  is_super_admin,
  confirmation_token,
  email_change,
  email_change_token_new,
  recovery_token
) VALUES (
  gen_random_uuid(),
  'admin@piyangox.com',
  crypt('123456', gen_salt('bf')),
  now(),
  now(),
  now(),
  '{"provider": "email", "providers": ["email"], "role": "admin"}',
  '{"name": "Admin Kullanıcı"}',
  false,
  '',
  '',
  '',
  ''
);

-- 2. Admin kullanıcısının ID'sini al
SELECT id, email, raw_app_meta_data FROM auth.users WHERE email = 'admin@piyangox.com';

-- 3. Test kullanıcısı da ekle
INSERT INTO auth.users (
  id,
  email,
  encrypted_password,
  email_confirmed_at,
  created_at,
  updated_at,
  raw_app_meta_data,
  raw_user_meta_data,
  is_super_admin,
  confirmation_token,
  email_change,
  email_change_token_new,
  recovery_token
) VALUES (
  gen_random_uuid(),
  'test@piyangox.com',
  crypt('123456', gen_salt('bf')),
  now(),
  now(),
  now(),
  '{"provider": "email", "providers": ["email"], "role": "member"}',
  '{"name": "Test Kullanıcı"}',
  false,
  '',
  '',
  '',
  ''
);

-- 4. Tüm kullanıcıları listele
SELECT id, email, raw_app_meta_data, created_at FROM auth.users ORDER BY created_at DESC; 