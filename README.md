# Pharma Pharmacy POS

**Brand:** Pharma Pharmacy  
**Visual identity:** Clinical teal, healthcare blue, clean white surfaces and navy navigation.  
**Repository:** https://github.com/Matokaaa1/pharma  
**Supabase project:** `ghizmgybhpmmyfrlqohq`

## Current setup

- `index.html` — pharmacy-branded POS UI, Supabase connection, email/password sign-in, Supabase-session validation, and password-reset request.
- `pharmacy_pos_schema.sql` — pharmacy products, batches/expiry, prescriptions, dispensing, stock movements, role/profile setup, and active-staff RLS policies.
- `README.md` — setup and operational status.

## Login

1. Open the deployed site and use **Email Login**.
2. The existing Supabase Auth account is `admin@pharma.co.ke`. A profile exists for this account with the Administrator role.
3. The password is not displayed or stored in this repository. If you do not know it, enter `admin@pharma.co.ke` and choose **Forgot password? Send reset email**.
4. If the reset email does not arrive, check Supabase **Authentication → URL Configuration** and email-provider settings. Ensure the deployed site URL is in the redirect allowlist.
5. PIN login is disabled in the browser until it can be implemented with secure server-side verification. Do not use a hard-coded PIN.

Never put a Supabase service-role/secret key in browser code. The public anon/publishable key is designed for client use only when RLS policies are configured correctly.

## Database status

The Supabase project is active. The following were applied through additive migrations:
- Pharmacy-specific tables and active-staff row-level security.
- `public.users` and `public.roles`, with a profile linked to the existing confirmed `admin@pharma.co.ke` Auth account.
- Compatibility tables used by the current POS UI: `products`, `orders`, `customers`, `audit_logs`, `store_settings`, `delivery_rates`, `delivery_zones`, `product_images`, and `site_settings`.
- Session restoration now checks the live Supabase Auth session and active user profile instead of trusting localStorage alone.

These changes did not drop tables or truncate business data. Pharmacy product, batch, prescription, dispensing, and stock-movement tables are currently empty; add real, verified catalogue and inventory data before use.

## Production readiness

This is **not yet certified production-ready**. The inherited retail interface still has workflows that need end-to-end testing and full pharmacy-specific integration. In particular, dispensing must use a server-side database transaction that validates prescriptions where required and deducts stock by earliest-expiry-first (FEFO), with no overselling. Review RLS role boundaries, storage bucket permissions, receipt/payment reconciliation, and backups before live pharmacy operations. Do not treat a successful login as proof that every POS workflow is complete.
