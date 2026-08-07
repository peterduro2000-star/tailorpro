create table if not exists public.license_payments (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  reference text unique not null,
  amount real not null,
  currency text not null default 'NGN',
  status text not null check (status in ('pending','success','failed')),
  provider text not null default 'paystack',
  paid_at timestamptz,
  raw_response jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_license_payments_user_id on public.license_payments(user_id);
create index if not exists idx_license_payments_reference on public.license_payments(reference);
create index if not exists idx_license_payments_status on public.license_payments(status);

alter table public.license_payments enable row level security;

drop policy if exists "Users can view their own license payments" on public.license_payments;
create policy "Users can view their own license payments"
on public.license_payments
for select
using (auth.uid() = user_id);

drop policy if exists "Users can insert their own license payments" on public.license_payments;
create policy "Users can insert their own license payments"
on public.license_payments
for insert
with check (auth.uid() = user_id);
