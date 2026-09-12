create or replace function public.toggle_tourism_place_like(p_place_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_changed integer := 0;
  v_likes integer := 1000;
  v_liked boolean := false;
begin
  if v_user_id is null then
    raise exception 'Login required to update a place like'
      using errcode = '28000';
  end if;

  delete from public.tourism_place_likes
  where user_id = v_user_id
    and place_id = p_place_id;

  get diagnostics v_changed = row_count;

  if v_changed = 1 then
    update public.tourism_places
    set likes_count = greatest(coalesce(likes_count, 1000) - 1, 1000)
    where place_id = p_place_id
    returning likes_count into v_likes;
    v_liked := false;
  else
    insert into public.tourism_place_likes (user_id, place_id)
    values (v_user_id, p_place_id)
    on conflict (user_id, place_id) do nothing;

    get diagnostics v_changed = row_count;

    if v_changed = 1 then
      update public.tourism_places
      set likes_count = greatest(coalesce(likes_count, 1000), 1000) + 1
      where place_id = p_place_id
      returning likes_count into v_likes;
    else
      select greatest(coalesce(likes_count, 1000), 1000)
      into v_likes
      from public.tourism_places
      where place_id = p_place_id;
    end if;
    v_liked := true;
  end if;

  if v_likes is null then
    raise exception 'Place not found'
      using errcode = 'P0002';
  end if;

  return jsonb_build_object(
    'likes_count', v_likes,
    'liked', v_liked
  );
end;
$$;

revoke all on function public.toggle_tourism_place_like(uuid) from public;
revoke all on function public.toggle_tourism_place_like(uuid) from anon;
grant execute on function public.toggle_tourism_place_like(uuid) to authenticated;
