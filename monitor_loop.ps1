$refCPU = @{
    Light = 0..49
    Moderate = 50..79
    Overload = 80..100
}

$refRAM = @{
    Light = 0..49
    Moderate = 50..79
    Overload = 80..100
}

$refDiscoLivre = @{
    Low = 0..19
    Moderate = 20..49
    Safe = 50..100
}

$refTempCPU = @{
    Cold = 0..39
    Normal = 40..69
    Warm = 70..100
}

function Get-Status($value, $table) {
    foreach ($key in $table.Keys) {
        if ($table[$key] -contains [int]$value) {
            return $key
        }
    }
    return "Unknown"
}

function Get-CPUUsage {
    $cpuLoad = Get-CimInstance -ClassName Win32_Processor | Select-Object -ExpandProperty LoadPercentage
    return $cpuLoad
}

function Get-CPUTemperature {
    try {
        $temps = Get-WmiObject MSAcpi_ThermalZoneTemperature -Namespace "root/wmi" -ErrorAction Stop
        if ($temps) {
            $tempC = ($temps.CurrentTemperature - 2732) / 10
            return [math]::Round($tempC, 1)
        } else {
            return $null
        }
    } catch {
        return $null
    }
}

function Get-TopProcesses {
    $topCpu = Get-Process | Sort-Object CPU -Descending | Select-Object -First 5 -Property Id, ProcessName, CPU
    $topMem = Get-Process | Sort-Object WS -Descending | Select-Object -First 5 -Property Id, ProcessName, @{Name='MemMB';Expression={[math]::Round($_.WS/1MB,2)}}
    return @{CPU = $topCpu; Mem = $topMem}
}

function Get-DiskIO {
    try {
        $disk = Get-CimInstance -ClassName Win32_PerfFormattedData_PerfDisk_LogicalDisk -Filter "Name='C:'" -ErrorAction Stop
        if ($disk) {
            Write-Host "Debug: Disk data found - ReadBytesPerSec: $($disk.DiskReadBytesPerSec), WriteBytesPerSec: $($disk.DiskWriteBytesPerSec)" -ForegroundColor Yellow
            return @{ReadKB = [math]::Round($disk.DiskReadBytesPerSec / 1KB, 2); WriteKB = [math]::Round($disk.DiskWriteBytesPerSec / 1KB, 2)}
        } else {
            Write-Host "Debug: No disk data found for C:" -ForegroundColor Yellow
            return @{ReadKB = $null; WriteKB = $null}
        }
    } catch {
        Write-Host "Debug: Error accessing disk data: $_" -ForegroundColor Red
        return @{ReadKB = $null; WriteKB = $null}
    }
}

$interval = 60
while ($true) {
    Clear-Host

    $usoCPU = Get-CPUUsage
    $statusCPU = Get-Status $usoCPU $refCPU

    $mem = Get-CimInstance Win32_OperatingSystem
    $usoRAM = [math]::Round((($mem.TotalVisibleMemorySize - $mem.FreePhysicalMemory) / $mem.TotalVisibleMemorySize) * 100, 2)
    $statusRAM = Get-Status $usoRAM $refRAM

    $disco = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"
    $freeSpacePct = [math]::Round(($disco.FreeSpace / $disco.Size) * 100, 2)
    $statusDisco = Get-Status $freeSpacePct $refDiscoLivre

    $diskIO = Get-DiskIO

    $uptime = (Get-CimInstance -ClassName Win32_OperatingSystem).LastBootUpTime
    $upTime = (Get-Date) - $uptime

    $tempCPU = Get-CPUTemperature
    if ($tempCPU) {
        $statusTemp = Get-Status $tempCPU $refTempCPU
    } else {
        $statusTemp = "Not available"
    }

    $topProc = Get-TopProcesses

    Write-Host "Turbo System Monitor - $(Get-Date -Format 'HH:mm:ss')" -ForegroundColor Cyan
    Write-Host "---------------------------------------------------------"

    if ($statusCPU -eq "Overload") { Write-Host "CPU: $usoCPU% ($statusCPU)" -ForegroundColor Red }
    else { Write-Host "CPU: $usoCPU% ($statusCPU)" -ForegroundColor Green }

    if ($statusRAM -eq "Overload") { Write-Host "RAM: $usoRAM% ($statusRAM)" -ForegroundColor Red }
    else { Write-Host "RAM: $usoRAM% ($statusRAM)" -ForegroundColor Green }

    if ($statusDisco -eq "Low") { Write-Host "Free disk space C: $freeSpacePct% ($statusDisco)" -ForegroundColor Red }
    else { Write-Host "Free disk space C: $freeSpacePct% ($statusDisco)" -ForegroundColor Green }

    if ($null -ne $diskIO.ReadKB -and $null -ne $diskIO.WriteKB) {
        Write-Host "Disk reading: $($diskIO.ReadKB) KB/s"
        Write-Host "Disk writing: $($diskIO.WriteKB) KB/s"
    } else {
        Write-Host "Disk reading: Not available"
        Write-Host "Disk writing: Not available"
    }

    Write-Host "System Uptime: $([math]::Round($upTime.TotalHours,2)) hours"

    if ($tempCPU) {
        if ($statusTemp -eq "Warm") { Write-Host "CPU Temperature: $tempCPU °C ($statusTemp)" -ForegroundColor Red }
        else { Write-Host "CPU Temperature: $tempCPU °C ($statusTemp)" -ForegroundColor Green }
    } else {
        Write-Host "CPU Temperature: Not available"
    }

    Write-Host "Top 5 processes by CPU:"
    $topProc.CPU | ForEach-Object {
        Write-Host "  $($_.ProcessName) (PID $($_.Id)) - CPU: $([math]::Round($_.CPU,2))"
    }

    Write-Host "Top 5 processes by RAM:"
    $topProc.Mem | ForEach-Object {
        Write-Host "  $($_.ProcessName) (PID $($_.Id)) - RAM: $($_.MemMB) MB"
    }

    Write-Host "---------------------------------------------------------"
    $remainingTime = $interval
    while ($remainingTime -gt 0) {
        Write-Host "Next refresh in: $remainingTime seconds" -ForegroundColor Yellow
        Start-Sleep -Seconds 1
        $remainingTime--
        Clear-Host
        Write-Host "Turbo System Monitor - $(Get-Date -Format 'HH:mm:ss')" -ForegroundColor Cyan
        Write-Host "---------------------------------------------------------"
        if ($statusCPU -eq "Overload") { Write-Host "CPU: $usoCPU% ($statusCPU)" -ForegroundColor Red }
        else { Write-Host "CPU: $usoCPU% ($statusCPU)" -ForegroundColor Green }
        if ($statusRAM -eq "Overload") { Write-Host "RAM: $usoRAM% ($statusRAM)" -ForegroundColor Red }
        else { Write-Host "RAM: $usoRAM% ($statusRAM)" -ForegroundColor Green }
        if ($statusDisco -eq "Low") { Write-Host "Free disk space C: $freeSpacePct% ($statusDisco)" -ForegroundColor Red }
        else { Write-Host "Free disk space C: $freeSpacePct% ($statusDisco)" -ForegroundColor Green }
        if ($null -ne $diskIO.ReadKB -and $null -ne $diskIO.WriteKB) {
            Write-Host "Disk reading: $($diskIO.ReadKB) KB/s"
            Write-Host "Disk writing: $($diskIO.WriteKB) KB/s"
        } else {
            Write-Host "Disk reading: Not available"
            Write-Host "Disk writing: Not available"
        }
        Write-Host "System Uptime: $([math]::Round($upTime.TotalHours,2)) hours"
        if ($tempCPU) {
            if ($statusTemp -eq "Warm") { Write-Host "CPU Temperature: $tempCPU °C ($statusTemp)" -ForegroundColor Red }
            else { Write-Host "CPU Temperature: $tempCPU °C ($statusTemp)" -ForegroundColor Green }
        } else {
            Write-Host "CPU Temperature: Not available"
        }
        Write-Host "Top 5 processes by CPU:"
        $topProc.CPU | ForEach-Object {
            Write-Host "  $($_.ProcessName) (PID $($_.Id)) - CPU: $([math]::Round($_.CPU,2))"
        }
        Write-Host "Top 5 processes by RAM:"
        $topProc.Mem | ForEach-Object {
            Write-Host "  $($_.ProcessName) (PID $($_.Id)) - RAM: $($_.MemMB) MB"
        }
        Write-Host "---------------------------------------------------------"
        Write-Host "Created by: Fabricio Colombo" -ForegroundColor DarkGray

    }
    Write-Host "Refreshing now..." -ForegroundColor Yellow

    Write-Host "---------------------------------------------------------"
    Write-Host "Press CTRL + C to exit"
}