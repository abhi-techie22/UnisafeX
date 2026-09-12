-- Admin-managed currency rates for the Tourism Travel Toolkit.
-- Rates are USD-based: value means "1 USD equals this currency amount".

insert into public.app_settings(key, value)
values (
  'currency_rates',
  '{
    "base": "USD",
    "rates": {
      "USD": 1,
      "INR": 83.5,
      "EUR": 0.92,
      "GBP": 0.79,
      "AUD": 1.52,
      "CAD": 1.37,
      "AED": 3.6725,
      "SGD": 1.35,
      "JPY": 157.0,
      "THB": 36.7
    },
    "updated_at": "2026-01-01T00:00:00.000Z",
    "source": "seed"
  }'::jsonb
)
on conflict (key) do nothing;
