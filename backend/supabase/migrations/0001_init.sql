-- PharmaReserve — initial schema
-- B2B pharmacy ordering platform (pharmacies buy from warehouses/vendors).
-- Target: Supabase (PostgreSQL 15+). Apply with the Supabase CLI or SQL editor.

-- ---------------------------------------------------------------------------
-- Extensions
-- ---------------------------------------------------------------------------
create extension if not exists "pgcrypto";      -- gen_random_uuid()

-- ---------------------------------------------------------------------------
-- Enums
-- ---------------------------------------------------------------------------
do $$ begin
  create type user_role as enum ('pharmacy', 'vendor', 'admin');
exception when duplicate_object then null; end $$;

do $$ begin
  create type account_status as enum ('pending', 'approved', 'suspended', 'rejected');
exception when duplicate_object then null; end $$;

do $$ begin
  create type order_status as enum (
    'pending', 'confirmed', 'processing', 'out_for_delivery', 'delivered', 'cancelled'
  );
exception when duplicate_object then null; end $$;

do $$ begin
  create type discount_type as enum ('percent', 'fixed');
exception when duplicate_object then null; end $$;

do $$ begin
  create type wallet_txn_type as enum ('credit', 'debit');
exception when duplicate_object then null; end $$;

-- ---------------------------------------------------------------------------
-- updated_at helper
-- ---------------------------------------------------------------------------
create or replace function set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end $$;

-- ---------------------------------------------------------------------------
-- Vendors (warehouses / distributors) — the selling side
-- ---------------------------------------------------------------------------
create table if not exists vendors (
  id            uuid primary key default gen_random_uuid(),
  name          text not null,
  logo_url      text,
  description   text,
  phone         text,
  status        account_status not null default 'approved',
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);
create trigger trg_vendors_updated before update on vendors
  for each row execute function set_updated_at();

-- ---------------------------------------------------------------------------
-- Pharmacies (buyer accounts)
-- ---------------------------------------------------------------------------
create table if not exists pharmacies (
  id              uuid primary key default gen_random_uuid(),
  name            text not null,
  license_number  text,
  phone           text,
  email           text,
  address         text,
  lat             double precision,
  lng             double precision,
  status          account_status not null default 'pending',
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);
create trigger trg_pharmacies_updated before update on pharmacies
  for each row execute function set_updated_at();

-- ---------------------------------------------------------------------------
-- Profiles — links an auth user to a role and (optionally) a pharmacy/vendor
-- ---------------------------------------------------------------------------
create table if not exists profiles (
  id          uuid primary key references auth.users(id) on delete cascade,
  role        user_role not null default 'pharmacy',
  full_name   text,
  phone       text,
  pharmacy_id uuid references pharmacies(id) on delete set null,
  vendor_id   uuid references vendors(id) on delete set null,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);
create trigger trg_profiles_updated before update on profiles
  for each row execute function set_updated_at();

-- Auto-create a profile row when a new auth user signs up.
create or replace function handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, full_name, phone)
  values (new.id, new.raw_user_meta_data->>'full_name', new.raw_user_meta_data->>'phone')
  on conflict (id) do nothing;
  return new;
end $$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function handle_new_user();

-- Helper: current user's role / pharmacy / vendor (used by RLS).
create or replace function current_role_is(target user_role)
returns boolean language sql stable as $$
  select exists (select 1 from profiles p where p.id = auth.uid() and p.role = target);
$$;

create or replace function current_pharmacy_id()
returns uuid language sql stable as $$
  select pharmacy_id from profiles where id = auth.uid();
$$;

create or replace function current_vendor_id()
returns uuid language sql stable as $$
  select vendor_id from profiles where id = auth.uid();
$$;

-- ---------------------------------------------------------------------------
-- Categories (drug categories; self-referencing for sub-categories)
-- ---------------------------------------------------------------------------
create table if not exists categories (
  id          uuid primary key default gen_random_uuid(),
  name_en     text not null,
  name_ar     text not null,
  parent_id   uuid references categories(id) on delete set null,
  icon_url    text,
  sort_order  int not null default 0,
  created_at  timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- Products (shared drug catalog)
-- ---------------------------------------------------------------------------
create table if not exists products (
  id            uuid primary key default gen_random_uuid(),
  trade_name    text not null,
  generic_name  text,
  pharmacology  text,
  producer      text,            -- manufacturer / company
  description   text,
  indications   text,
  dosage        text,
  category_id   uuid references categories(id) on delete set null,
  image_url     text,
  barcode       text,
  requires_rx   boolean not null default false,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);
create trigger trg_products_updated before update on products
  for each row execute function set_updated_at();

-- Full-text-ish search helpers
create index if not exists idx_products_trade_name on products using gin (to_tsvector('simple', coalesce(trade_name,'')));
create index if not exists idx_products_generic_name on products using gin (to_tsvector('simple', coalesce(generic_name,'')));
create index if not exists idx_products_category on products(category_id);

-- ---------------------------------------------------------------------------
-- Vendor products (per-vendor price + stock — the B2B "offers from distributors")
-- ---------------------------------------------------------------------------
create table if not exists vendor_products (
  id                uuid primary key default gen_random_uuid(),
  vendor_id         uuid not null references vendors(id) on delete cascade,
  product_id        uuid not null references products(id) on delete cascade,
  price             numeric(12,2) not null check (price >= 0),
  discount_percent  numeric(5,2) not null default 0 check (discount_percent between 0 and 100),
  stock_qty         int not null default 0 check (stock_qty >= 0),
  max_per_order     int,
  is_available      boolean not null default true,
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now(),
  unique (vendor_id, product_id)
);
create trigger trg_vendor_products_updated before update on vendor_products
  for each row execute function set_updated_at();
create index if not exists idx_vendor_products_product on vendor_products(product_id);
create index if not exists idx_vendor_products_vendor on vendor_products(vendor_id);

-- ---------------------------------------------------------------------------
-- Cart (one active cart per pharmacy; items reference a vendor_product)
-- ---------------------------------------------------------------------------
create table if not exists carts (
  id           uuid primary key default gen_random_uuid(),
  pharmacy_id  uuid not null references pharmacies(id) on delete cascade,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now(),
  unique (pharmacy_id)
);
create trigger trg_carts_updated before update on carts
  for each row execute function set_updated_at();

create table if not exists cart_items (
  id                uuid primary key default gen_random_uuid(),
  cart_id           uuid not null references carts(id) on delete cascade,
  vendor_product_id uuid not null references vendor_products(id) on delete cascade,
  quantity          int not null check (quantity > 0),
  created_at        timestamptz not null default now(),
  unique (cart_id, vendor_product_id)
);

-- ---------------------------------------------------------------------------
-- Promotions
-- ---------------------------------------------------------------------------
create table if not exists promos (
  id              uuid primary key default gen_random_uuid(),
  code            text not null unique,
  description     text,
  d_type          discount_type not null default 'percent',
  d_value         numeric(12,2) not null check (d_value >= 0),
  min_order       numeric(12,2) not null default 0,
  vendor_id       uuid references vendors(id) on delete cascade, -- null = platform-wide
  valid_from      timestamptz,
  valid_to        timestamptz,
  is_active       boolean not null default true,
  created_at      timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- Orders (per vendor) + items (price snapshots)
-- ---------------------------------------------------------------------------
create table if not exists orders (
  id            uuid primary key default gen_random_uuid(),
  pharmacy_id   uuid not null references pharmacies(id) on delete restrict,
  vendor_id     uuid not null references vendors(id) on delete restrict,
  status        order_status not null default 'pending',
  subtotal      numeric(12,2) not null default 0,
  discount      numeric(12,2) not null default 0,
  delivery_fee  numeric(12,2) not null default 0,
  total         numeric(12,2) not null default 0,
  promo_code    text,
  note          text,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now(),
  delivered_at  timestamptz
);
create trigger trg_orders_updated before update on orders
  for each row execute function set_updated_at();
create index if not exists idx_orders_pharmacy on orders(pharmacy_id);
create index if not exists idx_orders_vendor on orders(vendor_id);

create table if not exists order_items (
  id                uuid primary key default gen_random_uuid(),
  order_id          uuid not null references orders(id) on delete cascade,
  vendor_product_id uuid references vendor_products(id) on delete set null,
  product_name      text not null,      -- snapshot
  unit_price        numeric(12,2) not null,
  quantity          int not null check (quantity > 0),
  line_total        numeric(12,2) not null
);
create index if not exists idx_order_items_order on order_items(order_id);

-- ---------------------------------------------------------------------------
-- Wallet
-- ---------------------------------------------------------------------------
create table if not exists wallets (
  id           uuid primary key default gen_random_uuid(),
  pharmacy_id  uuid not null references pharmacies(id) on delete cascade,
  balance      numeric(12,2) not null default 0,
  currency     text not null default 'EGP',
  created_at   timestamptz not null default now(),
  unique (pharmacy_id)
);

create table if not exists wallet_transactions (
  id          uuid primary key default gen_random_uuid(),
  wallet_id   uuid not null references wallets(id) on delete cascade,
  amount      numeric(12,2) not null,
  txn_type    wallet_txn_type not null,
  reason      text,
  order_id    uuid references orders(id) on delete set null,
  created_at  timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- Favorite suppliers
-- ---------------------------------------------------------------------------
create table if not exists favorite_vendors (
  pharmacy_id uuid not null references pharmacies(id) on delete cascade,
  vendor_id   uuid not null references vendors(id) on delete cascade,
  created_at  timestamptz not null default now(),
  primary key (pharmacy_id, vendor_id)
);

-- ---------------------------------------------------------------------------
-- Row Level Security
-- ---------------------------------------------------------------------------
alter table profiles            enable row level security;
alter table pharmacies          enable row level security;
alter table vendors             enable row level security;
alter table categories          enable row level security;
alter table products            enable row level security;
alter table vendor_products     enable row level security;
alter table carts               enable row level security;
alter table cart_items          enable row level security;
alter table promos              enable row level security;
alter table orders              enable row level security;
alter table order_items         enable row level security;
alter table wallets             enable row level security;
alter table wallet_transactions enable row level security;
alter table favorite_vendors    enable row level security;

-- Profiles: a user sees/edits their own profile; admins see all.
create policy profiles_self_select on profiles for select
  using (id = auth.uid() or current_role_is('admin'));
create policy profiles_self_update on profiles for update
  using (id = auth.uid());

-- Catalog is readable by any authenticated user; writable by admins/vendors.
create policy categories_read on categories for select using (auth.role() = 'authenticated');
create policy products_read   on products   for select using (auth.role() = 'authenticated');
create policy vendors_read    on vendors    for select using (auth.role() = 'authenticated');

create policy categories_admin_write on categories for all
  using (current_role_is('admin')) with check (current_role_is('admin'));
create policy products_admin_write on products for all
  using (current_role_is('admin')) with check (current_role_is('admin'));

-- Vendor products: readable by all authed users; a vendor manages its own; admin all.
create policy vendor_products_read on vendor_products for select using (auth.role() = 'authenticated');
create policy vendor_products_vendor_write on vendor_products for all
  using (vendor_id = current_vendor_id() or current_role_is('admin'))
  with check (vendor_id = current_vendor_id() or current_role_is('admin'));

-- Promotions readable by all authed; admin writes.
create policy promos_read on promos for select using (auth.role() = 'authenticated');
create policy promos_admin_write on promos for all
  using (current_role_is('admin')) with check (current_role_is('admin'));

-- Cart: a pharmacy only touches its own cart + items.
create policy carts_owner on carts for all
  using (pharmacy_id = current_pharmacy_id())
  with check (pharmacy_id = current_pharmacy_id());
create policy cart_items_owner on cart_items for all
  using (exists (select 1 from carts c where c.id = cart_items.cart_id and c.pharmacy_id = current_pharmacy_id()))
  with check (exists (select 1 from carts c where c.id = cart_items.cart_id and c.pharmacy_id = current_pharmacy_id()));

-- Orders: pharmacy sees its own; vendor sees orders placed to it; admin all.
create policy orders_select on orders for select
  using (pharmacy_id = current_pharmacy_id() or vendor_id = current_vendor_id() or current_role_is('admin'));
create policy orders_pharmacy_insert on orders for insert
  with check (pharmacy_id = current_pharmacy_id());
create policy orders_vendor_update on orders for update
  using (vendor_id = current_vendor_id() or current_role_is('admin'));

create policy order_items_select on order_items for select
  using (exists (select 1 from orders o where o.id = order_items.order_id
                 and (o.pharmacy_id = current_pharmacy_id() or o.vendor_id = current_vendor_id() or current_role_is('admin'))));
create policy order_items_insert on order_items for insert
  with check (exists (select 1 from orders o where o.id = order_items.order_id and o.pharmacy_id = current_pharmacy_id()));

-- Wallet: pharmacy sees its own wallet + transactions.
create policy wallets_owner on wallets for select
  using (pharmacy_id = current_pharmacy_id() or current_role_is('admin'));
create policy wallet_txn_owner on wallet_transactions for select
  using (exists (select 1 from wallets w where w.id = wallet_transactions.wallet_id
                 and (w.pharmacy_id = current_pharmacy_id() or current_role_is('admin'))));

-- Favorites: pharmacy manages its own.
create policy favorites_owner on favorite_vendors for all
  using (pharmacy_id = current_pharmacy_id())
  with check (pharmacy_id = current_pharmacy_id());
