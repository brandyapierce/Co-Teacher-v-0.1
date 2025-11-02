# ⚡ Quick Git Setup - Configure Your Identity

## The Error

Git needs to know who you are before it can create commits. This is a one-time setup.

## ✅ Solution (30 seconds)

### Step 1: Open Terminal in Cursor
- Press **`Ctrl+` `** (Control + backtick)
- Or: **View** → **Terminal**

### Step 2: Run These Commands

**Replace with YOUR actual email and name:**

```bash
git config --global user.email "your-email@example.com"
git config --global user.name "Your Full Name"
```

**Example:**
```bash
git config --global user.email "brand@example.com"
git config --global user.name "Brand"
```

### Step 3: Verify It Worked

```bash
git config --global user.email
git config --global user.name
```

You should see your email and name printed back.

---

## 🎯 Then Try Commit Again

1. Go back to Source Control (`Ctrl+Shift+G`)
2. Paste commit message
3. Press `Ctrl+Enter`
4. Click "Sync" to push!

---

## 💡 Why This Happens

Git requires author information for every commit. The `--global` flag sets this for all repositories on your computer (one-time setup).

