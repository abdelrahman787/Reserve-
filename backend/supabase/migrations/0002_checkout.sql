-- Checkout: atomically turn the caller's cart into one order per vendor.
-- SECURITY DEFINER so it can write across tables; it resolves the pharmacy
-- from auth.uid(), so a caller can only ever check out their own cart.

create or replace function checkout(p_note text default null, p_promo_code text default null)
returns setof uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_pharmacy uuid;
  v_cart     uuid;
  v_vendor   uuid;
  v_order    uuid;
  v_subtotal numeric(12,2);
  v_discount numeric(12,2);
  v_promo    promos%rowtype;
begin
  select pharmacy_id into v_pharmacy from profiles where id = auth.uid();
  if v_pharmacy is null then
    raise exception 'No pharmacy linked to the current user';
  end if;

  select id into v_cart from carts where pharmacy_id = v_pharmacy;
  if v_cart is null then
    raise exception 'Cart is empty';
  end if;

  if not exists (select 1 from cart_items where cart_id = v_cart) then
    raise exception 'Cart is empty';
  end if;

  -- Optional promo lookup (validity window + active flag).
  if p_promo_code is not null and length(trim(p_promo_code)) > 0 then
    select * into v_promo from promos
     where code = p_promo_code
       and is_active
       and (valid_from is null or valid_from <= now())
       and (valid_to   is null or valid_to   >= now())
     limit 1;
  end if;

  -- One order per distinct vendor in the cart.
  for v_vendor in
    select distinct vp.vendor_id
      from cart_items ci
      join vendor_products vp on vp.id = ci.vendor_product_id
     where ci.cart_id = v_cart
  loop
    select coalesce(sum(vp.price * (1 - vp.discount_percent / 100) * ci.quantity), 0)
      into v_subtotal
      from cart_items ci
      join vendor_products vp on vp.id = ci.vendor_product_id
     where ci.cart_id = v_cart and vp.vendor_id = v_vendor;

    v_discount := 0;
    if v_promo.id is not null
       and (v_promo.vendor_id is null or v_promo.vendor_id = v_vendor)
       and v_subtotal >= v_promo.min_order then
      if v_promo.d_type = 'percent' then
        v_discount := round(v_subtotal * v_promo.d_value / 100, 2);
      else
        v_discount := least(v_promo.d_value, v_subtotal);
      end if;
    end if;

    insert into orders (pharmacy_id, vendor_id, status, subtotal, discount,
                        delivery_fee, total, promo_code, note)
    values (v_pharmacy, v_vendor, 'pending', v_subtotal, v_discount, 0,
            v_subtotal - v_discount,
            case when v_discount > 0 then p_promo_code else null end, p_note)
    returning id into v_order;

    insert into order_items (order_id, vendor_product_id, product_name,
                            unit_price, quantity, line_total)
    select v_order,
           ci.vendor_product_id,
           p.trade_name,
           round(vp.price * (1 - vp.discount_percent / 100), 2),
           ci.quantity,
           round(vp.price * (1 - vp.discount_percent / 100) * ci.quantity, 2)
      from cart_items ci
      join vendor_products vp on vp.id = ci.vendor_product_id
      join products p         on p.id = vp.product_id
     where ci.cart_id = v_cart and vp.vendor_id = v_vendor;

    return next v_order;
  end loop;

  delete from cart_items where cart_id = v_cart;
  return;
end $$;

grant execute on function checkout(text, text) to authenticated;
