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
do $$
declare t text;
begin
 foreach t in array array['pharmacy_products','pharmacy_batches','pharmacy_prescriptions','pharmacy_dispensing','pharmacy_dispensing_items','pharmacy_stock_movements'] loop
  execute format('alter table public.%I enable row level security',t);
  execute format('drop policy if exists %I on public.%I',t||'_authenticated_select',t);
  execute format('create policy %I on public.%I for select to authenticated using (true)',t||'_authenticated_select',t);
  execute format('drop policy if exists %I on public.%I',t||'_authenticated_insert',t);
  execute format('create policy %I on public.%I for insert to authenticated with check (true)',t||'_authenticated_insert',t);
  execute format('drop policy if exists %I on public.%I',t||'_authenticated_update',t);
  execute format('create policy %I on public.%I for update to authenticated using (true) with check (true)',t||'_authenticated_update',t);
 end loop;
end $$;
-- No DELETE policy. Replace broad single-store policies with role/branch-scoped policies before production.
