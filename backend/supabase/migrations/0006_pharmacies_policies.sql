-- RLS policies for `pharmacies` (the table had RLS enabled but no policies,
-- which blocked registration — the pharmacy row insert during sign-up).

-- Any authenticated user may create a pharmacy (done during registration,
-- before the profile is linked to it).
create policy pharmacies_insert on pharmacies for insert
  with check (auth.uid() is not null);

-- A pharmacy sees its own row; vendors and admins can see pharmacies
-- (needed to service orders).
create policy pharmacies_select on pharmacies for select
  using (
    id = current_pharmacy_id()
    or current_role_is('vendor')
    or current_role_is('admin')
  );

-- A pharmacy updates its own row.
create policy pharmacies_update on pharmacies for update
  using (id = current_pharmacy_id())
  with check (id = current_pharmacy_id());
