# Pharma Pharmacy POS

**Brand:** Pharma Pharmacy  
**Visual identity:** Clinical teal, healthcare blue, clean white surfaces and navy navigation.  
**Repository:** https://github.com/Matokaaa1/pharma  
**Supabase project:** `ghizmgybhpmmyfrlqohq`

## Included

- `index.html` — rebranded POS interface with pharmacy-oriented navigation, teal/blue styling and target Supabase URL configured.
- `pharmacy_pos_schema.sql` — additional pharmacy tables for medicine products, batches/expiry dates, prescriptions, dispensing records and stock movements.
- `.env.example` — public configuration template.
- `.gitignore` — ignores local environment files.

## Before running

1. In `index.html`, replace `REPLACE_WITH_PHARMA_SUPABASE_PUBLISHABLE_OR_ANON_KEY` with the target project's publishable key (or legacy anon key) from Supabase Project Settings → API Keys. Never expose a service-role/secret key in browser code.
2. Review `pharmacy_pos_schema.sql` and run it in the target project's SQL Editor: https://supabase.com/dashboard/project/ghizmgybhpmmyfrlqohq/sql/new
3. Sign in and add verified medicine catalogue items, prices, batch numbers, expiry dates and opening stock. The app no longer seeds fictional fashion products or made-up medicines by default.
4. Test product creation, checkout, stock changes, receipts, reports and user permissions against the target database before live use.

## Important status

The GitHub source has been rebranded, but this upload is not a claim that the POS is production-ready. The original retail codebase still requires a complete pharmacy workflow integration and testing. The pharmacy schema has **not** been applied to Supabase by this upload. Existing data has not been migrated. Existing product image URLs may still reference the old public storage bucket. Dispensing needs server-side transactional stock deduction (including batch/expiry handling), and RLS policies must be narrowed to staff roles and store/branch access before production.
