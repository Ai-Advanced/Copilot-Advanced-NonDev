# 03. VBA 매크로 기초 + Copilot 자동 생성

## 학습 목표

- VBA의 기본 구조와 재무 업무에서 활용하는 핵심 패턴 이해
- Copilot으로 VBA 코드를 생성하고 수정하는 방법 습득
- 반복 자동화 (파일 순회, 시트 복사, PDF 저장), 오류 핸들링 실전 적용
- 실습: 월별 리포트 시트 자동 생성 + PDF 저장 매크로

**예상 소요**: 60분 (실습 포함)

---

## 3.1 재무팀이 VBA를 써야 하는 이유

엑셀 수식은 **셀 단위 계산**에 강하지만, 다음 작업은 수식으로 불가능합니다:

| 작업 | 수식 | VBA |
|------|------|-----|
| 시트 자동 생성/복사/삭제 | 불가 | 가능 |
| 파일 열기/저장/PDF 변환 | 불가 | 가능 |
| 외부 파일 100개 순회 | 불가 | 가능 |
| 조건에 따라 셀 서식 적용 | 조건부서식 | 더 유연하게 |
| Outlook으로 이메일 발송 | 불가 | 가능 |
| 폼/대화상자 제어 | 불가 | 가능 |

재무팀에서 VBA가 가장 빛나는 순간은 **월 결산 반복 업무**입니다.
"20개 파일을 열어서 특정 시트 데이터를 복사하고 저장하고 닫기"를 수동으로 하면 2시간이지만, VBA로는 3분입니다.

---

## 3.2 VBA 기본 구조

### 매크로 편집기 열기

- `Alt + F11` → VBA 편집기 실행
- 왼쪽 프로젝트 창에서 `ThisWorkbook` 또는 `Module1` 선택
- 없으면: 삽입 > 모듈

### 기본 구조

```vba
Sub 매크로이름()
    ' 작업 내용
End Sub

Function 함수이름(인수 As 타입) As 반환타입
    ' 계산 후 반환
    함수이름 = 결과값
End Function
```

### 재무 VBA에서 자주 쓰는 패턴

```vba
' 마지막 데이터 행 찾기 (A열 기준)
Dim lastRow As Long
lastRow = Cells(Rows.Count, 1).End(xlUp).Row

' 특정 시트 참조
Dim ws As Worksheet
Set ws = Worksheets("매출원장")

' 셀 값 읽기/쓰기
Dim val As Double
val = ws.Cells(2, 4).Value       ' D2 셀
ws.Range("E2").Value = val * 1.1

' 범위 순회
Dim i As Long
For i = 2 To lastRow
    If Cells(i, 2).Value = "4000" Then
        Cells(i, 5).Interior.Color = RGB(198, 239, 206)  ' 연두색
    End If
Next i
```

---

## 3.3 Copilot으로 VBA 생성하기

VBA를 전혀 모르더라도 Copilot에게 "무엇을 자동화할지"를 설명하면 완성 코드를 받을 수 있습니다.

### VBA 프롬프트의 3요소

```
1. 목적: 무엇을 자동화하는가
2. 동작 순서: 1단계, 2단계, 3단계...
3. 예외 처리: 오류 발생 시 어떻게 할 것인가
```

### 좋은 VBA 프롬프트 예시

```
Excel VBA 매크로 작성.

목적: 월별 리포트 시트 12개 자동 생성

동작:
1. "양식" 시트를 복사
2. 복사된 시트 이름을 "2026-01", "2026-02", ..., "2026-12" 형식으로 설정
3. 이미 해당 이름의 시트가 있으면 건너뜀
4. 생성된 시트들을 "양식" 시트 뒤에 순서대로 배치
5. 완료 후 MsgBox로 생성된 시트 수 표시

오류 처리:
- "양식" 시트가 없으면 경고 메시지 후 종료
- 각 시트 생성 오류는 무시하고 계속 진행

전체 완성 코드. 주석 포함.
```

### Copilot 생성 결과 예시

```vba
Sub CreateMonthlySheets()
    '====================================================
    ' 목적: 양식 시트를 복사해 2026-01 ~ 2026-12 시트 생성
    ' 작성: GitHub Copilot
    ' 검증 필요: 시트명, 순서 배치 확인
    '====================================================

    Dim ws As Worksheet
    Dim templateSheet As Worksheet
    Dim sheetName As String
    Dim month As Integer
    Dim createdCount As Integer
    Dim skippedCount As Integer

    ' 양식 시트 존재 여부 확인
    On Error Resume Next
    Set templateSheet = Worksheets("양식")
    On Error GoTo 0

    If templateSheet Is Nothing Then
        MsgBox "오류: '양식' 시트를 찾을 수 없습니다.", vbCritical
        Exit Sub
    End If

    createdCount = 0
    skippedCount = 0

    Application.ScreenUpdating = False  ' 화면 깜빡임 방지

    For month = 1 To 12
        sheetName = "2026-" & Format(month, "00")

        ' 이미 존재하는지 확인
        Dim sheetExists As Boolean
        sheetExists = False
        For Each ws In Worksheets
            If ws.Name = sheetName Then
                sheetExists = True
                Exit For
            End If
        Next ws

        If sheetExists Then
            skippedCount = skippedCount + 1
        Else
            ' 양식 시트 복사 후 이름 설정
            On Error Resume Next
            templateSheet.Copy After:=Worksheets(Worksheets.Count)
            ActiveSheet.Name = sheetName
            On Error GoTo 0
            createdCount = createdCount + 1
        End If
    Next month

    Application.ScreenUpdating = True

    MsgBox "완료: " & createdCount & "개 시트 생성, " & _
           skippedCount & "개 시트 건너뜀.", vbInformation

End Sub
```

### 생성된 코드 검증 포인트

Copilot이 생성한 VBA를 받았을 때 반드시 확인할 사항:

1. **`On Error Resume Next` 범위**: 오류를 무시하는 범위가 너무 넓으면 실수를 숨깁니다. 좁은 범위로 한정하세요.
2. **`Application.ScreenUpdating = False` 쌍 확인**: 켜는 코드 없이 끄기만 하면 엑셀이 멈춘 것처럼 보입니다.
3. **마지막 행 계산 방식**: `Cells(Rows.Count, 1).End(xlUp).Row` 방식이 안전합니다. `UsedRange.Rows.Count`는 빈 행 포함 가능.
4. **메시지 박스 없이 자동 실행**: 운영 환경에서는 MsgBox 대신 로그 파일 기록 방식으로 변경 권장.

---

## 3.4 반복 자동화 패턴

### 패턴 1. 여러 파일 처리 (재무팀 핵심)

```vba
Sub ProcessAllFiles()
    '======================================================
    ' 목적: 지정 폴더의 모든 .xlsx 파일에서 데이터 통합
    '======================================================

    Dim folderPath As String
    Dim fileName As String
    Dim srcWb As Workbook
    Dim srcWs As Worksheet
    Dim destWs As Worksheet
    Dim destLastRow As Long
    Dim srcLastRow As Long
    Dim processedCount As Integer

    ' 폴더 선택 다이얼로그
    With Application.FileDialog(msoFileDialogFolderPicker)
        .Title = "데이터 파일 폴더 선택"
        If .Show = False Then Exit Sub
        folderPath = .SelectedItems(1) & "\"
    End With

    ' 통합 시트 설정
    Set destWs = ThisWorkbook.Worksheets("통합")
    destWs.Cells.Clear  ' 기존 데이터 삭제

    ' 헤더는 첫 파일에서 가져올 예정
    Dim isFirstFile As Boolean
    isFirstFile = True
    processedCount = 0

    Application.ScreenUpdating = False
    Application.Calculation = xlCalculationManual  ' 계산 일시 중지

    fileName = Dir(folderPath & "*.xlsx")

    Do While fileName <> ""
        ' 현재 파일 열기
        Set srcWb = Workbooks.Open(folderPath & fileName, ReadOnly:=True)

        On Error Resume Next
        Set srcWs = srcWb.Worksheets("Data")
        On Error GoTo 0

        If Not srcWs Is Nothing Then
            srcLastRow = srcWs.Cells(srcWs.Rows.Count, 1).End(xlUp).Row
            destLastRow = destWs.Cells(destWs.Rows.Count, 1).End(xlUp).Row

            If isFirstFile Then
                ' 첫 파일: 헤더 포함해서 복사
                srcWs.Range("A1:E" & srcLastRow).Copy destWs.Range("A1")
                isFirstFile = False
            Else
                ' 이후 파일: 헤더 제외 (2행부터)
                If srcLastRow >= 2 Then
                    srcWs.Range("A2:E" & srcLastRow).Copy _
                        destWs.Range("A" & (destLastRow + 1))
                End If
            End If

            ' 출처 파일명 F열에 기록
            Dim startRow As Long
            startRow = destWs.Cells(destWs.Rows.Count, 1).End(xlUp).Row - (srcLastRow - 2)
            If startRow < 2 Then startRow = 2
            destWs.Range("F" & startRow & ":F" & _
                (startRow + srcLastRow - 2)).Value = fileName

            processedCount = processedCount + 1
        End If

        srcWb.Close SaveChanges:=False
        Set srcWs = Nothing
        Set srcWb = Nothing

        fileName = Dir()
    Loop

    Application.Calculation = xlCalculationAutomatic
    Application.ScreenUpdating = True

    MsgBox processedCount & "개 파일 통합 완료." & Chr(13) & _
           "총 " & destWs.Cells(destWs.Rows.Count, 1).End(xlUp).Row - 1 & _
           "행 데이터.", vbInformation

End Sub
```

### 패턴 2. 조건부 행 색상 표시

```vba
Sub HighlightAnomalies()
    '======================================================
    ' 목적: 재무 데이터 이상치 행 색상 표시
    '======================================================

    Dim ws As Worksheet
    Dim lastRow As Long
    Dim i As Long
    Dim amount As Double

    Set ws = ActiveSheet
    lastRow = ws.Cells(ws.Rows.Count, 4).End(xlUp).Row  ' D열 기준

    ' 기존 배경색 초기화
    ws.Range("A2:F" & lastRow).Interior.ColorIndex = xlNone

    For i = 2 To lastRow
        ' D열 = 금액
        If IsNumeric(ws.Cells(i, 4).Value) Then
            amount = ws.Cells(i, 4).Value

            ' 음수 금액 (비정상)
            If amount < 0 Then
                ws.Range("A" & i & ":F" & i).Interior.Color = RGB(255, 199, 206)  ' 빨강

            ' 1억 초과 대형 거래
            ElseIf amount > 100000000 Then
                ws.Range("A" & i & ":F" & i).Interior.Color = RGB(255, 235, 156)  ' 노랑

            ' 0원 거래 (의심)
            ElseIf amount = 0 Then
                ws.Range("A" & i & ":F" & i).Interior.Color = RGB(221, 221, 221)  ' 회색
            End If
        Else
            ' 숫자 아닌 금액 (오류)
            ws.Range("D" & i).Interior.Color = RGB(255, 102, 0)  ' 주황
        End If
    Next i

    MsgBox "검사 완료. 이상 항목을 확인하세요.", vbInformation

End Sub
```

### 패턴 3. 셀 순회와 데이터 정제

```vba
Sub CleanFinanceData()
    '======================================================
    ' 목적: 재무 원장 데이터 정제 (공백 제거, 숫자 변환)
    '======================================================

    Dim ws As Worksheet
    Dim lastRow As Long
    Dim i As Long
    Dim cleanedCount As Long

    Set ws = ActiveSheet
    lastRow = ws.Cells(ws.Rows.Count, 1).End(xlUp).Row
    cleanedCount = 0

    Application.ScreenUpdating = False

    For i = 2 To lastRow
        ' A열: 날짜 정제 (텍스트 형식 날짜 → 날짜)
        If Not IsDate(ws.Cells(i, 1).Value) Then
            Dim rawDate As String
            rawDate = Trim(CStr(ws.Cells(i, 1).Value))
            If IsDate(rawDate) Then
                ws.Cells(i, 1).Value = CDate(rawDate)
                ws.Cells(i, 1).NumberFormat = "YYYY-MM-DD"
                cleanedCount = cleanedCount + 1
            End If
        End If

        ' B열: 계정코드 앞뒤 공백 제거
        If VarType(ws.Cells(i, 2).Value) = vbString Then
            Dim originalCode As String
            originalCode = ws.Cells(i, 2).Value
            ws.Cells(i, 2).Value = Trim(originalCode)
            If ws.Cells(i, 2).Value <> originalCode Then
                cleanedCount = cleanedCount + 1
            End If
        End If

        ' D열: 텍스트 숫자 → 숫자 변환
        If VarType(ws.Cells(i, 4).Value) = vbString Then
            Dim rawNum As String
            rawNum = Replace(Trim(ws.Cells(i, 4).Value), ",", "")
            If IsNumeric(rawNum) Then
                ws.Cells(i, 4).Value = CDbl(rawNum)
                cleanedCount = cleanedCount + 1
            End If
        End If
    Next i

    Application.ScreenUpdating = True
    MsgBox cleanedCount & "개 셀 정제 완료.", vbInformation

End Sub
```

---

## 3.5 PDF 저장 자동화

월 결산 리포트를 PDF로 저장하고 파일명에 날짜를 자동으로 포함하는 패턴입니다.

```vba
Sub SaveReportsToPDF()
    '======================================================
    ' 목적: Report_ 로 시작하는 시트를 각각 PDF로 저장
    '======================================================

    Dim ws As Worksheet
    Dim pdfPath As String
    Dim baseFolder As String
    Dim savedCount As Integer
    Dim errorLog As String
    Dim dateStr As String

    baseFolder = "C:\Reports\"
    dateStr = Format(Now(), "YYYYMMDD")
    savedCount = 0
    errorLog = ""

    ' 저장 폴더 없으면 생성
    If Dir(baseFolder, vbDirectory) = "" Then
        MkDir baseFolder
    End If

    Application.ScreenUpdating = False

    For Each ws In ThisWorkbook.Worksheets
        If Left(ws.Name, 7) = "Report_" Then
            pdfPath = baseFolder & dateStr & "_" & ws.Name & ".pdf"

            On Error Resume Next
            ws.ExportAsFixedFormat _
                Type:=xlTypePDF, _
                Filename:=pdfPath, _
                Quality:=xlQualityStandard, _
                IncludeDocProperties:=True, _
                IgnorePrintAreas:=False, _
                OpenAfterPublish:=False

            If Err.Number <> 0 Then
                errorLog = errorLog & ws.Name & ": " & Err.Description & Chr(13)
                Err.Clear
            Else
                savedCount = savedCount + 1
            End If
            On Error GoTo 0
        End If
    Next ws

    Application.ScreenUpdating = True

    Dim msg As String
    msg = savedCount & "개 PDF 저장 완료." & Chr(13) & _
          "저장 위치: " & baseFolder
    If errorLog <> "" Then
        msg = msg & Chr(13) & Chr(13) & "오류 발생:" & Chr(13) & errorLog
    End If

    MsgBox msg, vbInformation

End Sub
```

---

## 3.6 오류 핸들링

VBA 오류 처리는 재무 자동화에서 특히 중요합니다. 오류가 발생해도 **어디서 무슨 오류가 났는지** 파악해야 합니다.

### 3가지 오류 처리 방식

**방식 1. On Error GoTo (권장 - 구조적)**
```vba
Sub ProcessData()
    On Error GoTo ErrorHandler

    ' 작업 내용
    Dim ws As Worksheet
    Set ws = Worksheets("원장")
    ' ... 처리 ...

    Exit Sub  ' 정상 종료 시 오류 핸들러 건너뜀

ErrorHandler:
    MsgBox "오류 발생:" & Chr(13) & _
           "오류 번호: " & Err.Number & Chr(13) & _
           "오류 내용: " & Err.Description, vbCritical
    ' 필요 시 정리 작업
    Application.ScreenUpdating = True
    Application.Calculation = xlCalculationAutomatic
End Sub
```

**방식 2. On Error Resume Next (좁은 범위로 한정)**
```vba
' 시트 존재 여부 확인에만 사용
Dim targetWs As Worksheet
On Error Resume Next
Set targetWs = Worksheets("원장")
On Error GoTo 0  ' 즉시 오류 처리 재활성화

If targetWs Is Nothing Then
    MsgBox "'원장' 시트를 찾을 수 없습니다."
    Exit Sub
End If
```

**방식 3. 오류 로그 시트 기록**
```vba
Sub LogError(sheetName As String, errMsg As String)
    Dim logWs As Worksheet
    Dim logRow As Long

    On Error Resume Next
    Set logWs = Worksheets("오류로그")
    On Error GoTo 0

    If logWs Is Nothing Then
        Set logWs = Worksheets.Add
        logWs.Name = "오류로그"
        logWs.Range("A1:C1").Value = Array("발생시각", "시트명", "오류내용")
    End If

    logRow = logWs.Cells(logWs.Rows.Count, 1).End(xlUp).Row + 1
    logWs.Cells(logRow, 1).Value = Now()
    logWs.Cells(logRow, 2).Value = sheetName
    logWs.Cells(logRow, 3).Value = errMsg
End Sub
```

---

## 3.7 Copilot으로 기존 VBA 리팩토링

기존의 지저분한 VBA 코드도 Copilot으로 정리할 수 있습니다.

**프롬프트 패턴**:
```
아래 VBA 코드를 리팩토링해줘.

개선 목표:
1. On Error GoTo 구조적 오류 핸들링으로 변경
2. 하드코딩된 숫자(행 번호 등)를 변수/마지막 행 자동 감지로 교체
3. 반복 코드를 Sub 프로시저로 분리
4. Application.ScreenUpdating / Calculation 최적화 추가
5. 각 주요 블록에 한 줄 주석 추가
6. 매직 넘버(RGB 색상 값 등)를 Const 상수로 선언

[기존 코드 붙여넣기]
```

### Copilot이 VBA에서 자주 만드는 실수

1. **`ActiveSheet` 과도 사용**: 현재 활성 시트가 바뀌면 오작동. 항상 명시적으로 시트를 지정하세요.
   ```vba
   ' 나쁜 예
   ActiveSheet.Cells(1,1).Value = "test"

   ' 좋은 예
   Worksheets("원장").Cells(1,1).Value = "test"
   ```

2. **범위 선택 후 처리**: `.Select`는 느립니다. 직접 처리하세요.
   ```vba
   ' 나쁜 예 (Copilot이 종종 생성)
   Range("A2:D100").Select
   Selection.Copy

   ' 좋은 예
   Range("A2:D100").Copy Destination:=Worksheets("통합").Range("A2")
   ```

3. **Variant 타입 기본 사용**: 정확한 타입 선언 없이 Variant를 쓰면 느리고 오류 유발.
   ```vba
   ' 나쁜 예
   Dim x
   Dim i

   ' 좋은 예
   Dim amount As Double
   Dim i As Long
   ```

---

## 3.8 실습: 월별 리포트 자동 생성 매크로

### 실습 목표

"양식" 시트를 기반으로 2026년 1~12월 시트를 자동 생성하고,
각 시트의 B1 셀에 해당 월의 첫날을, B2 셀에 마지막 날을 자동으로 입력하는 매크로를 완성합니다.

### Step 1. 양식 시트 준비

새 Excel 파일을 열고 Sheet1의 이름을 "양식"으로 변경합니다.
양식 시트에 아래 내용을 입력합니다:

```
A1: 월간 재무 리포트
B1: [시작일]
B2: [종료일]
A4: 계정과목
B4: 예산
C4: 실적
D4: 편차
E4: 달성률
```

### Step 2. Copilot에 매크로 요청

VS Code에서 새 `.bas` 파일을 열고 아래 프롬프트를 Chat에 입력합니다:

```
Excel VBA 매크로 작성.

목적: 양식 시트를 복사해 2026년 월별 리포트 시트 12개 생성

동작 순서:
1. "양식" 시트 존재 확인 (없으면 오류 메시지 후 종료)
2. 1월~12월 순회:
   a. 시트명 "2026-MM" 형식 (예: 2026-01)
   b. 이미 존재하면 건너뜀
   c. "양식" 시트를 복사해 마지막 위치에 붙이고 이름 설정
   d. 복사된 시트의 B1 = 해당 월의 첫날 (날짜 형식 YYYY-MM-DD)
   e. 복사된 시트의 B2 = 해당 월의 마지막 날
3. 모든 생성 완료 후 "N개 시트 생성" MsgBox

최적화:
- Application.ScreenUpdating = False
- On Error GoTo 구조 사용
- 주석 포함
```

### Step 3. 결과 검증

생성된 코드를 VBA 편집기에 붙여넣고 실행 후 확인:

- [ ] 12개 시트가 "2026-01"~"2026-12" 이름으로 생성됨
- [ ] 각 시트 B1에 해당 월 첫날, B2에 마지막 날이 올바르게 입력됨
- [ ] 2026-02의 마지막 날이 2026-02-28 인지 확인
- [ ] 매크로를 다시 실행해도 중복 오류가 발생하지 않는지 확인

### Step 4. PDF 저장 추가 (선택)

위 매크로에 이어서 PDF 자동 저장 코드를 추가하도록 Copilot에 요청합니다:

```
위 매크로에 기능 추가:

완료 후 모든 "2026-" 시트를 PDF로 저장.
저장 경로: C:\MonthlyReports\
파일명: YYYYMMDD_2026-MM.pdf
저장 후 탐색기로 해당 폴더 열기 (Shell 명령 또는 직접 방법)
```

---

## 핵심 포인트

1. **VBA의 강점**: 파일 순회, 시트 생성, PDF 저장 등 수식으로 불가능한 작업
2. **Copilot VBA 프롬프트**: 목적 + 동작 순서 + 예외 처리 = 완성도 높은 코드
3. **생성된 코드 3대 체크**: `On Error Resume Next` 범위 / `ScreenUpdating` 쌍 / 명시적 시트 참조
4. **`ActiveSheet` 금지**: 항상 `Worksheets("이름")`으로 명시
5. **직접 처리가 빠르다**: `.Select` → `.Copy Destination:=` 방식으로 변경

---

**다음**: [04-day1-lab.md](./04-day1-lab.md) — Day 1 종합 실습
