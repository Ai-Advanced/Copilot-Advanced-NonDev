# ==============================================================
# powershell-file-automation.ps1
# 오피스 워커를 위한 PowerShell 파일 자동화 예시 모음
#
# 사용법:
#   1. 각 예시는 독립된 함수로 구성되어 있습니다.
#   2. 파일 하단의 "실행 예시" 섹션에서 원하는 함수를 호출하세요.
#   3. 처음에는 반드시 $DryRun = $true 로 미리보기를 확인하세요.
#
# 실행 방법:
#   VS Code 터미널 > .\powershell-file-automation.ps1
#   또는 PowerShell에서: & "C:\경로\powershell-file-automation.ps1"
#
# 실행 권한 오류 시:
#   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
# ==============================================================

# ---------------------------------------------------------------
# 예시 1. 파일명 앞에 날짜 추가 (YYYYMMDD_원본파일명)
# 상황: 보고서 PDF 파일들에 생성일자를 이름 앞에 붙이고 싶을 때
# ---------------------------------------------------------------
function Add-DatePrefix {
    param(
        [string]$FolderPath = "C:\Downloads",   # 대상 폴더
        [string]$Filter     = "*.pdf",           # 파일 필터 (예: *.pdf, *.docx, *.*)
        [bool]  $DryRun     = $true              # $false 로 바꾸면 실제 실행
    )

    Write-Host "`n[예시 1] 파일명 날짜 추가 시작 — 모드: $(if ($DryRun) { '미리보기' } else { '실제 실행' })" -ForegroundColor Cyan
    Write-Host "대상 폴더: $FolderPath | 필터: $Filter`n" -ForegroundColor Gray

    $files = Get-ChildItem -Path $FolderPath -Filter $Filter -File
    $count = 0

    foreach ($file in $files) {
        # 이미 날짜로 시작하는 파일은 건너뜀 (8자리 숫자_)
        if ($file.BaseName -match "^\d{8}_") {
            Write-Host "[건너뜀] $($file.Name) — 이미 날짜 포함" -ForegroundColor Yellow
            continue
        }

        $datePrefix = $file.CreationTime.ToString("yyyyMMdd")
        $newName    = "${datePrefix}_$($file.Name)"

        if ($DryRun) {
            Write-Host "[미리보기] $($file.Name)  →  $newName" -ForegroundColor Cyan
        } else {
            Rename-Item -LiteralPath $file.FullName -NewName $newName -ErrorAction SilentlyContinue
            Write-Host "[완료] $($file.Name)  →  $newName" -ForegroundColor Green
        }
        $count++
    }

    $mode = if ($DryRun) { "미리보기" } else { "실제 변경" }
    Write-Host "`n[$mode 완료] 처리 파일 수: $count 개`n" -ForegroundColor White
}


# ---------------------------------------------------------------
# 예시 2. 확장자별 폴더 분류
# 상황: 다운로드 폴더에 이미지, 문서, 영상 등이 뒤섞여 있을 때
# ---------------------------------------------------------------
function Sort-FilesByExtension {
    param(
        [string]$SourcePath = "C:\Downloads",   # 정리할 폴더
        [bool]  $DryRun     = $true
    )

    Write-Host "`n[예시 2] 확장자별 분류 시작 — 모드: $(if ($DryRun) { '미리보기' } else { '실제 실행' })" -ForegroundColor Cyan
    Write-Host "대상 폴더: $SourcePath`n" -ForegroundColor Gray

    # 분류 규칙: 확장자 → 대상 폴더명
    $categoryMap = @{
        "Images"    = @("jpg","jpeg","png","gif","bmp","webp","svg","ico","tiff")
        "Documents" = @("pdf","docx","doc","xlsx","xls","pptx","ppt","txt","csv","md","hwp")
        "Videos"    = @("mp4","mov","avi","mkv","wmv","flv","webm")
        "Archives"  = @("zip","rar","7z","tar","gz","bz2")
        "Installers"= @("exe","msi","dmg","pkg","deb")
        "Audio"     = @("mp3","wav","flac","aac","ogg","wma")
    }

    $counts = @{}
    foreach ($cat in $categoryMap.Keys) { $counts[$cat] = 0 }
    $counts["Others"] = 0

    $files = Get-ChildItem -Path $SourcePath -File

    foreach ($file in $files) {
        # 스크립트 파일 자체는 건너뜀
        if ($file.Extension -in @(".ps1", ".bat", ".cmd", ".sh")) {
            continue
        }

        $ext = $file.Extension.TrimStart(".").ToLower()
        $targetCategory = "Others"

        foreach ($cat in $categoryMap.Keys) {
            if ($ext -in $categoryMap[$cat]) {
                $targetCategory = $cat
                break
            }
        }

        $targetFolder = Join-Path $SourcePath $targetCategory
        $targetFile   = Join-Path $targetFolder $file.Name

        # 동일 이름 파일 충돌 처리 — 타임스탬프 추가
        if (Test-Path $targetFile) {
            $ts       = Get-Date -Format "yyyyMMdd_HHmmss"
            $newName  = "$($file.BaseName)_$ts$($file.Extension)"
            $targetFile = Join-Path $targetFolder $newName
        }

        if ($DryRun) {
            Write-Host "[미리보기] $($file.Name)  →  $targetCategory\$(Split-Path $targetFile -Leaf)" -ForegroundColor Cyan
        } else {
            if (-not (Test-Path $targetFolder)) {
                New-Item -ItemType Directory -Path $targetFolder | Out-Null
                Write-Host "[생성] 폴더: $targetFolder" -ForegroundColor DarkGray
            }
            Move-Item -LiteralPath $file.FullName -Destination $targetFile
            Write-Host "[이동] $($file.Name)  →  $targetCategory" -ForegroundColor Green
        }

        $counts[$targetCategory]++
    }

    Write-Host "`n[분류 요약]" -ForegroundColor White
    foreach ($cat in ($counts.Keys | Sort-Object)) {
        if ($counts[$cat] -gt 0) {
            Write-Host "  $cat : $($counts[$cat]) 개" -ForegroundColor White
        }
    }
    Write-Host ""
}


# ---------------------------------------------------------------
# 예시 3. 오래된 파일 보관 폴더로 이동
# 상황: Working 폴더에서 N일 이상 수정 없는 파일을 Archive로 이동
# ---------------------------------------------------------------
function Archive-OldFiles {
    param(
        [string]$SourcePath  = "C:\Documents\Working",   # 원본 폴더
        [string]$ArchivePath = "C:\Documents\Archive",   # 보관 폴더
        [int]   $DaysThreshold = 90,                      # 기준 일수
        [bool]  $DryRun      = $true
    )

    Write-Host "`n[예시 3] 오래된 파일 보관 시작 — 기준: $DaysThreshold 일 이전 수정" -ForegroundColor Cyan
    Write-Host "모드: $(if ($DryRun) { '미리보기' } else { '실제 실행' })`n" -ForegroundColor Gray

    $cutoff = (Get-Date).AddDays(-$DaysThreshold)
    $files  = Get-ChildItem -Path $SourcePath -File |
              Where-Object { $_.LastWriteTime -lt $cutoff }

    if ($files.Count -eq 0) {
        Write-Host "[완료] ${DaysThreshold}일 이상 된 파일이 없습니다." -ForegroundColor Yellow
        return
    }

    $logPath = Join-Path $ArchivePath "archive-log.txt"
    $count   = 0

    foreach ($file in $files) {
        # 보관 폴더를 이동 월 기준으로 생성 (예: Archive\2026-07)
        $monthFolder  = $file.LastWriteTime.ToString("yyyy-MM")
        $targetFolder = Join-Path $ArchivePath $monthFolder
        $targetFile   = Join-Path $targetFolder $file.Name

        if ($DryRun) {
            Write-Host "[미리보기] $($file.Name)  →  Archive\$monthFolder\" -ForegroundColor Cyan
        } else {
            if (-not (Test-Path $targetFolder)) {
                New-Item -ItemType Directory -Path $targetFolder | Out-Null
            }
            Move-Item -LiteralPath $file.FullName -Destination $targetFile
            # 로그 기록 (append)
            "$((Get-Date -Format 'yyyy-MM-dd HH:mm'))  이동: $($file.FullName)  →  $targetFile" |
                Add-Content -Path $logPath -Encoding UTF8
            Write-Host "[이동] $($file.Name)" -ForegroundColor Green
        }
        $count++
    }

    $mode = if ($DryRun) { "미리보기" } else { "실제 이동" }
    Write-Host "`n[$mode 완료] $count 개 파일 처리`n" -ForegroundColor White
}


# ---------------------------------------------------------------
# 예시 4. 폴더 백업 (날짜 이름 자동 생성)
# 상황: 중요 폴더를 매일/매월 날짜 폴더로 백업
# ---------------------------------------------------------------
function Backup-Folder {
    param(
        [string]$SourcePath  = "C:\Documents\Important",   # 백업 원본
        [string]$BackupRoot  = "D:\Backups",                # 백업 저장 위치
        [int]   $KeepDays    = 30,                          # 오래된 백업 보존 기간
        [bool]  $DryRun      = $true
    )

    $today      = Get-Date -Format "yyyyMMdd"
    $folderName = "$(Split-Path $SourcePath -Leaf)_$today"
    $backupDest = Join-Path $BackupRoot $folderName

    Write-Host "`n[예시 4] 폴더 백업 — 모드: $(if ($DryRun) { '미리보기' } else { '실제 실행' })" -ForegroundColor Cyan
    Write-Host "원본: $SourcePath`n백업: $backupDest`n" -ForegroundColor Gray

    # 오늘 이미 백업 존재 여부 확인
    if (Test-Path $backupDest) {
        Write-Host "[건너뜀] 오늘 백업이 이미 존재합니다: $backupDest" -ForegroundColor Yellow
        return
    }

    if ($DryRun) {
        $fileCount = (Get-ChildItem -Path $SourcePath -Recurse -File).Count
        Write-Host "[미리보기] $SourcePath ($fileCount 개 파일)  →  $backupDest" -ForegroundColor Cyan
    } else {
        Copy-Item -Path $SourcePath -Destination $backupDest -Recurse -Force
        $copiedCount = (Get-ChildItem -Path $backupDest -Recurse -File).Count
        Write-Host "[완료] 백업 성공: $backupDest ($copiedCount 개 파일)" -ForegroundColor Green

        # 오래된 백업 정리
        Write-Host "`n[정리] ${KeepDays}일 이상 된 백업 폴더 확인 중..." -ForegroundColor Gray
        $cutoff      = (Get-Date).AddDays(-$KeepDays)
        $baseName    = Split-Path $SourcePath -Leaf
        $oldBackups  = Get-ChildItem -Path $BackupRoot -Directory |
                       Where-Object { $_.Name -like "${baseName}_*" -and $_.CreationTime -lt $cutoff }

        foreach ($old in $oldBackups) {
            Write-Host "[삭제] 오래된 백업: $($old.Name)" -ForegroundColor DarkRed
            Remove-Item -LiteralPath $old.FullName -Recurse -Force
        }
    }
    Write-Host ""
}


# ---------------------------------------------------------------
# 예시 5. 파일 목록 CSV 추출
# 상황: 특정 폴더의 파일 목록을 엑셀용 CSV로 내보내기
# ---------------------------------------------------------------
function Export-FileList {
    param(
        [string]$FolderPath = "C:\Documents\Contracts",   # 조사할 폴더
        [string]$OutputPath = "C:\Documents",             # CSV 저장 위치
        [bool]  $Recurse    = $true                        # 하위 폴더 포함 여부
    )

    Write-Host "`n[예시 5] 파일 목록 CSV 추출 시작" -ForegroundColor Cyan
    Write-Host "대상: $FolderPath | 하위 폴더: $Recurse`n" -ForegroundColor Gray

    $today      = Get-Date -Format "yyyyMMdd"
    $outputFile = Join-Path $OutputPath "file-list-$today.csv"

    $params = @{ Path = $FolderPath; File = $true }
    if ($Recurse) { $params.Recurse = $true }

    $files = Get-ChildItem @params

    $data = $files | Select-Object `
        @{ N="파일명";     E={ $_.Name } },
        @{ N="확장자";     E={ $_.Extension } },
        @{ N="크기(KB)";   E={ [math]::Round($_.Length / 1KB, 1) } },
        @{ N="생성일";     E={ $_.CreationTime.ToString("yyyy-MM-dd HH:mm") } },
        @{ N="수정일";     E={ $_.LastWriteTime.ToString("yyyy-MM-dd HH:mm") } },
        @{ N="전체경로";   E={ $_.FullName } }

    # UTF-8 BOM으로 저장 — 엑셀에서 한글 깨짐 방지
    $data | Export-Csv -Path $outputFile -NoTypeInformation -Encoding UTF8

    Write-Host "[완료] $($files.Count) 개 파일 목록 저장: $outputFile`n" -ForegroundColor Green
}


# ---------------------------------------------------------------
# 예시 6. 파일명 일괄 치환 (특정 텍스트 교체)
# 상황: 파일명에 포함된 특정 단어를 다른 단어로 바꾸고 싶을 때
#       예: "보고서_최종" → "보고서_확정"
# ---------------------------------------------------------------
function Rename-FileContent {
    param(
        [string]$FolderPath  = "C:\Documents",
        [string]$SearchText  = "최종",      # 찾을 텍스트
        [string]$ReplaceText = "확정",      # 바꿀 텍스트
        [string]$Filter      = "*.*",
        [bool]  $DryRun      = $true
    )

    Write-Host "`n[예시 6] 파일명 텍스트 치환 — '$SearchText'  →  '$ReplaceText'" -ForegroundColor Cyan
    Write-Host "모드: $(if ($DryRun) { '미리보기' } else { '실제 실행' })`n" -ForegroundColor Gray

    $files = Get-ChildItem -Path $FolderPath -Filter $Filter -File |
             Where-Object { $_.Name -like "*$SearchText*" }

    if ($files.Count -eq 0) {
        Write-Host "[완료] '$SearchText' 를 포함한 파일이 없습니다." -ForegroundColor Yellow
        return
    }

    $count = 0
    foreach ($file in $files) {
        $newName = $file.Name -replace [regex]::Escape($SearchText), $ReplaceText

        if ($DryRun) {
            Write-Host "[미리보기] $($file.Name)  →  $newName" -ForegroundColor Cyan
        } else {
            Rename-Item -LiteralPath $file.FullName -NewName $newName
            Write-Host "[완료] $($file.Name)  →  $newName" -ForegroundColor Green
        }
        $count++
    }

    $mode = if ($DryRun) { "미리보기" } else { "실제 변경" }
    Write-Host "`n[$mode 완료] $count 개 파일 처리`n" -ForegroundColor White
}


# ---------------------------------------------------------------
# 예시 7. 빈 폴더 탐지 및 정리
# 상황: 공유 드라이브나 프로젝트 폴더에 비어있는 폴더가 많을 때
# ---------------------------------------------------------------
function Remove-EmptyFolders {
    param(
        [string]$RootPath = "C:\Projects",
        [bool]  $DryRun   = $true
    )

    Write-Host "`n[예시 7] 빈 폴더 탐지 — 루트: $RootPath" -ForegroundColor Cyan
    Write-Host "모드: $(if ($DryRun) { '미리보기 (삭제 없음)' } else { '실제 삭제' })`n" -ForegroundColor Gray

    # 하위부터 순서대로 처리 (부모 폴더가 빈 폴더가 되는 경우 처리)
    $emptyFolders = Get-ChildItem -Path $RootPath -Recurse -Directory |
                    Where-Object { (Get-ChildItem -Path $_.FullName -Recurse -File).Count -eq 0 } |
                    Sort-Object -Property FullName -Descending

    if ($emptyFolders.Count -eq 0) {
        Write-Host "[완료] 빈 폴더가 없습니다." -ForegroundColor Yellow
        return
    }

    $count = 0
    foreach ($folder in $emptyFolders) {
        if ($DryRun) {
            Write-Host "[미리보기] 빈 폴더: $($folder.FullName)" -ForegroundColor Cyan
        } else {
            Remove-Item -LiteralPath $folder.FullName -Force
            Write-Host "[삭제] $($folder.FullName)" -ForegroundColor Green
        }
        $count++
    }

    $mode = if ($DryRun) { "탐지" } else { "삭제" }
    Write-Host "`n[$mode 완료] $count 개 빈 폴더 처리`n" -ForegroundColor White
}


# ---------------------------------------------------------------
# 예시 8. 파일 중복 탐지 (같은 이름 파일 찾기)
# 상황: 폴더 내에 같은 이름의 파일이 여러 곳에 있는지 확인할 때
#       삭제는 하지 않고 보고서만 출력
# ---------------------------------------------------------------
function Find-DuplicateFileNames {
    param(
        [string]$FolderPath  = "C:\Documents",
        [string]$OutputCsv   = "C:\Documents\duplicates.csv",
        [bool]  $Recurse     = $true
    )

    Write-Host "`n[예시 8] 중복 파일명 탐지 시작" -ForegroundColor Cyan
    Write-Host "대상: $FolderPath`n" -ForegroundColor Gray

    $params = @{ Path = $FolderPath; File = $true }
    if ($Recurse) { $params.Recurse = $true }

    $files = Get-ChildItem @params

    # 파일명을 기준으로 그룹화, 2개 이상인 것만
    $duplicates = $files |
        Group-Object -Property Name |
        Where-Object { $_.Count -gt 1 }

    if ($duplicates.Count -eq 0) {
        Write-Host "[완료] 중복 파일명 없음." -ForegroundColor Yellow
        return
    }

    Write-Host "[발견] 중복 파일명 그룹: $($duplicates.Count) 개`n" -ForegroundColor Yellow

    $report = foreach ($group in $duplicates) {
        foreach ($file in $group.Group) {
            [PSCustomObject]@{
                파일명   = $file.Name
                경로     = $file.FullName
                크기KB   = [math]::Round($file.Length / 1KB, 1)
                수정일   = $file.LastWriteTime.ToString("yyyy-MM-dd")
            }
        }
    }

    $report | Export-Csv -Path $OutputCsv -NoTypeInformation -Encoding UTF8
    Write-Host "[완료] 중복 목록 저장: $OutputCsv" -ForegroundColor Green
    Write-Host "총 중복 파일 수: $($report.Count) 개 (삭제는 수동으로 진행하세요)`n" -ForegroundColor White
}


# ---------------------------------------------------------------
# 예시 9. 날짜 범위로 파일 복사 (특정 기간 파일만 추출)
# 상황: 특정 날짜 범위에 수정된 파일만 따로 모아야 할 때
#       예: 지난달 수정된 계약서만 감사용으로 복사
# ---------------------------------------------------------------
function Copy-FilesByDateRange {
    param(
        [string]$SourcePath  = "C:\Documents\Contracts",
        [string]$TargetPath  = "C:\Documents\Audit",
        [string]$StartDate   = "2026-07-01",   # 시작일 (포함)
        [string]$EndDate     = "2026-07-31",   # 종료일 (포함)
        [bool]  $DryRun      = $true
    )

    $start = [datetime]$StartDate
    $end   = ([datetime]$EndDate).AddDays(1)  # 종료일 자정까지 포함

    Write-Host "`n[예시 9] 날짜 범위 파일 복사" -ForegroundColor Cyan
    Write-Host "$StartDate ~ $EndDate 수정 파일  →  $TargetPath" -ForegroundColor Gray
    Write-Host "모드: $(if ($DryRun) { '미리보기' } else { '실제 실행' })`n" -ForegroundColor Gray

    $files = Get-ChildItem -Path $SourcePath -File -Recurse |
             Where-Object { $_.LastWriteTime -ge $start -and $_.LastWriteTime -lt $end }

    if ($files.Count -eq 0) {
        Write-Host "[완료] 해당 기간 파일 없음." -ForegroundColor Yellow
        return
    }

    $count = 0
    foreach ($file in $files) {
        $destFile = Join-Path $TargetPath $file.Name

        if ($DryRun) {
            Write-Host "[미리보기] $($file.Name) ($($file.LastWriteTime.ToString('yyyy-MM-dd')))" -ForegroundColor Cyan
        } else {
            if (-not (Test-Path $TargetPath)) {
                New-Item -ItemType Directory -Path $TargetPath | Out-Null
            }
            Copy-Item -LiteralPath $file.FullName -Destination $destFile -Force
            Write-Host "[복사] $($file.Name)" -ForegroundColor Green
        }
        $count++
    }

    $mode = if ($DryRun) { "미리보기" } else { "복사 완료" }
    Write-Host "`n[$mode] $count 개 파일 처리`n" -ForegroundColor White
}


# ---------------------------------------------------------------
# 예시 10. 월간 정리 패키지 (자동화 묶음 실행)
# 상황: 매월 말 실행하는 정리 작업을 한 번에 처리
#       예시 1(날짜 추가) + 예시 3(오래된 파일 보관) + 예시 4(백업) 순서 실행
# ---------------------------------------------------------------
function Run-MonthlyCleanup {
    param(
        [bool]$DryRun = $true
    )

    $startTime = Get-Date
    Write-Host "============================================" -ForegroundColor Magenta
    Write-Host " 월간 정리 패키지 시작 — $(Get-Date -Format 'yyyy-MM-dd HH:mm')" -ForegroundColor Magenta
    Write-Host " 모드: $(if ($DryRun) { '미리보기 (변경 없음)' } else { '실제 실행' })" -ForegroundColor Magenta
    Write-Host "============================================`n" -ForegroundColor Magenta

    # Step 1. 보고서 폴더 PDF 파일에 날짜 추가
    Write-Host "--- Step 1: 보고서 파일 날짜 추가 ---" -ForegroundColor DarkCyan
    Add-DatePrefix -FolderPath "C:\Documents\Reports" -Filter "*.pdf" -DryRun $DryRun

    # Step 2. 오래된 Working 파일 Archive로 이동
    Write-Host "--- Step 2: 오래된 파일 보관 ---" -ForegroundColor DarkCyan
    Archive-OldFiles `
        -SourcePath  "C:\Documents\Working" `
        -ArchivePath "C:\Documents\Archive" `
        -DaysThreshold 90 `
        -DryRun $DryRun

    # Step 3. 중요 폴더 백업
    Write-Host "--- Step 3: 월간 백업 ---" -ForegroundColor DarkCyan
    Backup-Folder `
        -SourcePath  "C:\Documents\Important" `
        -BackupRoot  "D:\MonthlyBackups" `
        -KeepDays    90 `
        -DryRun $DryRun

    $elapsed = (Get-Date) - $startTime
    Write-Host "============================================" -ForegroundColor Magenta
    Write-Host " 월간 정리 패키지 완료 — 소요: $([math]::Round($elapsed.TotalSeconds, 1))초" -ForegroundColor Magenta
    Write-Host "============================================`n" -ForegroundColor Magenta
}


# ==============================================================
# 실행 예시 — 아래 줄의 주석을 풀어서 실행하세요.
# 처음 실행 시 반드시 DryRun = $true 로 미리보기 확인!
# ==============================================================

# 예시 1. 다운로드 폴더 PDF 파일에 날짜 추가 (미리보기)
# Add-DatePrefix -FolderPath "C:\Downloads" -Filter "*.pdf" -DryRun $true

# 예시 2. 다운로드 폴더 확장자별 분류 (미리보기)
# Sort-FilesByExtension -SourcePath "C:\Downloads" -DryRun $true

# 예시 3. 90일 이상 된 파일 보관 (미리보기)
# Archive-OldFiles -SourcePath "C:\Documents\Working" -ArchivePath "C:\Documents\Archive" -DaysThreshold 90 -DryRun $true

# 예시 4. 중요 폴더 백업 (미리보기)
# Backup-Folder -SourcePath "C:\Documents\Important" -BackupRoot "D:\Backups" -KeepDays 30 -DryRun $true

# 예시 5. 계약서 폴더 파일 목록 CSV 추출 (실제 실행 — 읽기 전용이라 안전)
# Export-FileList -FolderPath "C:\Documents\Contracts" -OutputPath "C:\Documents"

# 예시 6. 파일명 "최종"을 "확정"으로 치환 (미리보기)
# Rename-FileContent -FolderPath "C:\Documents" -SearchText "최종" -ReplaceText "확정" -DryRun $true

# 예시 7. 빈 폴더 탐지 (미리보기)
# Remove-EmptyFolders -RootPath "C:\Projects" -DryRun $true

# 예시 8. 중복 파일명 탐지 및 CSV 저장 (읽기 전용)
# Find-DuplicateFileNames -FolderPath "C:\Documents" -OutputCsv "C:\Documents\duplicates.csv"

# 예시 9. 지난달 계약서만 감사용 폴더로 복사 (미리보기)
# Copy-FilesByDateRange -SourcePath "C:\Documents\Contracts" -TargetPath "C:\Documents\Audit-Jul" -StartDate "2026-07-01" -EndDate "2026-07-31" -DryRun $true

# 예시 10. 월간 정리 패키지 전체 실행 (미리보기)
# Run-MonthlyCleanup -DryRun $true

# ==============================================================
# 실제 실행할 때는 각 함수의 -DryRun $true 를 -DryRun $false 로 변경
# ==============================================================
