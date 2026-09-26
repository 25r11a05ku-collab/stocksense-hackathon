-- StockSense inventory schema for Supabase
-- Run this once in your Supabase project: SQL Editor → New query → paste → Run

create table if not exists products (
  sku     text primary key,
  name    text not null,
  cat     text,
  unit    text,
  reorder int  default 0,
  stock   jsonb default '{}'::jsonb   -- e.g. {"Main Warehouse": 450, "Warehouse 1": 0}
);

create table if not exists ledger (
  id      bigint primary key,
  date    text,
  doc     text,
  type    text,
  product text,
  loc     text,
  change  int,
  balance int
);

create table if not exists receipts (
  doc      text primary key,
  supplier text,
  product  text,
  wh       text,
  qty      int,
  status   text
);

create table if not exists deliveries (
  doc      text primary key,
  customer text,
  product  text,
  wh       text,
  qty      int,
  status   text
);

create table if not exists transfers (
  doc     text primary key,
  product text,
  "from"  text,
  "to"    text,
  qty     int,
  status  text
);

create table if not exists adjustments (
  doc     text primary key,
  product text,
  loc     text,
  diff    int,
  reason  text
);

-- ---------------------------------------------------------------------------
-- REAL BACKEND MODE: Row Level Security is ON. The browser's anon key can only
-- SELECT (read). It cannot insert, update, or delete anything directly.
-- All writes — receipts, deliveries, transfers, adjustments, product edits,
-- deletes — go through the "stocksense-api" Edge Function, which runs with
-- the service role key on Supabase's servers. That function is the backend:
-- it validates stock levels, computes the ledger, and checks the admin PIN
-- server-side before any delete. The browser never gets write access.
-- ---------------------------------------------------------------------------
alter table products    enable row level security;
alter table ledger      enable row level security;
alter table receipts    enable row level security;
alter table deliveries  enable row level security;
alter table transfers   enable row level security;
alter table adjustments enable row level security;

create policy "Public read - products"    on products    for select using (true);
create policy "Public read - ledger"      on ledger      for select using (true);
create policy "Public read - receipts"    on receipts    for select using (true);
create policy "Public read - deliveries"  on deliveries  for select using (true);
create policy "Public read - transfers"   on transfers   for select using (true);
create policy "Public read - adjustments" on adjustments for select using (true);

-- No insert/update/delete policies are defined for any table on purpose —
-- that means the anon key is refused for all writes by default, and only the
-- service role (used inside the Edge Function, never in the browser) can write.

-- Seed data, so the app has something to show as soon as you connect it.
insert into products (sku,name,cat,unit,reorder,stock) values
  ('STL-001','Steel Rod','Raw Materials','kg',50, '{"Main Warehouse":450,"Production Floor":150,"Warehouse 1":0,"Warehouse 2":0}'),
  ('STL-002','Steel Sheet','Raw Materials','kg',80, '{"Main Warehouse":220,"Production Floor":0,"Warehouse 1":0,"Warehouse 2":0}'),
  ('CHR-001','Chair','Furniture','pcs',30, '{"Main Warehouse":0,"Production Floor":0,"Warehouse 1":25,"Warehouse 2":0}'),
  ('TBL-001','Table','Furniture','pcs',15, '{"Main Warehouse":0,"Production Floor":0,"Warehouse 1":18,"Warehouse 2":0}'),
  ('LAP-001','Laptop Model X','Electronics','pcs',10, '{"Main Warehouse":0,"Production Floor":0,"Warehouse 1":0,"Warehouse 2":4}'),
  ('PKG-001','Corrugated Box','Packaging','box',200, '{"Main Warehouse":0,"Production Floor":0,"Warehouse 1":0,"Warehouse 2":90}')
on conflict (sku) do nothing;
