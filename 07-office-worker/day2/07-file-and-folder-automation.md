# 07. 파일/폴더 자동화 — PowerShell 스크립트로 반복 작업 끝내기

## 학습 목표

- PowerShell이 무엇인지 이해하고 VS Code에서 실행하는 법 익히기
- Copilot으로 파일 rename, 분류, 이동, 백업 스크립트를 생성하고 안전하게 실행하기
- 다운로드 폴더 자동 정리 스크립트를 처음부터 완성까지 만들기
- macOS 사용자를 위한 zsh 대안 명령어 이해

**예상 소요**: 60분 (실습 포함)

---

## 7.1 왜 PowerShell인가

"나는 코딩 안 배웠는데요."

이 과정에서 PowerShell을 다루는 이유는 **코딩을 가르치려는 게 아닙니다.** Copilot이 스크립트를 만들어주면 여러분은 실행만 하면 됩니다. 필요한 건 딱 두 가지입니다.

1. **어떤 작업을 원하는지 말로 설명하는 능력** (이미 갖고 있음)
2. **스크립트가 실제로 뭘 하는지 대략 읽을 수 있는 감각** (이 챕터에서 익힘)

PowerShell을 고르는 이유는 Windows에 기본 설치되어 있고, 파일 관련 작업에 가장 강하기 때문입니다.

---

## 7.2 PowerShell 기초 감각 — 핵심 명령어 5개

스크립트를 직접 짜지 않더라도 결과를 이해하려면 이 5개는 알아야 합니다.

| 명령어 | 하는 일 | 실생활 비유 |
|--------|---------|-----------|
| `Get-ChildItem` | 파일 목록 가져오기 | 폴더 열어서 목록 보기 |
| `Move-Item` | 파일 이동 | 파일을 잘라내어 다른 폴더에 붙여넣기 |
| `Copy-Item` | 파일 복사 | 복사해서 붙여넣기 |
| `Rename-Item` | 파일 이름 변경 | F2 누르고 이름 바꾸기 |
| `Remove-Item` | 파일 삭제 | Delete 키 누르기 |

이 5개가 모든 파일 자동화 스크립트의 기본 재료입니다.

### VS Code 터미널에서 직접 실행하기

```
VS Code > 보기(View) > 터미널 (Ctrl + `)
→ 터미널 창이 아래에 열림
→ pwsh 입력 후 Enter (PowerShell 7 실행)
또는 powershell 입력 (Windows PowerShell 5 실행)
```

간단 테스트:

```powershell
# 현재 폴더의 파일 목록 보기
Get-ChildItem

# 특정 폴더의 PDF 파일만 보기
Get-ChildItem -Path "C:\Downloads" -Filter "*.pdf"

# 파일 개수 세기
(Get-ChildItem -Path "C:\Downloads").Count
```

---

## 7.3 Copilot으로 스크립트 생성하기 — 기본 패턴

### 안전 원칙: Dry-run 먼저

파일을 이동하거나 이름을 바꾸는 스크립트는 **반드시 먼저 미리보기(dry-run)를 실행**해야 합니다. 실수로 파일을 삭제하거나 덮어쓰면 복구가 어렵습니다.

**Copilot 프롬프트에 항상 포함**:

```
스크립트 상단에 $DryRun = $true 변수 추가.
$DryRun이 $true이면 실제 변경 없이 변경될 내용만 콘솔에 출력.
$DryRun을 $false로 바꾸면 실제 실행.
```

### 프롬프트 기본 구조

```
Windows PowerShell 스크립트 작성.

목적: [무엇을 자동화]
대상 폴더: [경로]
동작:
1. [단계 1]
2. [단계 2]
3. [단계 3]

예외 처리:
- [상황 1] → [처리]
- [상황 2] → [처리]

추가:
- $DryRun = $true 변수로 미리보기/실행 전환
- 스크립트 상단에 사용법 주석 3줄
- 완료 후 처리된 파일 수 출력
```

---

## 7.4 스크립트 5가지 — 실무 상황별

### 스크립트 1. 파일 이름 일괄 변경 (날짜 추가)

**상황**: 보고서 PDF 파일들에 생성일자를 이름 앞에 붙이고 싶다.

**프롬프트**:

```
Windows PowerShell 스크립트 작성.

목적: 특정 폴더의 PDF 파일 이름 앞에 파일 생성일자(YYYYMMDD_) 추가
대상: C:\Documents\Reports 폴더의 *.pdf 파일
규칙: 파일 이름이 이미 8자리 숫자로 시작하면 건너뜀 (중복 방지)
예시: "분기보고서.pdf" → "20260720_분기보고서.pdf"

추가:
- $DryRun = $true 변수
- 상단 사용법 주석 포함
- 처리 완료된 파일 수 출력
```

**Copilot 생성 스크립트**:

```powershell
# ==============================================================
# 파일명 앞에 생성일자 추가 스크립트
# 사용법: $DryRun = $true 로 미리보기, $false 로 실제 실행
# 대상: $TargetPath 폴더의 PDF 파일
# ==============================================================

$DryRun     = $true                     # $false 로 변경하면 실제 실행
$TargetPath = "C:\Documents\Reports"    # 대상 폴더 경로

$files = Get-ChildItem -Path $TargetPath -Filter "*.pdf"
$count = 0

foreach ($file in $files) {
    $baseName = $file.BaseName

    # 이미 날짜로 시작하는 파일은 건너뜀 (8자리 숫자 확인)
    if ($baseName -match "^\d{8}_") {
        Write-Host "[건너뜀] $($file.Name) — 이미 날짜 포함" -ForegroundColor Yellow
        continue
    }

    $datePrefix  = $file.CreationTime.ToString("yyyyMMdd")
    $newName     = "${datePrefix}_$($file.Name)"
    $destination = Join-Path $TargetPath $newName

    if ($DryRun) {
        Write-Host "[미리보기] $($file.Name) → $newName" -ForegroundColor Cyan
    } else {
        Rename-Item -LiteralPath $file.FullName -NewName $newName
        Write-Host "[완료] $($file.Name) → $newName" -ForegroundColor Green
    }
    $count++
}

$mode = if ($DryRun) { "미리보기" } else { "실제 변경" }
Write-Host "`n[$mode 완료] 처리 파일 수: $count 개" -ForegroundColor White
```

**실행 방법**:

1. 스크립트를 `rename-with-date.ps1`로 저장합니다.
2. VS Code 터미널에서:
   ```powershell
   # 먼저 미리보기 실행 ($DryRun = $true 상태에서)
   .\rename-with-date.ps1

   # 결과 확인 후 스크립트에서 $DryRun = $false 로 변경
   # 다시 실행
   .\rename-with-date.ps1
   ```

---

### 스크립트 2. 확장자별 폴더 분류

**상황**: 다운로드 폴더에 이미지, 문서, 영상이 뒤섞여 있다.

**프롬프트**:

```
Windows PowerShell 스크립트 작성.

목적: C:\Downloads 폴더의 파일을 확장자별 하위 폴더로 이동
분류 규칙:
- 이미지 (jpg, jpeg, png, gif, bmp, webp) → Images 하위 폴더
- 문서 (pdf, docx, doc, xlsx, xls, pptx, ppt, txt) → Documents 하위 폴더
- 영상 (mp4, mov, avi, mkv) → Videos 하위 폴더
- 압축 (zip, rar, 7z) → Archives 하위 폴더
- 나머지 → Others 하위 폴더

예외:
- 대상 폴더가 없으면 자동 생성
- 같은 이름 파일이 있으면 번호 붙이기 (예: 파일(1).pdf)
- 폴더는 이동하지 않음 (파일만)

추가: $DryRun 변수, 상단 주석, 분류별 처리 수 요약 출력
```

---

### 스크립트 3. 오래된 파일 보관

**상황**: 3개월 이상 된 파일들을 별도 보관 폴더로 정기적으로 이동하고 싶다.

**프롬프트**:

```
Windows PowerShell 스크립트 작성.

목적: C:\Documents\Working 폴더에서 90일 이상 수정이 없는 파일을 C:\Documents\Archive 폴더로 이동
날짜 기준: 파일 최종 수정일
이동 후 원본 삭제 (이동이므로 원본은 없어짐)
보관 폴더 구조: C:\Documents\Archive\YYYY-MM\ (이동 월 기준 하위 폴더 자동 생성)
로그 파일: C:\Documents\archive-log.txt 에 이동 파일 목록 + 날짜 기록 (append)

추가: $DryRun 변수, $DaysThreshold 변수 (기본값 90), 상단 사용법 주석
```

---

### 스크립트 4. 폴더 백업 스크립트

**상황**: 매일 중요 폴더를 백업하고 싶다. 날짜별로 보관하고 오래된 백업은 자동 삭제.

**프롬프트**:

```
Windows PowerShell 스크립트 작성.

목적: 원본 폴더를 백업 폴더에 날짜 이름으로 복사
원본: C:\Documents\Important
백업 대상: D:\Backups\Important_YYYYMMDD 형식으로 폴더 생성
중복 방지: 오늘 날짜 백업이 이미 있으면 건너뜀
오래된 백업 정리: 30일 이상 된 백업 폴더 자동 삭제 (삭제 전 목록 출력)
완료 메시지: 백업 폴더 경로와 파일 수 출력

추가: $KeepDays 변수 (기본값 30), 상단 사용법 주석
```

---

### 스크립트 5. 파일 목록 CSV 추출

**상황**: 특정 폴더의 파일 목록을 엑셀에서 쓸 수 있는 CSV로 만들고 싶다.

**프롬프트**:

```
Windows PowerShell 스크립트 작성.

목적: C:\Documents\Contracts 폴더의 파일 목록을 CSV로 내보내기
포함 열: 파일명, 확장자, 크기(KB), 생성일, 수정일, 전체 경로
하위 폴더도 포함 (-Recurse)
출력 파일: C:\Documents\file-list-YYYYMMDD.csv (날짜 자동 포함)
인코딩: UTF-8 BOM (엑셀에서 한글 깨짐 방지)

추가: 상단 사용법 주석, 완료 후 파일 경로 출력
```

---

## 7.5 실행 권한 문제 해결

PowerShell 스크립트를 처음 실행하면 이런 오류가 날 수 있습니다:

```
이 시스템에서 스크립트 실행이 비활성화되어 있으므로
파일 C:\...\script.ps1을 로드할 수 없습니다.
```

이는 Windows 보안 설정 때문입니다. 아래 방법으로 해결합니다.

**방법 1. 현재 사용자만 허용 (권장)**:

```powershell
# VS Code 터미널에서 관리자 권한 없이 실행
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

프롬프트가 나오면 `Y` 입력.

**방법 2. 스크립트 우클릭 실행 허용**:

파일 탐색기에서 `.ps1` 파일 우클릭 > 속성 > 하단 "차단 해제" 체크 > 확인.

**IT 팀에 문의하는 경우**: 회사 보안 정책으로 PowerShell 스크립트 실행이 막혀 있을 수 있습니다. IT 팀에 "CurrentUser 범위로 RemoteSigned 설정 허용 요청"을 하면 됩니다.

---

## 7.6 Copilot으로 스크립트 디버깅

스크립트가 오류를 낼 때 Copilot에 오류 메시지를 그대로 붙여넣으면 됩니다.

```
아래 PowerShell 스크립트 실행 중 오류가 발생함.

오류 메시지:
[오류 전체 붙여넣기]

스크립트:
[스크립트 붙여넣기]

원인 분석과 수정된 스크립트를 알려줘.
```

Copilot이 수정한 버전을 바로 줍니다.

---

## 7.7 macOS 대안 — zsh / bash

macOS 사용자는 PowerShell 대신 터미널(Terminal.app)에서 zsh를 씁니다. 기본 개념은 같습니다.

### 동일 목적의 zsh 명령어 비교

| 작업 | PowerShell | zsh (macOS) |
|------|-----------|-------------|
| 파일 목록 | `Get-ChildItem` | `ls -la` |
| 파일 이동 | `Move-Item` | `mv` |
| 파일 복사 | `Copy-Item` | `cp -r` |
| 파일 이름 변경 | `Rename-Item` | `mv 원본 새이름` |
| 폴더 생성 | `New-Item -ItemType Directory` | `mkdir` |

### macOS 사용자 Copilot 프롬프트

Windows PowerShell 대신 이렇게 요청합니다:

```
macOS zsh 셸 스크립트 작성.

목적: ~/Downloads 폴더의 파일을 확장자별 하위 폴더로 이동
(동일 조건...)

추가: DRY_RUN=true 변수, 상단 주석 포함
```

---

## 실습 — 다운로드 폴더 자동 정리 스크립트

### 실습 시나리오

여러분의 `C:\Downloads` (또는 `~/Downloads`) 폴더는 아마 지금 이런 상태일 것입니다.

```
Downloads/
├── 보고서_최종.pdf
├── 보고서_최종_v2.pdf
├── 회의사진.jpg
├── 설치파일.exe
├── 계약서.docx
├── 발표자료.pptx
├── 동영상_회의녹화.mp4
├── setup_something.zip
└── ... (수백 개)
```

이 스크립트 하나로 5초 만에 깔끔하게 정리합니다.

### Step 1. 스크립트 요청

아래 프롬프트를 Chat에 입력합니다:

```
Windows PowerShell 스크립트 작성.

목적: 다운로드 폴더 자동 정리
대상: C:\Downloads 폴더 (하위 폴더 제외, 루트 파일만)

분류 규칙:
- PDF 문서 → C:\Downloads\PDFs
- Word/Excel/PPT 문서 → C:\Downloads\Documents
- 이미지 (jpg, png, gif, bmp, webp) → C:\Downloads\Images
- 영상 (mp4, mov, avi, mkv) → C:\Downloads\Videos
- 압축 파일 (zip, rar, 7z) → C:\Downloads\Archives
- 설치 파일 (exe, msi, dmg) → C:\Downloads\Installers
- 나머지 → C:\Downloads\Others

예외 처리:
- 없는 폴더는 자동 생성
- 같은 이름 파일 충돌 시 파일명에 타임스탬프 추가 (예: 파일_20260720_143022.pdf)
- .ps1, .bat 같은 스크립트 파일은 이동하지 않음

출력:
- 각 파일 이동 내역 실시간 표시
- 마지막에 분류별 이동 수 요약 표 출력

추가:
- $DryRun = $true (미리보기/실행 전환)
- 스크립트 상단에 사용법 주석 5줄
- 각 중요 블록에 한국어 주석
```

### Step 2. 스크립트 저장 + 검토

생성된 스크립트를 `organize-downloads.ps1`으로 저장합니다.

저장 전 확인 사항:
- [ ] `$DryRun = $true`가 스크립트 상단에 있는가?
- [ ] 폴더 경로가 내 환경과 맞는가?
- [ ] 삭제 명령(`Remove-Item`)이 없는가? (이동만 해야 함)

### Step 3. 미리보기 실행

```powershell
# VS Code 터미널에서
.\organize-downloads.ps1
```

출력된 내용을 보면서 의도치 않은 파일이 이동되는지 확인합니다.

### Step 4. 실제 실행

스크립트를 열어 `$DryRun = $false`로 변경 후 다시 실행합니다.

### Step 5. 결과 확인

`C:\Downloads` 폴더를 열어 하위 폴더로 파일이 잘 분류됐는지 확인합니다.

---

## 핵심 포인트

1. **스크립트를 외울 필요 없다** — 상황을 설명하면 Copilot이 만들어준다
2. **항상 Dry-run 먼저** — `$DryRun = $true` 로 실행해서 결과 확인 후 실제 실행
3. **실행 권한 오류**: `Set-ExecutionPolicy RemoteSigned -Scope CurrentUser` 한 번만 실행
4. **오류 나면 오류 메시지 그대로 Copilot에 붙여넣기** — 바로 수정해준다
5. macOS 사용자는 같은 프롬프트에 "zsh 스크립트"라고 명시하면 됨

---

**다음**: [08-capstone.md](./08-capstone.md) — 캡스톤 프로젝트
