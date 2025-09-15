# HubInfecto - Supabase Database Setup Instructions

## 📋 Overview

This guide will help you set up the complete Supabase database architecture for HubInfecto, including all tables, functions, policies, and sample data needed for the medical management system.

## 🚀 Quick Setup (Recommended)

### Option 1: One-Script Setup (Easiest)

1. **Create a new Supabase project**
   - Go to [supabase.com](https://supabase.com)
   - Create a new project
   - Wait for the project to be fully initialized

2. **Run the quick setup script**
   - Go to SQL Editor in your Supabase dashboard
   - Copy and paste the entire content of `quick-setup.sql`
   - Click "Run" to execute
   - This creates all tables, indexes, and sample doctors

3. **Add security and functions (optional but recommended)**
   - Run `rls-policies.sql` to set up Row Level Security
   - Run `functions.sql` to add business logic functions
   - Run `migrations/002_sample_data.sql` for sample patients/appointments

### Option 2: Step-by-Step Setup

1. **Create a new Supabase project** (same as above)

2. **Run the setup scripts in order**
   - Go to SQL Editor in your Supabase dashboard
   - **First**: Run `extensions.sql` to set up required extensions
   - **Second**: Run `schema.sql` to create all tables and indexes
   - **Third**: Run `rls-policies.sql` to set up security policies
   - **Fourth**: Run `functions.sql` to create business logic functions

3. **Add sample data (optional)**
   - Run `migrations/002_sample_data.sql` for development/testing

### Option 2: Using Supabase CLI

```bash
# Install Supabase CLI
npm install -g supabase

# Login to Supabase
supabase login

# Link to your project
supabase link --project-ref YOUR_PROJECT_REF

# Run migrations
supabase db push
```

## 📁 File Structure

```
supabase/
├── quick-setup.sql          # 🚀 One-script setup (recommended)
├── extensions.sql           # PostgreSQL extensions setup
├── schema.sql              # Core database schema
├── rls-policies.sql        # Row Level Security policies
├── functions.sql           # Business logic functions
├── setup-instructions.md   # This file
└── migrations/
    ├── 001_initial_setup.sql   # Initial migration (fixed)
    └── 002_sample_data.sql     # Sample data for development
```

## 🗃️ Database Architecture

### Core Tables

1. **patients** - Patient registry and demographics
2. **doctors** - Medical staff registry
3. **appointments** - Core appointment management
4. **pending_tasks** - Medical follow-ups and studies
5. **medical_notes** - Clinical documentation
6. **daily_capacity** - Appointment capacity management
7. **audit_log** - Security and compliance logging

### Key Features

- **Full ACID compliance** with PostgreSQL
- **Row Level Security (RLS)** for medical data protection
- **Automated triggers** for data integrity
- **Business functions** for complex operations
- **Performance indexes** for optimal queries
- **Audit logging** for compliance

## 🔧 Configuration Steps

### 1. Environment Variables

Update your `.env.local` file:

```env
NEXT_PUBLIC_SUPABASE_URL=https://your-project-id.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=your-anon-key
```

### 2. Authentication Setup

Configure authentication in Supabase dashboard:

- Enable Email/Password authentication
- Set up proper JWT claims for roles
- Configure user metadata for doctor assignments

### 3. Storage (Optional)

If you need file storage for medical documents:

```sql
-- Create storage bucket
INSERT INTO storage.buckets (id, name, public) VALUES ('medical-documents', 'medical-documents', false);

-- Create RLS policy for storage
CREATE POLICY "Authenticated users can upload medical documents"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'medical-documents' AND auth.is_staff());
```

## 👥 User Roles and Permissions

### Role Hierarchy

1. **admin** - Full system access
2. **doctor** - Medical staff with patient access
3. **nurse** - Limited medical access
4. **receptionist** - Appointment and check-in management

### JWT Token Structure

Your authentication system should provide JWTs with this structure:

```json
{
  "role": "doctor|nurse|admin|receptionist",
  "doctor_id": "uuid-if-doctor",
  "email": "user@example.com",
  "exp": 1234567890
}
```

## 🔒 Security Features

### Row Level Security (RLS)

- All tables have RLS enabled
- Role-based access control
- Automatic audit logging
- Medical data encryption ready

### Data Privacy

- Patient data is protected by RLS
- Medical notes have confidentiality flags
- Audit trail for all sensitive operations
- HIPAA-ready architecture (pending compliance review)

## 📊 Sample Data

The system includes sample data for development:

- 3 doctors (Infectología specialists)
- 5 sample patients
- Random appointments for current week
- Pending tasks with various priorities
- Medical notes examples
- 90 days of daily capacity settings

## 🔧 Maintenance Functions

### Built-in Utilities

```sql
-- Get database health status
SELECT * FROM get_database_health();

-- Clean up old data (keeps 1 year by default)
SELECT cleanup_old_data(365);

-- Reset demo data (development only)
SELECT reset_demo_data();

-- Get daily statistics
SELECT * FROM get_daily_stats('2025-09-15');
```

### Performance Monitoring

Key indexes are created for:
- Appointment date/time lookups
- Patient name searches (with trigram matching)
- Task due date filtering
- Doctor assignment queries

## 🚨 Troubleshooting

### Common Issues

1. **Extension installation fails**
   - **Error**: `operator class "gin_trgm_ops" does not exist`
   - **Solution**: Run `extensions.sql` first, or skip pg_trgm (system works without it)
   - **Note**: pg_trgm may not be available on all Supabase plans

2. **Migration fails**
   - Ensure PostgreSQL extensions are enabled
   - Check for proper permissions
   - Verify Supabase project is fully initialized

2. **RLS policies block queries**
   - Verify JWT token includes proper role claims
   - Check user authentication status
   - Review policy conditions

3. **Performance issues**
   - Ensure all indexes are created
   - Check query execution plans
   - Consider adding custom indexes for specific use cases

### Support Commands

```sql
-- Check if extensions are installed
SELECT * FROM pg_extension WHERE extname IN ('uuid-ossp', 'pgcrypto', 'pg_trgm');

-- Verify all tables exist
SELECT tablename FROM pg_tables WHERE schemaname = 'public' ORDER BY tablename;

-- Check RLS status
SELECT tablename, rowsecurity FROM pg_tables WHERE schemaname = 'public';

-- List all policies
SELECT schemaname, tablename, policyname FROM pg_policies;
```

## 📈 Performance Recommendations

### Query Optimization

1. **Use proper indexes**
   - All foreign keys are indexed
   - Date ranges use btree indexes
   - Text search uses GIN indexes

2. **Efficient queries**
   - Use the provided functions for complex operations
   - Leverage computed views for reporting
   - Batch operations when possible

3. **Connection pooling**
   - Configure Supabase connection limits
   - Use connection pooling in production
   - Monitor connection usage

### Scaling Considerations

- **Read replicas** for reporting queries
- **Partitioning** for large appointment tables (future)
- **Archiving** old completed appointments
- **Caching** frequently accessed data

## 🔄 Backup and Recovery

### Automated Backups

Supabase provides:
- Daily automated backups
- Point-in-time recovery
- Cross-region backup storage

### Manual Backup

```bash
# Export schema
pg_dump --schema-only --no-owner --no-privileges your_db_url > schema_backup.sql

# Export data only
pg_dump --data-only --no-owner --no-privileges your_db_url > data_backup.sql
```

## 📞 Support

For issues with this database setup:

1. Check the troubleshooting section above
2. Review Supabase documentation
3. Contact development team
4. Create an issue in the project repository

---

**⚠️ Important Notes:**
- Always test migrations in a development environment first
- Review all RLS policies before production deployment
- Ensure compliance with local medical data regulations
- Regular security audits are recommended
- Keep backups of critical data