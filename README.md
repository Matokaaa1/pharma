# Retail & Pharmacy POS — Supabase setup

Target Supabase project: `ghizmgybhpmmyfrlqohq`  
Target repository: https://github.com/Matokaaa1/pharma

## Current setup

- `index.html` is the existing retail POS source baseline, updated to point its Supabase client at the target project.
- `pharmacy_pos_schema.sql` adds pharmacy-specific product, batch, prescription, dispensing, dispensing-item, and stock-movement tables.
- `.env.example` documents the public browser configuration.
- The existing retail UI/schema still needs a full integration test against the target project. This commit does not mean the app is production-ready.

## Configure Supabase safely

In `index.html`, replace `REPLACE_WITH_PHARMA_SUPABASE_PUBLISHABLE_OR_ANON_KEY` with the project's **publishable key** (or legacy anon key). Find it under Supabase Project Settings → API Keys. Never put a service-role/secret key in browser code.

## Database migration

Review `pharmacy_pos_schema.sql`, then run it in the target project's SQL Editor:
https://supabase.com/dashboard/project/ghizmgybhpmmyfrlqohq/sql/new

The migration creates pharmacy-specific tables and does not drop existing tables. It enables RLS with a basic authenticated-user single-store policy; replace this with staff-role and branch-scoped policies before production.

## Important limitations

- No SQL has been applied to Supabase by this GitHub upload.
- No retail records are migrated from the original Supabase project.
- Existing retail product-image URLs still point to their original public storage bucket.
- Pharmacy dispensing should be moved to a server-side transaction/RPC with FEFO stock deduction and role validation before live dispensing.
