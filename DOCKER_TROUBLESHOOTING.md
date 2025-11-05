# Docker Desktop Troubleshooting

## Issue: Docker Commands Failing

**Symptom:**
```
request returned 500 Internal Server Error for API route
docker-desktop WSL distribution is Stopped
```

**Solution:**

### Method 1: Restart Docker Desktop (Easiest)
1. Look for Docker icon 🐳 in system tray (bottom-right)
2. Right-click Docker icon
3. Click "Restart"
4. Wait 2-3 minutes for full restart
5. Try `docker ps` again

### Method 2: Start Docker Desktop Manually
1. Open Start menu
2. Search "Docker Desktop"
3. Click to launch
4. Wait for "Docker Desktop is running" message
5. Wait 2-3 minutes for WSL to initialize
6. Try `docker ps` again

### Method 3: Check Docker Desktop Settings
1. Open Docker Desktop
2. Go to Settings → General
3. Make sure "Use the WSL 2 based engine" is checked ✅
4. Click "Apply & Restart"

### Method 4: Verify WSL 2 Kernel Update
1. Open Docker Desktop
2. If you see "WSL 2 installation is incomplete" message:
   - Click the provided link
   - Download and install WSL 2 kernel update
   - Restart Docker Desktop

### Method 5: Check System Resources
1. Open Docker Desktop → Settings → Resources
2. Ensure:
   - Memory: At least 2GB allocated
   - CPUs: At least 2 cores
   - Disk: At least 20GB free

## Verification Commands

After restarting, run these to verify:

```powershell
# Check Docker version
docker --version

# Check Docker Compose
docker-compose --version

# Check if Docker daemon is running
docker ps

# Test with hello-world
docker run --rm hello-world
```

## Expected Output When Working

```
docker ps
CONTAINER ID   IMAGE     COMMAND   CREATED   STATUS    PORTS     NAMES
(Empty list is fine - means no containers running)

docker run --rm hello-world
Hello from Docker!
This message shows that your installation appears to be working correctly.
```

## Common Issues

### Issue: "WSL 2 installation is incomplete"
**Fix**: Download WSL 2 kernel update from the link Docker provides

### Issue: "Docker daemon not running"
**Fix**: Restart Docker Desktop from system tray

### Issue: "Hyper-V conflicts"
**Fix**: Ensure WSL 2 is enabled (not Hyper-V)

### Issue: "Out of memory"
**Fix**: Increase Docker Desktop memory allocation in Settings

---

*Last Updated: November 3, 2025*



