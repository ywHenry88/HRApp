# SQL Files Security Guide - Protecting Sensitive Data on GitHub

## Problem
SQL files with real employee data, passwords, or sensitive information should NOT be uploaded to GitHub.

---

## Solution

### Option 1: Exclude ALL SQL Files with Data (Recommended)

**Already configured in `.gitignore`:**

```gitignore
# Database files with sensitive data
database/*seed*.sql        # Exclude all seed data files
database/02_seed_data.sql
database/08_demo_entitlements_seed.sql
database/10_seed_staff_fields.sql
```

**What this does:**
- ✅ Schema files (structure only) - ALLOWED
- ❌ Seed data files (with real data) - BLOCKED
- ❌ Any backup or dump files - BLOCKED

---

### Option 2: Exclude ALL SQL Files (Most Secure)

If you want to exclude ALL SQL files completely:

**Add to `.gitignore`:**

```gitignore
# Exclude ALL SQL files (most secure)
*.sql
database/*.sql
```

---

### Option 3: Include ONLY Safe Schema Files

If you want to include only structure/schema files:

**Update `.gitignore`:**

```gitignore
# Exclude all SQL files first
database/*.sql

# Then allow only safe schema files (using !)
!database/01_create_schema.sql
!database/03_create_views.sql
!database/04_create_stored_procedures.sql
!database/05_rules_ddl.sql
!database/06_computed_views.sql
!database/07_business_procedures.sql
```

---

## Check What Files Are Being Tracked

Before pushing to GitHub, verify what SQL files Git is tracking:

```cmd
cd C:\github\py01\Etak\HRApp1.0

# List all SQL files that Git knows about
git ls-files | findstr /i ".sql"
```

**Safe to upload:**
- ✅ `database/01_create_schema.sql` - Table structure only
- ✅ `database/03_create_views.sql` - View definitions
- ✅ `database/04_create_stored_procedures.sql` - Procedures
- ✅ `database/05_rules_ddl.sql` - Rules structure
- ✅ `database/06_computed_views.sql` - Computed views
- ✅ `database/07_business_procedures.sql` - Business logic

**DO NOT upload:**
- ❌ `database/02_seed_data.sql` - Contains real data
- ❌ `database/08_demo_entitlements_seed.sql` - Employee entitlements
- ❌ `database/10_seed_staff_fields.sql` - Staff personal data
- ❌ Any file with INSERT statements containing real data

---

## If SQL Files Already Committed

If you already committed SQL files with sensitive data, remove them:

### Step 1: Remove from Git (Keep Local Copy)

```cmd
# Remove specific files from Git tracking
git rm --cached database/02_seed_data.sql
git rm --cached database/08_demo_entitlements_seed.sql
git rm --cached database/10_seed_staff_fields.sql

# Or remove all seed files at once
git rm --cached database/*seed*.sql
```

**Important:** This removes from Git but **keeps the file on your computer**.

### Step 2: Commit the Removal

```cmd
git commit -m "Remove sensitive SQL data files from repository"
```

### Step 3: Push to GitHub

```cmd
git push
```

### Step 4: (Optional) Remove from GitHub History

If the files were already pushed to GitHub and you want to remove them from history:

**⚠️ Warning:** This rewrites Git history. Only do this if necessary.

```cmd
# Remove file from entire Git history
git filter-branch --force --index-filter \
  "git rm --cached --ignore-unmatch database/02_seed_data.sql" \
  --prune-empty --tag-name-filter cat -- --all

# Force push (this rewrites history)
git push origin --force --all
```

**Easier method using BFG Repo-Cleaner:**

1. Download BFG: https://rtyley.github.io/bfg-repo-cleaner/
2. Run:
   ```cmd
   java -jar bfg.jar --delete-files 02_seed_data.sql
   git reflog expire --expire=now --all
   git gc --prune=now --aggressive
   git push --force
   ```

---

## Create Sample Data Instead

Instead of committing real data, create sample/dummy data:

### Create: `database/02_seed_data_SAMPLE.sql`

```sql
-- SAMPLE DATA (Safe to commit to GitHub)
-- Replace with your actual data locally

-- Sample Users (not real data)
INSERT INTO tb_Users (StaffCode, NameEN, NameZH, Email, DepartmentID, IsActive) VALUES
('SAMPLE001', 'John Doe', '李明', 'sample@example.com', 'OFFICE', 1),
('SAMPLE002', 'Jane Smith', '王芳', 'sample2@example.com', 'TRANS', 1);

-- Sample Leave Balances
INSERT INTO tb_LeaveBalances (StaffCode, LeaveTypeID, TotalDays, UsedDays) VALUES
('SAMPLE001', 1, 20, 5),
('SAMPLE002', 1, 15, 3);

-- NOTE: This is SAMPLE data only
-- For real data, use local file: 02_seed_data.sql (not committed to Git)
```

**Commit this sample file:**
```cmd
git add database/02_seed_data_SAMPLE.sql
git commit -m "Add sample data template (no real data)"
git push
```

---

## Best Practices

### ✅ DO:

1. **Keep schema/structure files in Git**
   - Table definitions
   - View definitions
   - Stored procedures
   - Constraints and indexes

2. **Exclude data files from Git**
   - Any file with INSERT statements
   - Seed data with real information
   - Database dumps
   - Backup files

3. **Use sample data**
   - Create `*_SAMPLE.sql` files for GitHub
   - Keep real data files locally only
   - Document in README how to set up real data

4. **Review before committing**
   ```cmd
   git status
   git diff database/
   ```

### ❌ DON'T:

1. Commit files with:
   - Real employee names
   - Real email addresses
   - Real phone numbers
   - Passwords (even hashed)
   - Personal information
   - Production data

2. Upload database dumps to GitHub
3. Share credentials in SQL comments
4. Include connection strings with passwords

---

## Check Current Status

Run this to see what SQL files Git is tracking:

```cmd
cd C:\github\py01\Etak\HRApp1.0

# Show tracked SQL files
git ls-files | findstr /i ".sql"

# Show if any SQL files are staged
git status | findstr /i ".sql"

# Show content of a specific SQL file (first 20 lines)
git show :database/02_seed_data.sql | head -20
```

---

## Quick Fix Commands

### Remove all seed data files from Git:

```cmd
# Navigate to project
cd C:\github\py01\Etak\HRApp1.0

# Remove from Git (keeps local file)
git rm --cached database/02_seed_data.sql
git rm --cached database/08_demo_entitlements_seed.sql
git rm --cached database/10_seed_staff_fields.sql

# Commit the removal
git commit -m "Remove sensitive SQL data files"

# Push to GitHub
git push
```

### Verify files are excluded:

```cmd
# This should show NO seed data files
git ls-files | findstr /i "seed"
```

---

## .gitignore Reference

Current configuration in your `.gitignore`:

```gitignore
# Database files with sensitive data
database/*seed*.sql        # Blocks all *seed*.sql files
database/02_seed_data.sql  # Blocks main seed data
database/08_demo_entitlements_seed.sql
database/10_seed_staff_fields.sql
```

---

## Alternative: Use Environment-Specific Files

Create different SQL files for different environments:

```
database/
├── schema/
│   ├── 01_tables.sql           ✅ Safe (structure only)
│   ├── 02_views.sql            ✅ Safe
│   └── 03_procedures.sql       ✅ Safe
├── data/
│   ├── sample/                 ✅ Safe (dummy data)
│   │   └── users_sample.sql
│   └── production/             ❌ Not in Git (real data)
│       └── users_real.sql      (local only)
```

Add to `.gitignore`:
```gitignore
database/data/production/
```

---

## Summary

**Recommended Setup:**

1. ✅ Update `.gitignore` to exclude seed data files (already done)
2. ✅ Remove any already-committed sensitive files
3. ✅ Create sample data files for GitHub
4. ✅ Keep real data files locally only
5. ✅ Verify before each push

**Commands to run NOW:**

```cmd
cd C:\github\py01\Etak\HRApp1.0

# Check what SQL files are tracked
git ls-files | findstr /i ".sql"

# If you see seed data files, remove them:
git rm --cached database/*seed*.sql
git commit -m "Remove sensitive data files from repository"
git push
```

---

*Your `.gitignore` has been updated to protect sensitive SQL files!*

