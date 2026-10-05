-- Wallet funding (admin) and paying an order from the pharmacy's wallet.

-- Credit a pharmacy wallet. Admin only (top-up / refund).
create or replace function credit_wallet(
  p_pharmacy_id uuid, p_amount numeric, p_reason text default null)
returns numeric
language plpgsql security definer set search_path = public
as $$
declare v_wallet uuid; v_balance numeric;
begin
  if not current_role_is('admin') then
    raise exception 'Only admins can credit wallets';
  end if;
  if p_amount <= 0 then raise exception 'Amount must be positive'; end if;

  select id into v_wallet from wallets where pharmacy_id = p_pharmacy_id;
  if v_wallet is null then
    insert into wallets (pharmacy_id) values (p_pharmacy_id) returning id into v_wallet;
  end if;
  update wallets set balance = balance + p_amount
    where id = v_wallet returning balance into v_balance;
  insert into wallet_transactions (wallet_id, amount, txn_type, reason)
    values (v_wallet, p_amount, 'credit', coalesce(p_reason, 'Top-up'));
  return v_balance;
end $$;
grant execute on function credit_wallet(uuid, numeric, text) to authenticated;

-- Pay a pending order from the caller's wallet (atomic debit + confirm).
create or replace function pay_order_from_wallet(p_order_id uuid)
returns numeric
language plpgsql security definer set search_path = public
as $$
declare
  v_pharmacy uuid; v_wallet uuid; v_balance numeric;
  v_total numeric; v_status order_status;
begin
  select pharmacy_id into v_pharmacy from profiles where id = auth.uid();
  if v_pharmacy is null then raise exception 'No pharmacy for user'; end if;

  select total, status into v_total, v_status
    from orders where id = p_order_id and pharmacy_id = v_pharmacy;
  if v_total is null then raise exception 'Order not found'; end if;
  if v_status <> 'pending' then raise exception 'Order is not payable'; end if;

  select id, balance into v_wallet, v_balance
    from wallets where pharmacy_id = v_pharmacy;
  if v_wallet is null or v_balance < v_total then
    raise exception 'Insufficient wallet balance';
  end if;

  update wallets set balance = balance - v_total
    where id = v_wallet returning balance into v_balance;
  insert into wallet_transactions (wallet_id, amount, txn_type, reason, order_id)
    values (v_wallet, v_total, 'debit', 'Order payment', p_order_id);
  update orders set status = 'confirmed' where id = p_order_id;
  return v_balance;
end $$;
grant execute on function pay_order_from_wallet(uuid) to authenticated;
