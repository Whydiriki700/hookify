-- Hookify license server (Supabase / Postgres)
-- Pola sama dengan osvyn_kunci: kode hanya hidup di server, aplikasi
-- memanggil dua RPC SECURITY DEFINER, RLS terkunci total.
-- Jalankan sekali di SQL Editor proyek Supabase yang sama dengan Osvyn.

create table if not exists public.hookify_kunci (
  kode text primary key,
  tier text not null check (tier in ('MON','YR','LIFE')),
  durasi_hari int not null,
  status text not null default 'terbit' check (status in ('terbit','aktif','hangus','cabut')),
  device_id text,
  device_label text,
  diterbitkan_pada timestamptz not null default now(),
  diaktifkan_pada timestamptz,
  kedaluwarsa_pada timestamptz,
  catatan text
);

create table if not exists public.hookify_upaya (
  device_id text not null,
  jendela timestamptz not null,
  gagal int not null default 0,
  primary key (device_id, jendela)
);

alter table public.hookify_kunci enable row level security;
alter table public.hookify_upaya enable row level security;
-- Tanpa policy publik: anon key tidak bisa membaca/menulis tabel langsung.

create or replace function public.hookify_aktivasi(p_kode text, p_device text, p_label text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  k public.hookify_kunci%rowtype;
  jendela_jam timestamptz := date_trunc('hour', now());
  jumlah_gagal int;
begin
  select gagal into jumlah_gagal from public.hookify_upaya
    where device_id = p_device and jendela = jendela_jam;
  if coalesce(jumlah_gagal, 0) >= 10 then
    return jsonb_build_object('ok', false, 'alasan', 'terlalu_banyak_percobaan');
  end if;

  select * into k from public.hookify_kunci
    where kode = upper(trim(p_kode)) for update;

  if not found then
    insert into public.hookify_upaya(device_id, jendela, gagal)
      values (p_device, jendela_jam, 1)
      on conflict (device_id, jendela)
      do update set gagal = public.hookify_upaya.gagal + 1;
    return jsonb_build_object('ok', false, 'alasan', 'tidak_terdaftar');
  end if;

  if k.status = 'cabut' then
    return jsonb_build_object('ok', false, 'alasan', 'dicabut');
  end if;

  if k.status = 'hangus' then
    return jsonb_build_object('ok', false, 'alasan', 'hangus');
  end if;

  if k.status = 'aktif' then
    if k.device_id is distinct from p_device then
      return jsonb_build_object('ok', false, 'alasan', 'dipakai_perangkat_lain');
    end if;
    -- Idempoten: perangkat yang sama mengaktifkan ulang.
    return jsonb_build_object('ok', true, 'tier', k.tier,
      'kedaluwarsa', k.kedaluwarsa_pada);
  end if;

  -- status 'terbit': ikat ke perangkat ini.
  update public.hookify_kunci
    set status = 'aktif',
        device_id = p_device,
        device_label = p_label,
        diaktifkan_pada = now(),
        kedaluwarsa_pada = now() + (durasi_hari || ' days')::interval
    where kode = k.kode
    returning * into k;

  return jsonb_build_object('ok', true, 'tier', k.tier,
    'kedaluwarsa', k.kedaluwarsa_pada);
end;
$$;

create or replace function public.hookify_cek(p_kode text, p_device text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  k public.hookify_kunci%rowtype;
begin
  select * into k from public.hookify_kunci where kode = upper(trim(p_kode));

  if not found then
    return jsonb_build_object('ok', false, 'alasan', 'tidak_terdaftar');
  end if;

  if k.device_id is distinct from p_device then
    return jsonb_build_object('ok', false, 'alasan', 'dipakai_perangkat_lain');
  end if;

  if k.status = 'cabut' then
    return jsonb_build_object('ok', false, 'alasan', 'dicabut');
  end if;

  if k.kedaluwarsa_pada is not null and k.kedaluwarsa_pada < now() then
    update public.hookify_kunci set status = 'hangus' where kode = k.kode;
    return jsonb_build_object('ok', false, 'alasan', 'hangus');
  end if;

  return jsonb_build_object('ok', true, 'tier', k.tier,
    'kedaluwarsa', k.kedaluwarsa_pada, 'status', k.status);
end;
$$;

revoke all on function public.hookify_aktivasi(text, text, text) from public;
revoke all on function public.hookify_cek(text, text) from public;
grant execute on function public.hookify_aktivasi(text, text, text) to anon, authenticated;
grant execute on function public.hookify_cek(text, text) to anon, authenticated;
