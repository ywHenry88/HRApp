# GitHub Deployment Guide - HR Leave Management System

## Overview
This guide explains how to deploy the HR Leave Management System to GitHub, including setting up the repository, pushing code, and optionally deploying the UI to GitHub Pages.

---

## Prerequisites

1. **Git installed** on your computer
   - Check: `git --version`
   - Download: https://git-scm.com/downloads

2. **GitHub account**
   - Sign up at: https://github.com

3. **GitHub CLI (optional but recommended)**
   - Download: https://cli.github.com/

---

## Step 1: Initialize Git Repository

Open Command Prompt in your project directory (`C:\github\py01\Etak\HRApp1.0`):

```cmd
cd C:\github\py01\Etak\HRApp1.0
git init
```

---

## Step 2: Create .gitignore File

Create a `.gitignore` file to exclude sensitive and unnecessary files:

```gitignore
# Node modules
node_modules/
**/node_modules/

# Environment variables
.env
*.env
.env.local
.env.production
backend/.env
backend/env.example.txt

# Logs
logs/
*.log
npm-debug.log*
backend/logs/

# Python virtual environment
hr.reference/etakhr/
**/__pycache__/
*.pyc
*.pyo
*.pyd

# Flask sessions
hr.reference/flask_session/

# Database credentials (keep structure files, not actual DB)
# *.sql  # DON'T uncomment this - we want to keep SQL schema files

# OS files
.DS_Store
Thumbs.db
desktop.ini

# IDE files
.vscode/
.idea/
*.swp
*.swo

# Build outputs
dist/
build/
*.min.js
*.min.css

# Temporary files
*.tmp
*.temp
~*

# Package lock files (optional - some teams keep these)
# package-lock.json
# yarn.lock
```

---

## Step 3: Configure Git User (First Time Only)

```cmd
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

---

## Step 4: Add Files to Git

```cmd
# Add all files (respecting .gitignore)
git add .

# Check what will be committed
git status
```

---

## Step 5: Create Initial Commit

```cmd
git commit -m "Initial commit: HR Leave Management System v1.0

- Frontend: Vue.js UI with Tailwind CSS
- Backend: Node.js/Express API
- Database: SQL Server schema and seed data
- Features: Leave management, admin panel, employee dashboard
- Bilingual support: English/Traditional Chinese"
```

---

## Step 6: Create GitHub Repository

### Option A: Using GitHub Website

1. Go to https://github.com/new
2. Repository name: `HRApp` (or your preferred name)
3. Description: `HR Leave Management System - Employee leave tracking and approval system`
4. Visibility: Choose **Public** or **Private**
5. **DO NOT** check "Initialize with README" (you already have files)
6. Click **Create repository**

### Option B: Using GitHub CLI

```cmd
# Login to GitHub
gh auth login

# Create repository
gh repo create HRApp --public --description "HR Leave Management System"
# OR for private:
gh repo create HRApp --private --description "HR Leave Management System"
```

---

## Step 7: Connect Local Repository to GitHub

GitHub will show you commands after creating the repo. Use these:

```cmd
# Add remote origin (replace YOUR_USERNAME with your GitHub username)
git remote add origin https://github.com/YOUR_USERNAME/HRApp.git

# Verify remote
git remote -v

# Push to GitHub (first time)
git push -u origin main
```

**Note:** If you get an error about "master" vs "main" branch:

```cmd
# Rename branch to main
git branch -M main

# Then push
git push -u origin main
```

---

## Step 8: Verify Upload

1. Go to `https://github.com/YOUR_USERNAME/HRApp`
2. Verify all files are uploaded
3. Check that sensitive files (`.env`, `node_modules`) are NOT present

---

## Step 9 (Optional): Deploy UI to GitHub Pages

If you want to host the **static UI prototype** online for demonstration:

### A. Create `gh-pages` branch

```cmd
# Create and switch to gh-pages branch
git checkout -b gh-pages

# Push to GitHub
git push -u origin gh-pages
```

### B. Enable GitHub Pages

1. Go to repository **Settings**
2. Scroll to **Pages** section (left sidebar)
3. Under "Source", select:
   - Branch: `gh-pages`
   - Folder: `/root` or `/UI`
4. Click **Save**

### C. Configure Base Path (if needed)

If deploying from `/UI` folder, you may need to update paths in HTML files.

Your UI will be available at:
`https://YOUR_USERNAME.github.io/HRApp/UI/index.html`

---

## Step 10: Future Updates

After making changes, push updates:

```cmd
# Check status
git status

# Add changed files
git add .

# Commit with message
git commit -m "Description of changes"

# Push to GitHub
git push
```

---

## Important Security Notes

### ⚠️ Before Pushing to GitHub

1. **Remove ALL sensitive data:**
   - Database passwords
   - API keys
   - Secret tokens
   - Production credentials

2. **Check `backend/.env` is NOT committed:**
   ```cmd
   git status
   # Should NOT show backend/.env or any .env files
   ```

3. **Review `backend/env.example.txt`:**
   - Should contain ONLY example/placeholder values
   - No real credentials

4. **SQL Server Connection:**
   - Database credentials should be in `.env` (ignored by git)
   - SQL schema files are OK to commit
   - Do NOT commit actual database files or dumps with real data

---

## Project Structure on GitHub

```
HRApp/
├── .gitignore                    ✅ Excludes sensitive files
├── README.md                     ✅ Project documentation
├── DEPLOYMENT_GUIDE.md           ✅ Setup instructions
├── GITHUB_DEPLOYMENT_GUIDE.md    ✅ This file
├── PRD.md                        ✅ Product requirements
├── backend/
│   ├── config/
│   ├── controllers/
│   ├── routes/
│   ├── middleware/
│   ├── server.js
│   ├── package.json
│   └── env.example.txt           ✅ Example only
├── frontend/
│   ├── src/
│   ├── public/
│   └── package.json
├── database/
│   └── *.sql                     ✅ Schema files OK
├── UI/                           ✅ Static prototype
│   ├── index.html
│   ├── pages/
│   ├── css/
│   └── js/
└── docs/                         ✅ Documentation
```

---

## Recommended Repository Settings

### 1. Add README.md Badge

Add to top of `README.md`:

```markdown
![GitHub last commit](https://img.shields.io/github/last-commit/YOUR_USERNAME/HRApp)
![GitHub issues](https://img.shields.io/github/issues/YOUR_USERNAME/HRApp)
![GitHub stars](https://img.shields.io/github/stars/YOUR_USERNAME/HRApp)
```

### 2. Add Topics/Tags

In GitHub repository settings:
- `leave-management`
- `hr-system`
- `nodejs`
- `vue`
- `sql-server`
- `employee-management`

### 3. Enable Issues

Settings → Features → Issues ✅

### 4. Add License (Optional)

If open-source, add a `LICENSE` file (e.g., MIT License)

---

## GitHub Repository Best Practices

### 1. Branch Strategy

```cmd
# Main branch: production-ready code
main

# Development branch
git checkout -b develop

# Feature branches
git checkout -b feature/employee-dashboard
git checkout -b feature/leave-approval
git checkout -b bugfix/calendar-display
```

### 2. Commit Message Convention

```
feat: Add compensatory leave management
fix: Resolve language switch in leave-request-multi
docs: Update deployment guide
style: Format code and remove version labels
refactor: Optimize leave balance calculation
test: Add unit tests for leave controller
```

### 3. Pull Request Workflow

1. Create feature branch
2. Make changes
3. Push to GitHub
4. Create Pull Request
5. Review and merge

---

## Troubleshooting

### Issue: "Failed to push - rejected"

**Solution:**
```cmd
git pull origin main --rebase
git push origin main
```

### Issue: "Large files warning"

**Solution:**
```cmd
# Remove large file from git history
git rm --cached path/to/large/file
echo "path/to/large/file" >> .gitignore
git commit -m "Remove large file"
```

### Issue: "Authentication failed"

**Solution 1 - Personal Access Token:**
1. GitHub → Settings → Developer settings → Personal access tokens
2. Generate new token with `repo` scope
3. Use token as password when pushing

**Solution 2 - SSH Key:**
```cmd
# Generate SSH key
ssh-keygen -t ed25519 -C "your.email@example.com"

# Add to GitHub: Settings → SSH Keys

# Change remote to SSH
git remote set-url origin git@github.com:YOUR_USERNAME/HRApp.git
```

---

## Quick Reference Commands

```cmd
# Initialize
git init
git add .
git commit -m "Initial commit"

# Connect to GitHub
git remote add origin https://github.com/YOUR_USERNAME/HRApp.git
git branch -M main
git push -u origin main

# Daily workflow
git status                  # Check changes
git add .                   # Stage all changes
git commit -m "message"     # Commit
git push                    # Push to GitHub
git pull                    # Pull latest changes

# Branch management
git branch                  # List branches
git checkout -b new-branch  # Create new branch
git checkout main           # Switch to main
git merge feature-branch    # Merge branch

# Undo changes
git restore file.txt        # Discard changes
git reset HEAD~1            # Undo last commit
git revert commit-hash      # Revert specific commit
```

---

## Additional Resources

- Git Documentation: https://git-scm.com/doc
- GitHub Guides: https://guides.github.com/
- GitHub CLI: https://cli.github.com/
- Git Cheat Sheet: https://education.github.com/git-cheat-sheet-education.pdf

---

## Next Steps After Deployment

1. ✅ Verify repository is accessible
2. ✅ Update README.md with repository URL
3. ✅ Set up GitHub Actions for CI/CD (optional)
4. ✅ Configure branch protection rules (optional)
5. ✅ Invite collaborators (if team project)
6. ✅ Create project board for task tracking
7. ✅ Set up GitHub Pages for UI demo (optional)

---

*Document Created: 2025-10-27*
*Version: 1.0*

