alter table public.guide_requests
  add column if not exists guide_name text,
  add column if not exists guide_photo_url text,
  add column if not exists guide_phone text,
  add column if not exists guide_languages text,
  add column if not exists guide_experience_years integer
    check (guide_experience_years is null or guide_experience_years >= 0),
  add column if not exists guide_bio text,
  add column if not exists guide_charge_amount numeric(10,2)
    check (guide_charge_amount is null or guide_charge_amount >= 0),
  add column if not exists guide_charge_currency text not null default 'INR',
  add column if not exists guide_meeting_point text,
  add column if not exists booking_status text not null default 'not_booked'
    check (booking_status in ('not_booked', 'booked', 'cancelled')),
  add column if not exists booked_at timestamptz;

create index if not exists guide_requests_booking_status_idx
  on public.guide_requests(booking_status);

create or replace function public.book_guide_request(p_request_id uuid)
returns public.guide_requests
language plpgsql
security definer
set search_path = public
as $$
declare
  v_request public.guide_requests;
begin
  update public.guide_requests
  set booking_status = 'booked',
      booked_at = coalesce(booked_at, now()),
      updated_at = now()
  where id = p_request_id
    and user_id = auth.uid()
    and status = 'confirmed'
    and guide_name is not null
    and guide_charge_amount is not null
    and booking_status <> 'booked'
  returning * into v_request;

  if v_request.id is null then
    raise exception 'Guide request is not ready for booking'
      using errcode = 'P0001';
  end if;

  return v_request;
end;
$$;

revoke all on function public.book_guide_request(uuid) from public;
grant execute on function public.book_guide_request(uuid) to authenticated;
