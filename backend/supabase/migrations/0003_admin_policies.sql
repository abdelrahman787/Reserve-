-- Let warehouse staff (vendor role) add catalog products, not only admins.
-- Updates/deletes to shared products stay admin-only (products_admin_write).

create policy products_vendor_insert on products for insert
  with check (current_role_is('vendor') or current_role_is('admin'));
