# GitHub Update Workflow - Pushing Future Changes

## Daily Workflow (After Making Changes)

### Quick 4-Step Process

```cmd
# Step 1: Check what changed
git status

# Step 2: Add all changes
git add .

# Step 3: Commit with a message
git commit -m "Description of what you changed"

# Step 4: Push to GitHub
git push

```

That's it! Your changes are now on GitHub.

---

## Detailed Step-by-Step Guide

### 1️⃣ After Making Changes to Your Files

Open Command Prompt in your project folder:

```cmd
cd C:\github\py01\Etak\HRApp1.0
```

### 2️⃣ Check What Changed

```cmd
git status
```

**This shows:**

- 🟢 Modified files (in red)
- ➕ New files
- ❌ Deleted files

**Example output:**

```
On branch main
Changes not staged for commit:
  modified:   UI/pages/employee/dashboard.html
  modified:   UI/js/app.js
  
Untracked files:
  UI/LANGUAGE_SWITCH_FIX.md
```

### 3️⃣ Add Changes to Staging

**Option A - Add ALL changes (most common):**

```cmd
git add .
```

**Option B - Add specific files only:**

```cmd
git add UI/pages/employee/dashboard.html
git add UI/js/app.js
```

**Option C - Add all files in a folder:**

```cmd
git add UI/
git add backend/
```

### 4️⃣ Commit Changes

```cmd
git commit -m "Your commit message here"
```

**Good commit message examples:**

```cmd
git commit -m "Fix language switcher in leave-request-multi.html"
git commit -m "Add Chinese translations for compensatory leave"
git commit -m "Update dashboard to show real employee data"
git commit -m "Fix calendar date selection bug"
git commit -m "Add new feature: blackout dates management"
```

**Bad commit messages (avoid these):**

```cmd
git commit -m "update"
git commit -m "changes"
git commit -m "fix bug"
```

### 5️⃣ Push to GitHub

```cmd
git push
```

**First time after setup:**

```cmd
git push -u origin main
```

**After that, just:**

```cmd
git push
```

---

## Complete Example Scenario

Let's say you just fixed the language switcher and added new features:

```cmd
# Navigate to project
cd C:\github\py01\Etak\HRApp1.0

# Check what changed
git status

# Output shows:
#   modified:   UI/pages/employee/leave-request-multi.html
#   modified:   UI/js/app.js
#   new file:   UI/LANGUAGE_SWITCH_FIX.md

# Add all changes
git add .

# Commit with descriptive message
git commit -m "Fix language switcher and add translation keys

- Added data-i18n attributes to leave-request-multi.html
- Added 17 new translation keys to app.js
- Created documentation for the fix"

# Push to GitHub
git push

# Done! Changes are now on GitHub
```

---

## Common Scenarios

### Scenario 1: Modified Several Files

```cmd
git status                          # See what changed
git add .                          # Add everything
git commit -m "Update UI styling and fix responsive layout"
git push                           # Push to GitHub
```

### Scenario 2: Added New Feature

```cmd
git status
git add .
git commit -m "Add employee leave balance calculation feature"
git push
```

### Scenario 3: Fixed a Bug

```cmd
git status
git add .
git commit -m "Fix calendar not displaying holidays correctly"
git push
```

### Scenario 4: Updated Documentation Only

```cmd
git status
git add README.md DEPLOYMENT_GUIDE.md
git commit -m "Update documentation with new setup instructions"
git push
```

### Scenario 5: Multiple Small Changes Throughout Day

```cmd
# After each logical change:
git add .
git commit -m "Fix navigation menu on mobile devices"
git push

# Later...
git add .
git commit -m "Update color scheme to match brand guidelines"
git push

# Later...
git add .
git commit -m "Add error handling for leave request form"
git push
```

---

## Best Practices

### ✅ DO:

- Commit often (after each logical change)
- Write clear, descriptive commit messages
- Push to GitHub regularly (at least daily)
- Check `git status` before committing
- Review changes with `git diff` before adding

### ❌ DON'T:

- Wait weeks before committing
- Write vague messages like "update" or "fix"
- Commit sensitive data (.env files, passwords)
- Push broken/untested code to main branch
- Mix unrelated changes in one commit

---

## Useful Additional Commands

### Check Recent Commits

```cmd
git log
# Shows commit history

git log --oneline
# Shows short version
```

### See What Actually Changed

```cmd
git diff
# Shows exact changes before adding

git diff UI/pages/employee/dashboard.html
# Shows changes in specific file
```

### Undo Changes (Before Commit)

```cmd
git restore filename.txt
# Discard changes to a file

git restore .
# Discard ALL changes (careful!)
```

### Undo Last Commit (After Commit, Before Push)

```cmd
git reset HEAD~1
# Undo last commit, keep changes

git reset --hard HEAD~1
# Undo last commit, discard changes (careful!)
```

### Pull Latest Changes (If Working with Team)

```cmd
git pull
# Get latest changes from GitHub before making your changes
```

---

## Visual Workflow Diagram

```
┌─────────────────────────────────────────────────────────┐
│  1. Make Changes to Files                               │
│     (Edit code, add files, delete files)                │
└──────────────────┬──────────────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────────────┐
│  2. git status                                          │
│     (Check what changed)                                │
└──────────────────┬──────────────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────────────┐
│  3. git add .                                           │
│     (Stage all changes)                                 │
└──────────────────┬──────────────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────────────┐
│  4. git commit -m "Message"                             │
│     (Save changes locally)                              │
└──────────────────┬──────────────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────────────┐
│  5. git push                                            │
│     (Upload to GitHub)                                  │
└──────────────────┬──────────────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────────────┐
│  ✅ Changes now visible on GitHub!                      │
│     https://github.com/ywHenry88/HRApp                  │
└─────────────────────────────────────────────────────────┘
```

---

## Typical Daily Routine

### Morning (Start of Day)

```cmd
cd C:\github\py01\Etak\HRApp1.0
git pull                    # Get latest changes
```

### During Work (After Each Feature/Fix)

```cmd
git status                  # Check changes
git add .                   # Stage changes
git commit -m "Descriptive message"
git push                    # Push to GitHub
```

### End of Day

```cmd
git status                  # Make sure everything is committed
git push                    # Final push of the day
```

---

## Troubleshooting

### Problem: "Nothing to commit"

**Meaning:** No changes detected
**Solution:** Make sure you saved your files!

### Problem: "Authentication failed"

**Solution:** Use your Personal Access Token (not password)

```cmd
# Generate new token at:
# https://github.com/settings/tokens
```

### Problem: "Rejected - non-fast-forward"

**Solution:** Pull first, then push

```cmd
git pull origin main
git push
```

### Problem: "Merge conflict"

**Solution:** Resolve conflicts manually

```cmd
git pull
# Edit files to resolve conflicts
git add .
git commit -m "Resolve merge conflicts"
git push
```

### Problem: "Accidentally committed wrong files"

**Solution:** Undo last commit

```cmd
git reset HEAD~1
# Review and re-commit correctly
```

---

## Quick Reference Card

| Command                  | Purpose                |
| ------------------------ | ---------------------- |
| `git status`           | Check what changed     |
| `git add .`            | Add all changes        |
| `git add file.txt`     | Add specific file      |
| `git commit -m "msg"`  | Commit changes         |
| `git push`             | Push to GitHub         |
| `git pull`             | Get latest from GitHub |
| `git log`              | View commit history    |
| `git diff`             | See exact changes      |
| `git restore file.txt` | Undo changes to file   |

---

## Next Steps

1. ✅ Make some changes to your project
2. ✅ Practice the 4-step workflow
3. ✅ Check your GitHub repository to see updates
4. ✅ Repeat daily!

**Remember:** The more you practice, the more natural it becomes!

---

*For the initial setup, refer to: GITHUB_DEPLOYMENT_GUIDE.md*
*For quick commands, see: GITHUB_QUICK_START.txt*
