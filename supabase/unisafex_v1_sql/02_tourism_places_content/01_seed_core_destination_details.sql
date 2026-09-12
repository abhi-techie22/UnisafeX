-- Older tourism seed data omitted the address column.
update public.tourism_places
set address = concat_ws(', ', nullif(city, ''), nullif(state, ''))
where address is null or btrim(address) = '';
