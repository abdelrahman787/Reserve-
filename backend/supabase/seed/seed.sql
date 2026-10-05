-- Sample data for local testing. Run AFTER 0001_init.sql.
-- Safe to re-run: uses fixed UUIDs with ON CONFLICT DO NOTHING.

-- Vendor (warehouse / distributor)
insert into vendors (id, name, description, phone, status) values
  ('11111111-1111-1111-1111-111111111111', 'Nile Pharma Distribution', 'Wholesale pharmaceutical distributor', '+201000000000', 'approved')
on conflict (id) do nothing;

-- Categories
insert into categories (id, name_en, name_ar, sort_order) values
  ('22222222-0000-0000-0000-000000000001', 'Analgesics', 'مسكنات', 1),
  ('22222222-0000-0000-0000-000000000002', 'Antibiotics', 'مضادات حيوية', 2),
  ('22222222-0000-0000-0000-000000000003', 'Vitamins', 'فيتامينات', 3)
on conflict (id) do nothing;

-- Products
insert into products (id, trade_name, generic_name, producer, pharmacology, category_id, requires_rx) values
  ('33333333-0000-0000-0000-000000000001', 'Panadol Extra', 'Paracetamol + Caffeine', 'GSK', 'Analgesic / Antipyretic', '22222222-0000-0000-0000-000000000001', false),
  ('33333333-0000-0000-0000-000000000002', 'Augmentin 1g', 'Amoxicillin + Clavulanic acid', 'GSK', 'Broad-spectrum antibiotic', '22222222-0000-0000-0000-000000000002', true),
  ('33333333-0000-0000-0000-000000000003', 'Cevamin', 'Vitamin C 1000mg', 'Pharco', 'Vitamin supplement', '22222222-0000-0000-0000-000000000003', false)
on conflict (id) do nothing;

-- Vendor offers (price + stock)
insert into vendor_products (vendor_id, product_id, price, discount_percent, stock_qty) values
  ('11111111-1111-1111-1111-111111111111', '33333333-0000-0000-0000-000000000001', 28.50, 5, 500),
  ('11111111-1111-1111-1111-111111111111', '33333333-0000-0000-0000-000000000002', 95.00, 0, 120),
  ('11111111-1111-1111-1111-111111111111', '33333333-0000-0000-0000-000000000003', 42.00, 10, 300)
on conflict (vendor_id, product_id) do nothing;
