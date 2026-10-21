-- Retail + Pharmacy POS extension. Creates pharmacy tables only; does not drop existing tables.
create extension if not exists pgcrypto;

create table if not exists public.pharmacy_products (
 id uuid primary key default gen_random_uuid(), name text not null, sku text unique, barcode text,
 active_ingredient text, strength text, dosage_form text, category text not null default 'General',
 selling_price numeric(12,2) not null default 0 check (selling_price >= 0),
 reorder_level integer not null default 0 check (reorder_level >= 0),
 prescription_required boolean not null default false, active boolean not null default true,
 created_by uuid references auth.users(id) on delete set null,
 created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.pharmacy_batches (
 id uuid primary key default gen_random_uuid(),
 product_id uuid not null references public.pharmacy_products(id) on delete restrict,
 batch_number text not null, expiry_date date not null,
 quantity_received integer not null check (quantity_received > 0),
 quantity_available integer not null check (quantity_available >= 0),
 cost_price numeric(12,2) not null default 0 check (cost_price >= 0),
 selling_price numeric(12,2) not null default 0 check (selling_price >= 0),
 supplier_name text, purchase_reference text, received_at timestamptz not null default now(),
 created_by uuid references auth.users(id) on delete set null, created_at timestamptz not null default now(),
 unique(product_id,batch_number), check (quantity_available <= quantity_received)
);
create table if not exists public.pharmacy_prescriptions (
 id uuid primary key default gen_random_uuid(), prescription_number text not null unique,
 patient_name text not null, patient_reference text, prescriber_name text not null, prescriber_registration text,
 prescribed_at timestamptz not null default now(), valid_until date, notes text,
 status text not null default 'pending' check (status in ('pending','validated','dispensed','cancelled','rejected')),
 validated_by uuid references auth.users(id) on delete set null, validated_at timestamptz,
 created_by uuid references auth.users(id) on delete set null, created_at timestamptz not null default now()
);
create table if not exists public.pharmacy_dispensing (
 id uuid primary key default gen_random_uuid(), receipt_number text not null unique,
 patient_name text not null default 'Walk-in',
 prescription_id uuid references public.pharmacy_prescriptions(id) on delete restrict,
 payment_method text not null default 'cash' check (payment_method in ('cash','mpesa','card','insurance','credit')),
 subtotal numeric(12,2) not null default 0 check (subtotal >= 0),
 discount_amount numeric(12,2) not null default 0 check (discount_amount >= 0),
 tax_amount numeric(12,2) not null default 0 check (tax_amount >= 0),
 total_amount numeric(12,2) not null default 0 check (total_amount >= 0),
 amount_paid numeric(12,2) not null default 0 check (amount_paid >= 0),
 status text not null default 'completed' check (status in ('draft','completed','voided','refunded')),
 notes text, dispensed_by uuid references auth.users(id) on delete set null, created_at timestamptz not null default now()
);
create table if not exists public.pharmacy_dispensing_items (
 id uuid primary key default gen_random_uuid(),
 dispensing_id uuid not null references public.pharmacy_dispensing(id) on delete cascade,
 product_id uuid not null references public.pharmacy_products(id) on delete restrict,
 batch_id uuid references public.pharmacy_batches(id) on delete restrict,
 prescription_id uuid references public.pharmacy_prescriptions(id) on delete restrict,
 quantity integer not null check (quantity > 0), unit_price numeric(12,2) not null check (unit_price >= 0),
 line_total numeric(12,2) not null check (line_total >= 0), created_at timestamptz not null default now()
);
create table if not exists public.pharmacy_stock_movements (
 id uuid primary key default gen_random_uuid(),
 product_id uuid not null references public.pharmacy_products(id) on delete restrict,
 batch_id uuid references public.pharmacy_batches(id) on delete restrict,
 movement_type text not null check (movement_type in ('opening','purchase','sale','return','adjustment','expired','damaged','transfer')),
 quantity_change integer not null check (quantity_change <> 0), reference_number text, notes text,
 performed_by uuid references auth.users(id) on delete set null, created_at timestamptz not null default now()
);
create index if not exists pharmacy_batches_product_expiry_idx on public.pharmacy_batches(product_id,expiry_date);
create index if not exists pharmacy_batches_expiry_idx on public.pharmacy_batches(expiry_date) where quantity_available > 0;
create index if not exists pharmacy_prescriptions_status_date_idx on public.pharmacy_prescriptions(status,prescribed_at desc);
create index if not exists pharmacy_dispensing_created_idx on public.pharmacy_dispensing(created_at desc);
create index if not exists pharmacy_dispensing_items_sale_idx on public.pharmacy_dispensing_items(dispensing_id);
create index if not exists pharmacy_stock_movements_product_date_idx on public.pharmacy_stock_movements(product_id,created_at desc);

-- Authentication profiles and role definitions. Never store passwords in public.users.
create table if not exists public.roles (
 id integer primary key, name text not null unique, description text
);
insert into public.roles (id,name,description) values
 (1,'Administrator','Full pharmacy administration'),
 (2,'Pharmacist','Prescription review and dispensing'),
 (3,'Manager','Pharmacy operations and reporting'),
 (4,'Cashier','Point of sale and customer transactions'),
 (5,'Stock Manager','Stock and batch management')
on conflict (id) do update set name=excluded.name,description=excluded.description;

create table if not exists public.users (
 id uuid primary key references auth.users(id) on delete cascade,
 email text not null unique,
 full_name text not null default '',
 role_id integer references public.roles(id),
 role text not null default 'Cashier',
 role_name text not null default 'Cashier',
 status text not null default 'active' check(status in ('active','inactive','suspended')),
 pin text, pin_enabled boolean not null default false, phone text,
 last_login timestamptz, created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);
alter table public.users add column if not exists role_name text not null default 'Cashier';
alter table public.users add column if not exists role text not null default 'Cashier';
alter table public.users add column if not exists role_id integer references public.roles(id);
alter table public.users add column if not exists status text not null default 'active';
alter table public.users add column if not exists pin text;
alter table public.users add column if not exists pin_enabled boolean not null default false;
alter table public.users add column if not exists phone text;
alter table public.users add column if not exists last_login timestamptz;
alter table public.users add column if not exists updated_at timestamptz not null default now();

insert into public.users (id,email,full_name,role_id,role,role_name,status,pin_enabled)
select id,email,'Pharma Pharmacy Administrator',1,'Admin','Administrator','active',false
from auth.users where lower(email)='admin@pharma.co.ke' and email_confirmed_at is not null
on conflict (id) do update set role_id=1,role='Admin',role_name='Administrator',status='active',updated_at=now();

alter table public.roles enable row level security;
alter table public.users enable row level security;
revoke all on public.roles from anon;
revoke all on public.users from anon;
grant select on public.roles to authenticated;
grant select on public.users to authenticated;
drop policy if exists roles_authenticated_select on public.roles;
create policy roles_authenticated_select on public.roles for select to authenticated using (
 exists(select 1 from public.users u where u.id=auth.uid() and u.status='active')
);
drop policy if exists users_select_self on public.users;
create policy users_select_self on public.users for select to authenticated using (id=auth.uid());

-- Strict active-staff policies; no public/anonymous access and no DELETE policy by default.
do $$
declare t text;
begin
 foreach t in array array['pharmacy_products','pharmacy_batches','pharmacy_prescriptions','pharmacy_dispensing','pharmacy_dispensing_items','pharmacy_stock_movements'] loop
  execute format('alter table public.%I enable row level security',t);
  execute format('drop policy if exists %I on public.%I',t||'_authenticated_select',t);
  execute format('drop policy if exists %I on public.%I',t||'_authenticated_insert',t);
  execute format('drop policy if exists %I on public.%I',t||'_authenticated_update',t);
  execute format('drop policy if exists %I on public.%I',t||'_active_staff_select',t);
  execute format('create policy %I on public.%I for select to authenticated using (exists (select 1 from public.users u where u.id=auth.uid() and u.status=''active''))',t||'_active_staff_select',t);
 end loop;
end $$;

drop policy if exists pharmacy_products_active_staff_insert on public.pharmacy_products;
create policy pharmacy_products_active_staff_insert on public.pharmacy_products for insert to authenticated with check (
 exists(select 1 from public.users u where u.id=auth.uid() and u.status='active'
 and lower(coalesce(u.role_name,u.role,'')) in ('admin','administrator','owner','manager','stock manager','pharmacist'))
);
drop policy if exists pharmacy_products_active_staff_update on public.pharmacy_products;
create policy pharmacy_products_active_staff_update on public.pharmacy_products for update to authenticated using (
 exists(select 1 from public.users u where u.id=auth.uid() and u.status='active'
 and lower(coalesce(u.role_name,u.role,'')) in ('admin','administrator','owner','manager','stock manager','pharmacist'))
) with check (
 exists(select 1 from public.users u where u.id=auth.uid() and u.status='active'
 and lower(coalesce(u.role_name,u.role,'')) in ('admin','administrator','owner','manager','stock manager','pharmacist'))
);

drop policy if exists pharmacy_batches_active_staff_insert on public.pharmacy_batches;
create policy pharmacy_batches_active_staff_insert on public.pharmacy_batches for insert to authenticated with check (
 exists(select 1 from public.users u where u.id=auth.uid() and u.status='active'
 and lower(coalesce(u.role_name,u.role,'')) in ('admin','administrator','owner','manager','stock manager','pharmacist'))
);
drop policy if exists pharmacy_batches_active_staff_update on public.pharmacy_batches;
create policy pharmacy_batches_active_staff_update on public.pharmacy_batches for update to authenticated using (
 exists(select 1 from public.users u where u.id=auth.uid() and u.status='active'
 and lower(coalesce(u.role_name,u.role,'')) in ('admin','administrator','owner','manager','stock manager','pharmacist'))
) with check (
 exists(select 1 from public.users u where u.id=auth.uid() and u.status='active'
 and lower(coalesce(u.role_name,u.role,'')) in ('admin','administrator','owner','manager','stock manager','pharmacist'))
);

drop policy if exists pharmacy_prescriptions_active_staff_insert on public.pharmacy_prescriptions;
create policy pharmacy_prescriptions_active_staff_insert on public.pharmacy_prescriptions for insert to authenticated with check (
 exists(select 1 from public.users u where u.id=auth.uid() and u.status='active'
 and lower(coalesce(u.role_name,u.role,'')) in ('admin','administrator','owner','manager','pharmacist'))
);
drop policy if exists pharmacy_prescriptions_active_staff_update on public.pharmacy_prescriptions;
create policy pharmacy_prescriptions_active_staff_update on public.pharmacy_prescriptions for update to authenticated using (
 exists(select 1 from public.users u where u.id=auth.uid() and u.status='active'
 and lower(coalesce(u.role_name,u.role,'')) in ('admin','administrator','owner','manager','pharmacist'))
) with check (
 exists(select 1 from public.users u where u.id=auth.uid() and u.status='active'
 and lower(coalesce(u.role_name,u.role,'')) in ('admin','administrator','owner','manager','pharmacist'))
);

drop policy if exists pharmacy_dispensing_active_staff_insert on public.pharmacy_dispensing;
create policy pharmacy_dispensing_active_staff_insert on public.pharmacy_dispensing for insert to authenticated with check (
 exists(select 1 from public.users u where u.id=auth.uid() and u.status='active'
 and lower(coalesce(u.role_name,u.role,'')) in ('admin','administrator','owner','manager','pharmacist','cashier'))
);
drop policy if exists pharmacy_dispensing_active_staff_update on public.pharmacy_dispensing;
create policy pharmacy_dispensing_active_staff_update on public.pharmacy_dispensing for update to authenticated using (
 exists(select 1 from public.users u where u.id=auth.uid() and u.status='active'
 and lower(coalesce(u.role_name,u.role,'')) in ('admin','administrator','owner','manager','pharmacist'))
) with check (
 exists(select 1 from public.users u where u.id=auth.uid() and u.status='active'
 and lower(coalesce(u.role_name,u.role,'')) in ('admin','administrator','owner','manager','pharmacist'))
);

drop policy if exists pharmacy_dispensing_items_active_staff_insert on public.pharmacy_dispensing_items;
create policy pharmacy_dispensing_items_active_staff_insert on public.pharmacy_dispensing_items for insert to authenticated with check (
 exists(select 1 from public.users u where u.id=auth.uid() and u.status='active'
 and lower(coalesce(u.role_name,u.role,'')) in ('admin','administrator','owner','manager','pharmacist','cashier'))
);
drop policy if exists pharmacy_dispensing_items_active_staff_update on public.pharmacy_dispensing_items;
create policy pharmacy_dispensing_items_active_staff_update on public.pharmacy_dispensing_items for update to authenticated using (
 exists(select 1 from public.users u where u.id=auth.uid() and u.status='active'
 and lower(coalesce(u.role_name,u.role,'')) in ('admin','administrator','owner','manager','pharmacist'))
) with check (
 exists(select 1 from public.users u where u.id=auth.uid() and u.status='active'
 and lower(coalesce(u.role_name,u.role,'')) in ('admin','administrator','owner','manager','pharmacist'))
);

drop policy if exists pharmacy_stock_movements_active_staff_insert on public.pharmacy_stock_movements;
create policy pharmacy_stock_movements_active_staff_insert on public.pharmacy_stock_movements for insert to authenticated with check (
 exists(select 1 from public.users u where u.id=auth.uid() and u.status='active'
 and lower(coalesce(u.role_name,u.role,'')) in ('admin','administrator','owner','manager','stock manager','pharmacist'))
);
