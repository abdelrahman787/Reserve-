-- Storage bucket for product images (public read; vendor/admin write).
insert into storage.buckets (id, name, public)
values ('product-images', 'product-images', true)
on conflict (id) do nothing;

create policy "product_images_public_read" on storage.objects
  for select using (bucket_id = 'product-images');

create policy "product_images_staff_insert" on storage.objects
  for insert to authenticated
  with check (
    bucket_id = 'product-images'
    and (public.current_role_is('vendor') or public.current_role_is('admin'))
  );

create policy "product_images_staff_update" on storage.objects
  for update to authenticated
  using (
    bucket_id = 'product-images'
    and (public.current_role_is('vendor') or public.current_role_is('admin'))
  );

create policy "product_images_staff_delete" on storage.objects
  for delete to authenticated
  using (
    bucket_id = 'product-images'
    and (public.current_role_is('vendor') or public.current_role_is('admin'))
  );
