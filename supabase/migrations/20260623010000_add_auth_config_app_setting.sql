-- Remote auth UI mode for UniSafeX.
-- This does not replace Supabase Auth provider settings; it controls app copy
-- and app-side buttons while the real confirmation setting remains in
-- Supabase Dashboard > Authentication > Providers > Email.

insert into public.app_settings(key, value)
values (
  'auth_config',
  '{
    "email_confirmation_required": true,
    "show_resend_confirmation": true
  }'::jsonb
)
on conflict (key) do nothing;
