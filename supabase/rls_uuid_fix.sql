-- =========================================================
-- SUPABASE UUID + RLS ALIGNMENT
-- Date: 2026-02-13
-- Target:
-- - permintaan.id_user UUID (auth.users.id)
-- - keranjang.id_user UUID (auth.users.id)
-- - users.auth_id UUID (auth.users.id)
-- - pengembalian.id_pinjam FK -> permintaan.id_permintaan ON DELETE CASCADE
-- =========================================================

begin;

-- ---------------------------------------------------------
-- 1) Schema alignment (types + not null)
-- ---------------------------------------------------------
do $$
begin
  if exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'permintaan'
      and column_name = 'id_user'
      and data_type <> 'uuid'
  ) then
    execute 'alter table public.permintaan alter column id_user type uuid using id_user::uuid';
  end if;
end $$;

do $$
begin
  if exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'keranjang'
      and column_name = 'id_user'
      and data_type <> 'uuid'
  ) then
    execute 'alter table public.keranjang alter column id_user type uuid using id_user::uuid';
  end if;
end $$;

do $$
begin
  if exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'users'
      and column_name = 'auth_id'
      and data_type <> 'uuid'
  ) then
    execute 'alter table public.users alter column auth_id type uuid using auth_id::uuid';
  end if;
end $$;

alter table public.permintaan alter column id_user set not null;
alter table public.keranjang alter column id_user set not null;
alter table public.users alter column auth_id set not null;

-- ---------------------------------------------------------
-- 2) Foreign key alignment pengembalian -> permintaan
-- ---------------------------------------------------------
alter table public.pengembalian
  drop constraint if exists pengembalian_id_pinjam_fkey;

alter table public.pengembalian
  add constraint pengembalian_id_pinjam_fkey
  foreign key (id_pinjam)
  references public.permintaan (id_permintaan)
  on delete cascade;

-- ---------------------------------------------------------
-- 3) Helper function: staff/admin from users.role
-- ---------------------------------------------------------
create or replace function public.is_staff()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.users u
    where u.auth_id = auth.uid()
      and lower(coalesce(u.role, '')) in ('admin', 'petugas')
  );
$$;

grant execute on function public.is_staff() to authenticated;

-- ---------------------------------------------------------
-- 4) Enable RLS
-- ---------------------------------------------------------
alter table public.permintaan enable row level security;
alter table public.pengembalian enable row level security;
alter table public.keranjang enable row level security;

-- ---------------------------------------------------------
-- 5) Drop old policies
-- ---------------------------------------------------------
drop policy if exists "permintaan_select_own" on public.permintaan;
drop policy if exists "permintaan_insert_own" on public.permintaan;
drop policy if exists "permintaan_update_own_return_request" on public.permintaan;
drop policy if exists "permintaan_staff_all" on public.permintaan;
drop policy if exists "permintaan_staff_select_all" on public.permintaan;
drop policy if exists "permintaan_staff_update_all" on public.permintaan;

drop policy if exists "pengembalian_select_own" on public.pengembalian;
drop policy if exists "pengembalian_insert_own" on public.pengembalian;
drop policy if exists "pengembalian_staff_all" on public.pengembalian;
drop policy if exists "pengembalian_staff_select_all" on public.pengembalian;
drop policy if exists "pengembalian_staff_update_all" on public.pengembalian;

drop policy if exists "keranjang_select_own" on public.keranjang;
drop policy if exists "keranjang_insert_own" on public.keranjang;
drop policy if exists "keranjang_update_own" on public.keranjang;
drop policy if exists "keranjang_update_delete_own" on public.keranjang;
drop policy if exists "keranjang_delete_own" on public.keranjang;

-- ---------------------------------------------------------
-- 6) PERMINTAAN policies
-- ---------------------------------------------------------
create policy "permintaan_select_own"
on public.permintaan
for select
to authenticated
using (id_user = auth.uid());

create policy "permintaan_insert_own"
on public.permintaan
for insert
to authenticated
with check (id_user = auth.uid());

create policy "permintaan_update_own_return_request"
on public.permintaan
for update
to authenticated
using (id_user = auth.uid())
with check (
  id_user = auth.uid()
  and status = 'pengembalian_diajukan'
);

create policy "permintaan_staff_select_all"
on public.permintaan
for select
to authenticated
using (public.is_staff());

create policy "permintaan_staff_update_all"
on public.permintaan
for update
to authenticated
using (public.is_staff())
with check (public.is_staff());

-- ---------------------------------------------------------
-- 7) PENGEMBALIAN policies
-- ---------------------------------------------------------
create policy "pengembalian_select_own"
on public.pengembalian
for select
to authenticated
using (
  exists (
    select 1
    from public.permintaan p
    where p.id_permintaan = pengembalian.id_pinjam
      and p.id_user = auth.uid()
  )
);

create policy "pengembalian_insert_own"
on public.pengembalian
for insert
to authenticated
with check (
  exists (
    select 1
    from public.permintaan p
    where p.id_permintaan = pengembalian.id_pinjam
      and p.id_user = auth.uid()
  )
);

create policy "pengembalian_staff_select_all"
on public.pengembalian
for select
to authenticated
using (public.is_staff());

create policy "pengembalian_staff_update_all"
on public.pengembalian
for update
to authenticated
using (public.is_staff())
with check (public.is_staff());

-- ---------------------------------------------------------
-- 8) KERANJANG policies
-- ---------------------------------------------------------
create policy "keranjang_select_own"
on public.keranjang
for select
to authenticated
using (id_user = auth.uid());

create policy "keranjang_insert_own"
on public.keranjang
for insert
to authenticated
with check (id_user = auth.uid());

create policy "keranjang_update_own"
on public.keranjang
for update
to authenticated
using (id_user = auth.uid())
with check (id_user = auth.uid());

create policy "keranjang_delete_own"
on public.keranjang
for delete
to authenticated
using (id_user = auth.uid());

commit;

-- ---------------------------------------------------------
-- Optional post-checks:
-- select table_name, column_name, data_type
-- from information_schema.columns
-- where table_schema = 'public'
--   and (table_name, column_name) in (
--     ('permintaan', 'id_user'),
--     ('keranjang', 'id_user'),
--     ('users', 'auth_id')
--   )
-- order by table_name, column_name;
-- ---------------------------------------------------------
