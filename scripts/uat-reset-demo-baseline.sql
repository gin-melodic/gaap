-- Reset the online demo user's immutable baseline so the API (with the full
-- seeded chart of accounts) can re-capture the baseline and regenerate demo
-- transactions for every historical business date.
--
-- Apply:
--   docker exec -i gaap-uat-postgres-1 psql -U gaap_uat -d gaap_uat \
--     < scripts/uat-reset-demo-baseline.sql
-- Then restart the API:
--   docker compose -f docker-compose.uat.yml restart gaap-api
--
-- Verify after restart:
--   docker exec gaap-uat-postgres-1 psql -U gaap_uat -d gaap_uat -c \
--     "SELECT count(*) FROM transactions WHERE user_id=(SELECT id FROM users WHERE email='gaap_test_feedback@ginmel.ai');"

BEGIN;

DELETE FROM demo_data_generation_runs
WHERE user_id = (SELECT id FROM users WHERE email = 'gaap_test_feedback@ginmel.ai');

DELETE FROM demo_user_baselines
WHERE user_id = (SELECT id FROM users WHERE email = 'gaap_test_feedback@ginmel.ai');

COMMIT;
