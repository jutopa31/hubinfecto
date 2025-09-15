-- HubInfecto - PostgreSQL Extensions Setup
-- Extensions required for HubInfecto medical system
-- Run this FIRST before running any other scripts

-- =====================================================
-- ENABLE REQUIRED EXTENSIONS
-- =====================================================

-- UUID generation (required for primary keys)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Cryptographic functions (required for security)
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Trigram matching for fuzzy text search (optional but recommended)
-- Note: This extension might not be available on all Supabase plans
DO $$
BEGIN
    CREATE EXTENSION IF NOT EXISTS "pg_trgm";
    RAISE NOTICE 'pg_trgm extension enabled successfully - fuzzy search will be available';
EXCEPTION
    WHEN others THEN
        RAISE NOTICE 'pg_trgm extension not available - will use fallback text search';
        RAISE NOTICE 'This is normal on some Supabase plans and will not affect functionality';
END $$;

-- =====================================================
-- VERIFY EXTENSIONS
-- =====================================================

-- Function to check extension status
CREATE OR REPLACE FUNCTION check_extensions()
RETURNS TABLE (
    extension_name TEXT,
    is_installed BOOLEAN,
    description TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        ext.name,
        ext.installed,
        ext.description
    FROM (
        VALUES
            ('uuid-ossp', EXISTS(SELECT 1 FROM pg_extension WHERE extname = 'uuid-ossp'), 'UUID generation functions'),
            ('pgcrypto', EXISTS(SELECT 1 FROM pg_extension WHERE extname = 'pgcrypto'), 'Cryptographic functions'),
            ('pg_trgm', EXISTS(SELECT 1 FROM pg_extension WHERE extname = 'pg_trgm'), 'Trigram matching for fuzzy search')
    ) AS ext(name, installed, description);
END;
$$ LANGUAGE plpgsql;

-- Show extension status
SELECT
    extension_name,
    CASE
        WHEN is_installed THEN '✅ Installed'
        ELSE '❌ Not Available'
    END as status,
    description
FROM check_extensions()
ORDER BY is_installed DESC, extension_name;

-- =====================================================
-- EXTENSION-SPECIFIC NOTES
-- =====================================================

/*
EXTENSION NOTES:

1. uuid-ossp (REQUIRED)
   - Provides uuid_generate_v4() function
   - Required for all primary keys
   - Should be available on all PostgreSQL installations

2. pgcrypto (REQUIRED)
   - Provides cryptographic functions
   - Used for password hashing and data encryption
   - Required for security features

3. pg_trgm (OPTIONAL)
   - Enables fuzzy text search with similarity() function
   - Improves patient search functionality
   - May not be available on all Supabase plans
   - Fallback search functions are provided if unavailable

TROUBLESHOOTING:

If extensions fail to install:
1. Check your Supabase plan - some extensions require higher tiers
2. Contact Supabase support if needed extensions are missing
3. The system will work with fallback functions if pg_trgm is unavailable
4. uuid-ossp and pgcrypto are typically available on all plans

MANUAL INSTALLATION:

If running on your own PostgreSQL instance:
```sql
-- As superuser
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";
```
*/