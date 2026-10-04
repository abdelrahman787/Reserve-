-- Auto-create a wallet for every new pharmacy.
create or replace function handle_new_pharmacy()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into wallets (pharmacy_id) values (new.id)
  on conflict (pharmacy_id) do nothing;
  return new;
end $$;

drop trigger if exists on_pharmacy_created on pharmacies;
create trigger on_pharmacy_created
  after insert on pharmacies
  for each row execute function handle_new_pharmacy();

-- Backfill wallets for any pharmacies created before this trigger existed.
insert into wallets (pharmacy_id)
select p.id from pharmacies p
left join wallets w on w.pharmacy_id = p.id
where w.id is null;

-- Let a vendor manage its own promos (admins already can via promos_admin_write).
create policy promos_vendor_write on promos for all
  using (vendor_id = current_vendor_id() or current_role_is('admin'))
  with check (vendor_id = current_vendor_id() or current_role_is('admin'));
