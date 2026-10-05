-- Device push tokens (FCM) per user, for sending push notifications.
create table if not exists device_tokens (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references auth.users(id) on delete cascade,
  token      text not null unique,
  platform   text,                       -- android | ios | web
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists idx_device_tokens_user on device_tokens(user_id);

create trigger trg_device_tokens_updated before update on device_tokens
  for each row execute function set_updated_at();

alter table device_tokens enable row level security;

-- A user manages only their own tokens.
create policy device_tokens_owner on device_tokens for all
  using (user_id = auth.uid())
  with check (user_id = auth.uid());
