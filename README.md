
# Turbo System Monitor - PowerShell Script

## Features

- Live CPU usage with status indicator (Low, Moderate, High)
- RAM usage and status
- Available disk space on drive `C:`
- Disk read/write speed
- System uptime
- CPU temperature (if supported)
- Top 5 processes by CPU usage
- Top 5 processes by RAM usage

## Example Output

```yaml
Turbo System Monitor - 12:34:56
---------------------------------------------------------
CPU: 17% (Low)
RAM: 38.98% (Low)
Free space on disk C: 69.52% (Safe)
Disk Read: 0 KB/s
Disk Write: 160.73 KB/s
System uptime: 0.94 hours
CPU Temperature: 45 °C (Normal)

Top 5 processes by CPU:
  chrome (PID 1234) - CPU: 120.5
  ...

Top 5 processes by RAM:
  code (PID 5678) - RAM: 400 MB
  ...
---------------------------------------------------------
Press CTRL + C to exit
```

## How to Use

1. **Download or clone the repository**:

   ```bash
   git clone https://github.com/Fabricio-colombo/monitor-system
   cd monitor-system
   ```

2. **Enable script execution in PowerShell** (if not already enabled):

   ```powershell
   Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```

3. **Run the script**:

   ```powershell
   .\monitor.ps1
   ```

## Requirements

- PowerShell 5.1 or later  
- Administrator privileges may be required for some performance counters  
- Hardware support may be required for temperature readings
