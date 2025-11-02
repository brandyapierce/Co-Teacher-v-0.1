# Docker Installation Verification Commands

After installing Docker Desktop, run these commands in PowerShell to verify everything works:

## 1. Check Docker Version
```powershell
docker --version
```
**Expected output:**
```
Docker version 24.x.x, build xxxxxxx
```

## 2. Check Docker Compose Version
```powershell
docker-compose --version
```
**Expected output:**
```
Docker Compose version v2.x.x
```

## 3. Test Docker is Running
```powershell
docker ps
```
**Expected output:**
```
CONTAINER ID   IMAGE     COMMAND   CREATED   STATUS    PORTS     NAMES
```
(Empty list is fine - means no containers running yet)

## 4. Run Hello World Test
```powershell
docker run hello-world
```
**Expected output:**
```
Hello from Docker!
This message shows that your installation appears to be working correctly.
...
```

## If All Tests Pass ✅
Docker is installed correctly and ready to use!

## If Tests Fail ❌
1. Make sure Docker Desktop is running (check system tray)
2. Restart Docker Desktop
3. Restart your computer
4. Check if WSL 2 is installed (see troubleshooting section)

---

## Next Steps
Once Docker is verified, you can proceed with backend testing:
```powershell
cd C:\Users\brand\Downloads\Co-Teacher-v-0.1
cd services\gateway_bff
docker-compose up -d
```

