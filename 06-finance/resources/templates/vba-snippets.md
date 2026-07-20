# 재무 실무 VBA 스니펫 모음

> 이 파일의 각 스니펫을 Excel VBA 편집기 (`Alt+F11` → 모듈)에 붙여넣어 바로 사용합니다.
> 각 Sub/Function 위에 있는 설명을 읽고 사내 환경에 맞게 경로/시트명/계정코드를 수정하세요.

---

## 목차

1. [파일 순회 및 데이터 통합](#1-파일-순회-및-데이터-통합)
2. [시트 복사 및 관리](#2-시트-복사-및-관리)
3. [PDF 저장 자동화](#3-pdf-저장-자동화)
4. [이메일 발송 (Outlook)](#4-이메일-발송-outlook)
5. [조건부 서식 자동 적용](#5-조건부-서식-자동-적용)
6. [데이터 정제 유틸리티](#6-데이터-정제-유틸리티)
7. [유틸리티 함수](#7-유틸리티-함수)

---

## 1. 파일 순회 및 데이터 통합

### 스니펫 01. 폴더 내 모든 xlsx 파일 통합

```vba
'====================================================
' 스니펫 01: 폴더 내 .xlsx 파일 통합
' 사용법: 실행 전 통합 대상 폴더를 선택 다이얼로그로 지정
' 조건: 각 파일에 "Data" 시트가 있어야 함
' 출력: 현재 파일의 "통합" 시트
'====================================================
Sub MergeAllXlsxFiles()

    Const SOURCE_SHEET As String = "Data"
    Const DEST_SHEET   As String = "통합"
    Const DATA_COLS    As String = "A:E"

    Dim folderPath    As String
    Dim fileName      As String
    Dim srcWb         As Workbook
    Dim srcWs         As Worksheet
    Dim destWs        As Worksheet
    Dim destLastRow   As Long
    Dim srcLastRow    As Long
    Dim isFirstFile   As Boolean
    Dim processedCnt  As Integer
    Dim skippedCnt    As Integer

    ' 폴더 선택
    With Application.FileDialog(msoFileDialogFolderPicker)
        .Title = "통합할 파일이 있는 폴더 선택"
        If .Show = False Then Exit Sub
        folderPath = .SelectedItems(1) & "\"
    End With

    ' 대상 시트 확인 또는 생성
    On Error Resume Next
    Set destWs = ThisWorkbook.Worksheets(DEST_SHEET)
    On Error GoTo 0
    If destWs Is Nothing Then
        Set destWs = ThisWorkbook.Worksheets.Add
        destWs.Name = DEST_SHEET
    Else
        destWs.Cells.Clear
    End If

    isFirstFile  = True
    processedCnt = 0
    skippedCnt   = 0

    Application.ScreenUpdating = False
    Application.Calculation    = xlCalculationManual

    fileName = Dir(folderPath & "*.xlsx")
    Do While fileName <> ""

        Set srcWb = Nothing
        Set srcWs = Nothing

        On Error Resume Next
        Set srcWb = Workbooks.Open(folderPath & fileName, ReadOnly:=True, UpdateLinks:=False)
        On Error GoTo 0

        If Not srcWb Is Nothing Then
            On Error Resume Next
            Set srcWs = srcWb.Worksheets(SOURCE_SHEET)
            On Error GoTo 0

            If Not srcWs Is Nothing Then
                srcLastRow  = srcWs.Cells(srcWs.Rows.Count, 1).End(xlUp).Row
                destLastRow = destWs.Cells(destWs.Rows.Count, 1).End(xlUp).Row

                If isFirstFile Then
                    ' 첫 파일: 헤더 포함 복사
                    srcWs.Range(DATA_COLS & "1:" & DATA_COLS & srcLastRow).Copy _
                        destWs.Range("A1")
                    isFirstFile = False
                ElseIf srcLastRow >= 2 Then
                    ' 이후 파일: 헤더 제외
                    srcWs.Range(DATA_COLS & "2:" & DATA_COLS & srcLastRow).Copy _
                        destWs.Range("A" & (destLastRow + 1))
                End If

                ' 출처 파일명 F열 기록
                Dim writeRow As Long
                writeRow = destWs.Cells(destWs.Rows.Count, 1).End(xlUp).Row
                Dim dataRows As Long
                dataRows = srcLastRow - IIf(isFirstFile, 1, 2) + 1
                If dataRows > 0 Then
                    destWs.Range("F" & (writeRow - dataRows + 1) & ":F" & writeRow).Value = fileName
                End If

                processedCnt = processedCnt + 1
            Else
                skippedCnt = skippedCnt + 1
            End If

            srcWb.Close SaveChanges:=False
        End If

        fileName = Dir()
    Loop

    Application.Calculation    = xlCalculationAutomatic
    Application.ScreenUpdating = True

    MsgBox "통합 완료:" & Chr(13) & _
           "처리: " & processedCnt & "개 파일" & Chr(13) & _
           "건너뜀: " & skippedCnt & "개 (Data 시트 없음)" & Chr(13) & _
           "총 " & destWs.Cells(destWs.Rows.Count, 1).End(xlUp).Row - 1 & "행", _
           vbInformation

End Sub
```

### 스니펫 02. 특정 열 값으로 파일 분류 저장

```vba
'====================================================
' 스니펫 02: 부서코드별로 행을 분리하여 각각 다른 파일로 저장
' 사용법: 활성 시트의 C열(부서코드)을 기준으로 분리
' 출력 위치: C:\Finance\ByDept\ (없으면 자동 생성)
'====================================================
Sub SplitByDeptCode()

    Const SPLIT_COL   As Integer = 3   ' C열 = 부서코드
    Const OUTPUT_DIR  As String  = "C:\Finance\ByDept\"
    Const MONTH_LABEL As String  = "202606"  ' 파일명에 포함할 연월

    Dim ws          As Worksheet
    Dim lastRow     As Long
    Dim deptCodes   As Collection
    Dim deptCode    As Variant
    Dim newWb       As Workbook
    Dim newWs       As Worksheet
    Dim i           As Long
    Dim destRow     As Long

    Set ws      = ActiveSheet
    lastRow     = ws.Cells(ws.Rows.Count, 1).End(xlUp).Row

    ' 출력 폴더 생성
    If Dir(OUTPUT_DIR, vbDirectory) = "" Then MkDir OUTPUT_DIR

    ' 고유 부서코드 수집
    Set deptCodes = New Collection
    On Error Resume Next
    For i = 2 To lastRow
        deptCodes.Add ws.Cells(i, SPLIT_COL).Value, CStr(ws.Cells(i, SPLIT_COL).Value)
    Next i
    On Error GoTo 0

    Application.ScreenUpdating = False

    ' 부서별 파일 생성
    For Each deptCode In deptCodes
        Set newWb = Workbooks.Add
        Set newWs = newWb.Sheets(1)
        newWs.Name = CStr(deptCode)

        ' 헤더 복사
        ws.Rows(1).Copy newWs.Rows(1)
        destRow = 2

        ' 해당 부서 행 복사
        For i = 2 To lastRow
            If CStr(ws.Cells(i, SPLIT_COL).Value) = CStr(deptCode) Then
                ws.Rows(i).Copy newWs.Rows(destRow)
                destRow = destRow + 1
            End If
        Next i

        ' 파일 저장
        Dim savePath As String
        savePath = OUTPUT_DIR & CStr(deptCode) & "_" & MONTH_LABEL & ".xlsx"
        newWb.SaveAs Filename:=savePath, FileFormat:=xlOpenXMLWorkbook
        newWb.Close SaveChanges:=False
    Next deptCode

    Application.ScreenUpdating = True
    MsgBox deptCodes.Count & "개 부서 파일 저장 완료." & Chr(13) & OUTPUT_DIR, vbInformation

End Sub
```

---

## 2. 시트 복사 및 관리

### 스니펫 03. 월별 시트 자동 생성

```vba
'====================================================
' 스니펫 03: 양식 시트를 복사해 월별 시트 12개 생성
' 사용법: "양식" 이름의 시트가 존재해야 함
' 연도 설정: YEAR_TARGET 상수 수정
'====================================================
Sub CreateMonthlySheets()

    Const TEMPLATE_SHEET As String  = "양식"
    Const YEAR_TARGET    As Integer = 2026

    Dim templateWs   As Worksheet
    Dim newWs        As Worksheet
    Dim sheetName    As String
    Dim m            As Integer
    Dim createdCnt   As Integer
    Dim skippedCnt   As Integer

    ' 양식 시트 확인
    On Error Resume Next
    Set templateWs = Worksheets(TEMPLATE_SHEET)
    On Error GoTo 0
    If templateWs Is Nothing Then
        MsgBox "'" & TEMPLATE_SHEET & "' 시트를 찾을 수 없습니다.", vbCritical
        Exit Sub
    End If

    createdCnt = 0
    skippedCnt = 0
    Application.ScreenUpdating = False

    For m = 1 To 12
        sheetName = CStr(YEAR_TARGET) & "-" & Format(m, "00")

        ' 이미 존재 여부 확인
        Dim exists As Boolean
        exists = False
        Dim ws As Worksheet
        For Each ws In Worksheets
            If ws.Name = sheetName Then exists = True: Exit For
        Next ws

        If exists Then
            skippedCnt = skippedCnt + 1
        Else
            templateWs.Copy After:=Worksheets(Worksheets.Count)
            ActiveSheet.Name = sheetName

            ' 시작일/종료일 자동 입력
            ActiveSheet.Range("B1").Value = DateSerial(YEAR_TARGET, m, 1)
            ActiveSheet.Range("B1").NumberFormat = "YYYY-MM-DD"
            ActiveSheet.Range("B2").Value = DateSerial(YEAR_TARGET, m + 1, 1) - 1
            ActiveSheet.Range("B2").NumberFormat = "YYYY-MM-DD"

            createdCnt = createdCnt + 1
        End If
    Next m

    Application.ScreenUpdating = True
    MsgBox "완료: " & createdCnt & "개 생성, " & skippedCnt & "개 건너뜀.", vbInformation

End Sub
```

### 스니펫 04. 특정 패턴 시트 일괄 삭제

```vba
'====================================================
' 스니펫 04: 이름이 특정 패턴으로 시작하는 시트 일괄 삭제
' 주의: 삭제 전 확인 메시지 표시
'====================================================
Sub DeleteSheetsByPattern()

    Const PATTERN As String = "Temp_"   ' 삭제할 시트 이름 접두어

    Dim ws          As Worksheet
    Dim deleteList  As Collection
    Dim sheetName   As Variant
    Dim deletedCnt  As Integer

    Set deleteList = New Collection

    ' 삭제 대상 수집
    For Each ws In Worksheets
        If Left(ws.Name, Len(PATTERN)) = PATTERN Then
            deleteList.Add ws.Name
        End If
    Next ws

    If deleteList.Count = 0 Then
        MsgBox "'" & PATTERN & "'로 시작하는 시트가 없습니다.", vbInformation
        Exit Sub
    End If

    ' 확인 메시지
    Dim confirmMsg As String
    confirmMsg = deleteList.Count & "개 시트를 삭제합니다. 계속할까요?" & Chr(13)
    For Each sheetName In deleteList
        confirmMsg = confirmMsg & " - " & sheetName & Chr(13)
    Next sheetName

    If MsgBox(confirmMsg, vbYesNo + vbExclamation, "시트 삭제 확인") = vbNo Then
        Exit Sub
    End If

    Application.DisplayAlerts = False
    deletedCnt = 0
    For Each sheetName In deleteList
        On Error Resume Next
        Worksheets(CStr(sheetName)).Delete
        If Err.Number = 0 Then deletedCnt = deletedCnt + 1
        Err.Clear
        On Error GoTo 0
    Next sheetName
    Application.DisplayAlerts = True

    MsgBox deletedCnt & "개 시트 삭제 완료.", vbInformation

End Sub
```

---

## 3. PDF 저장 자동화

### 스니펫 05. 특정 시트들 PDF 일괄 저장

```vba
'====================================================
' 스니펫 05: "Report_"로 시작하는 모든 시트를 PDF로 일괄 저장
' 출력 경로: C:\Reports\YYYYMMDD_시트명.pdf
' 오류 발생 시 오류로그 시트에 기록
'====================================================
Sub SaveReportsToPDF()

    Const PDF_FOLDER   As String = "C:\Reports\"
    Const SHEET_PREFIX As String = "Report_"

    Dim ws          As Worksheet
    Dim pdfPath     As String
    Dim dateStr     As String
    Dim savedCnt    As Integer
    Dim errLog      As String
    Dim logWs       As Worksheet

    dateStr  = Format(Now(), "YYYYMMDD")
    savedCnt = 0
    errLog   = ""

    ' 출력 폴더 생성
    If Dir(PDF_FOLDER, vbDirectory) = "" Then
        On Error Resume Next
        MkDir PDF_FOLDER
        On Error GoTo 0
    End If

    Application.ScreenUpdating = False

    For Each ws In ThisWorkbook.Worksheets
        If Left(ws.Name, Len(SHEET_PREFIX)) = SHEET_PREFIX Then
            pdfPath = PDF_FOLDER & dateStr & "_" & ws.Name & ".pdf"

            On Error Resume Next
            ws.ExportAsFixedFormat _
                Type:=xlTypePDF, _
                Filename:=pdfPath, _
                Quality:=xlQualityStandard, _
                IncludeDocProperties:=True, _
                IgnorePrintAreas:=False, _
                OpenAfterPublish:=False
            If Err.Number <> 0 Then
                errLog = errLog & ws.Name & ": " & Err.Description & Chr(13)
                Err.Clear
            Else
                savedCnt = savedCnt + 1
            End If
            On Error GoTo 0
        End If
    Next ws

    Application.ScreenUpdating = True

    Dim resultMsg As String
    resultMsg = savedCnt & "개 PDF 저장 완료." & Chr(13) & PDF_FOLDER
    If errLog <> "" Then
        resultMsg = resultMsg & Chr(13) & Chr(13) & "오류:" & Chr(13) & errLog
    End If
    MsgBox resultMsg, vbInformation

End Sub
```

### 스니펫 06. 단일 시트 PDF + 파일명 자동화

```vba
'====================================================
' 스니펫 06: 활성 시트를 오늘 날짜 포함 파일명으로 PDF 저장
' 사용법: 저장할 시트를 활성화한 후 실행
'====================================================
Sub SaveActiveToPDF()

    Const SAVE_FOLDER As String = "C:\Reports\"

    Dim pdfName As String
    Dim pdfPath As String

    pdfName = Format(Now(), "YYYYMMDD") & "_" & ActiveSheet.Name & ".pdf"
    pdfPath = SAVE_FOLDER & pdfName

    If Dir(SAVE_FOLDER, vbDirectory) = "" Then MkDir SAVE_FOLDER

    On Error GoTo ErrHandle
    ActiveSheet.ExportAsFixedFormat Type:=xlTypePDF, Filename:=pdfPath, _
        Quality:=xlQualityStandard, OpenAfterPublish:=False
    MsgBox "저장 완료: " & pdfPath, vbInformation
    Exit Sub

ErrHandle:
    MsgBox "PDF 저장 오류: " & Err.Description, vbCritical

End Sub
```

---

## 4. 이메일 발송 (Outlook)

### 스니펫 07. 활성 시트 PDF → Outlook 이메일

```vba
'====================================================
' 스니펫 07: 활성 시트를 PDF로 저장 후 Outlook으로 이메일 발송
' 수신자: B1 셀 값 (이메일 주소)
' 제목: B2 셀 값 (없으면 기본값 사용)
' 주의: Outlook이 설치/로그인된 환경 필요
'====================================================
Sub SendSheetAsPDF()

    Const TEMP_FOLDER As String = "C:\Temp\"

    Dim ws          As Worksheet
    Dim pdfPath     As String
    Dim recipient   As String
    Dim mailSubject As String
    Dim outApp      As Object
    Dim outMail     As Object

    Set ws = ActiveSheet
    recipient   = ws.Range("B1").Value
    mailSubject = ws.Range("B2").Value

    ' 기본값 처리
    If Trim(recipient) = "" Then
        MsgBox "B1 셀에 수신자 이메일 주소를 입력하세요.", vbExclamation
        Exit Sub
    End If
    If Trim(mailSubject) = "" Then
        mailSubject = "[재무팀] " & ws.Name & " - " & Format(Now(), "YYYY-MM")
    End If

    ' 임시 폴더 생성
    If Dir(TEMP_FOLDER, vbDirectory) = "" Then MkDir TEMP_FOLDER
    pdfPath = TEMP_FOLDER & "temp_report_" & Format(Now(), "YYYYMMDDHHmm") & ".pdf"

    ' PDF 저장
    On Error GoTo ErrHandle
    ws.ExportAsFixedFormat Type:=xlTypePDF, Filename:=pdfPath, OpenAfterPublish:=False

    ' Outlook 메일 구성
    Set outApp  = CreateObject("Outlook.Application")
    Set outMail = outApp.CreateItem(0)

    With outMail
        .To      = recipient
        .Subject = mailSubject
        .Body    = "안녕하세요," & Chr(13) & Chr(13) & _
                   ws.Name & " 리포트를 첨부드립니다." & Chr(13) & Chr(13) & _
                   "재무팀 드림"
        .Attachments.Add pdfPath
        .Display   ' .Send 로 변경하면 바로 발송
    End With

    MsgBox "이메일 창이 열렸습니다. 내용 확인 후 발송하세요.", vbInformation
    Exit Sub

ErrHandle:
    MsgBox "오류 발생: " & Err.Description, vbCritical

End Sub
```

### 스니펫 08. 수신자 목록에서 개별 이메일 발송

```vba
'====================================================
' 스니펫 08: "수신자" 시트의 목록을 순회하며 이메일 발송
' 수신자 시트 구조: A=이름, B=이메일, C=부서코드, D=발송여부
' 발송 후 D열에 "발송완료" 기록
'====================================================
Sub SendBulkEmails()

    Const RECIPIENTS_SHEET As String = "수신자"
    Const ATTACH_PATH      As String = "C:\Reports\monthly_report.pdf"

    Dim recipWs     As Worksheet
    Dim outApp      As Object
    Dim outMail     As Object
    Dim lastRow     As Long
    Dim i           As Long
    Dim sentCnt     As Integer

    ' 수신자 시트 확인
    On Error Resume Next
    Set recipWs = Worksheets(RECIPIENTS_SHEET)
    On Error GoTo 0
    If recipWs Is Nothing Then
        MsgBox "'" & RECIPIENTS_SHEET & "' 시트를 찾을 수 없습니다.", vbCritical
        Exit Sub
    End If

    ' 첨부 파일 확인
    If Dir(ATTACH_PATH) = "" Then
        MsgBox "첨부 파일을 찾을 수 없습니다: " & ATTACH_PATH, vbCritical
        Exit Sub
    End If

    lastRow = recipWs.Cells(recipWs.Rows.Count, 1).End(xlUp).Row
    sentCnt = 0

    Set outApp = CreateObject("Outlook.Application")

    For i = 2 To lastRow
        ' 이미 발송된 행 건너뜀
        If recipWs.Cells(i, 4).Value = "발송완료" Then GoTo NextRow

        Dim recipName  As String
        Dim recipEmail As String
        recipName  = recipWs.Cells(i, 1).Value
        recipEmail = recipWs.Cells(i, 2).Value

        If Trim(recipEmail) = "" Then GoTo NextRow

        Set outMail = outApp.CreateItem(0)
        With outMail
            .To      = recipEmail
            .Subject = "[재무팀] " & Format(Now(), "YYYY-MM") & " 월간 재무 리포트"
            .Body    = recipName & " 님, 안녕하세요." & Chr(13) & Chr(13) & _
                       "이번 달 재무 리포트를 첨부드립니다." & Chr(13) & _
                       "확인 후 문의 사항은 재무팀으로 연락 주세요." & Chr(13) & Chr(13) & _
                       "감사합니다." & Chr(13) & "재무팀 드림"
            .Attachments.Add ATTACH_PATH
            .Send
        End With

        recipWs.Cells(i, 4).Value = "발송완료"
        sentCnt = sentCnt + 1

NextRow:
    Next i

    MsgBox sentCnt & "명에게 이메일 발송 완료.", vbInformation

End Sub
```

---

## 5. 조건부 서식 자동 적용

### 스니펫 09. 예산 달성률 구간별 색상 적용

```vba
'====================================================
' 스니펫 09: 달성률 컬럼에 구간별 색상 자동 적용
' 적용 대상: 활성 시트의 E열 (달성률, %)
' 구간: < 80% 빨강 / 80~120% 정상 / > 120% 노랑
'====================================================
Sub ApplyAchievementColors()

    Const RATE_COL As Integer = 5  ' E열

    Dim ws        As Worksheet
    Dim lastRow   As Long
    Dim i         As Long
    Dim rateVal   As Double

    Set ws = ActiveSheet
    lastRow = ws.Cells(ws.Rows.Count, RATE_COL).End(xlUp).Row

    ' 기존 배경색 초기화 (E2부터)
    ws.Range(ws.Cells(2, RATE_COL), ws.Cells(lastRow, RATE_COL)).Interior.ColorIndex = xlNone

    For i = 2 To lastRow
        If IsNumeric(ws.Cells(i, RATE_COL).Value) Then
            rateVal = ws.Cells(i, RATE_COL).Value
            If rateVal < 80 Then
                ws.Cells(i, RATE_COL).Interior.Color = RGB(255, 199, 206)  ' 빨강 (미달)
            ElseIf rateVal > 120 Then
                ws.Cells(i, RATE_COL).Interior.Color = RGB(255, 235, 156)  ' 노랑 (초과)
            Else
                ws.Cells(i, RATE_COL).Interior.Color = RGB(198, 239, 206)  ' 초록 (정상)
            End If
        End If
    Next i

    MsgBox "색상 적용 완료. (빨강: 미달 / 초록: 정상 / 노랑: 초과)", vbInformation

End Sub
```

### 스니펫 10. 음수 금액 행 전체 강조

```vba
'====================================================
' 스니펫 10: 금액 컬럼(D열)이 음수인 행 전체를 빨간 배경으로 강조
' 재무 데이터에서 비정상 음수 잔액 빠르게 식별
'====================================================
Sub HighlightNegativeRows()

    Const AMOUNT_COL  As Integer = 4   ' D열
    Const TOTAL_COLS  As Integer = 6   ' A~F열 강조

    Dim ws       As Worksheet
    Dim lastRow  As Long
    Dim i        As Long
    Dim cnt      As Integer

    Set ws      = ActiveSheet
    lastRow     = ws.Cells(ws.Rows.Count, AMOUNT_COL).End(xlUp).Row
    cnt         = 0

    ' 기존 강조 초기화
    ws.Range("A2:" & Chr(64 + TOTAL_COLS) & lastRow).Interior.ColorIndex = xlNone

    For i = 2 To lastRow
        If IsNumeric(ws.Cells(i, AMOUNT_COL).Value) Then
            If ws.Cells(i, AMOUNT_COL).Value < 0 Then
                ws.Range("A" & i & ":" & Chr(64 + TOTAL_COLS) & i).Interior.Color = RGB(255, 199, 206)
                cnt = cnt + 1
            End If
        End If
    Next i

    If cnt = 0 Then
        MsgBox "음수 금액 없음.", vbInformation
    Else
        MsgBox cnt & "건의 음수 금액 행을 강조했습니다. 확인이 필요합니다.", vbExclamation
    End If

End Sub
```

---

## 6. 데이터 정제 유틸리티

### 스니펫 11. 텍스트 숫자 일괄 변환

```vba
'====================================================
' 스니펫 11: 선택 영역의 텍스트 형식 숫자를 실제 숫자로 변환
' ERP에서 내보낸 데이터에 자주 발생하는 문제 해결
' 사용법: 변환할 셀 범위 선택 후 실행
'====================================================
Sub ConvertTextToNumbers()

    If Selection Is Nothing Then
        MsgBox "변환할 셀 범위를 선택하세요.", vbExclamation
        Exit Sub
    End If

    Dim cell        As Range
    Dim convertedCnt As Integer
    Dim rawStr      As String

    convertedCnt = 0
    Application.ScreenUpdating = False

    For Each cell In Selection
        If Not IsEmpty(cell.Value) And VarType(cell.Value) = vbString Then
            rawStr = Trim(Replace(CStr(cell.Value), ",", ""))
            If IsNumeric(rawStr) Then
                cell.Value = CDbl(rawStr)
                convertedCnt = convertedCnt + 1
            End If
        End If
    Next cell

    Application.ScreenUpdating = True
    MsgBox convertedCnt & "개 셀을 숫자로 변환했습니다.", vbInformation

End Sub
```

### 스니펫 12. 중복 전표 탐지 및 강조

```vba
'====================================================
' 스니펫 12: 동일 날짜 + 계정코드 + 금액 중복 전표 탐지
' 구조: A=날짜, B=계정코드, C=금액 (또는 차변/대변)
' 중복 행 전체를 주황 배경으로 강조
'====================================================
Sub FindDuplicateEntries()

    Dim ws          As Worksheet
    Dim lastRow     As Long
    Dim i           As Long, j As Long
    Dim key         As String
    Dim dupCnt      As Integer
    Dim keyDict     As Object

    Set ws      = ActiveSheet
    lastRow     = ws.Cells(ws.Rows.Count, 1).End(xlUp).Row
    Set keyDict = CreateObject("Scripting.Dictionary")
    dupCnt      = 0

    ' 기존 강조 초기화
    ws.Range("A2:F" & lastRow).Interior.ColorIndex = xlNone

    Application.ScreenUpdating = False

    ' 1패스: 키 등장 횟수 카운트
    For i = 2 To lastRow
        key = CStr(ws.Cells(i, 1).Value) & "|" & _
              Trim(ws.Cells(i, 2).Value) & "|" & _
              CStr(ws.Cells(i, 3).Value)
        If keyDict.Exists(key) Then
            keyDict(key) = keyDict(key) + 1
        Else
            keyDict(key) = 1
        End If
    Next i

    ' 2패스: 중복 행 강조
    For i = 2 To lastRow
        key = CStr(ws.Cells(i, 1).Value) & "|" & _
              Trim(ws.Cells(i, 2).Value) & "|" & _
              CStr(ws.Cells(i, 3).Value)
        If keyDict(key) > 1 Then
            ws.Range("A" & i & ":F" & i).Interior.Color = RGB(255, 165, 0)  ' 주황
            dupCnt = dupCnt + 1
        End If
    Next i

    Application.ScreenUpdating = True

    If dupCnt = 0 Then
        MsgBox "중복 전표 없음.", vbInformation
    Else
        MsgBox dupCnt & "건의 중복 의심 행을 강조했습니다. 확인이 필요합니다.", vbExclamation
    End If

End Sub
```

### 스니펫 13. 조건부 행 삭제 (취소/삭제 상태)

```vba
'====================================================
' 스니펫 13: 특정 조건의 행 일괄 삭제
' 조건: C열이 "취소" 또는 "삭제", 또는 D열(금액)이 0
' 주의: 삭제 전 현재 시트를 자동 백업
'====================================================
Sub DeleteCancelledRows()

    Const STATUS_COL  As Integer = 3   ' C열 = 상태
    Const AMOUNT_COL  As Integer = 4   ' D열 = 금액

    Dim ws          As Worksheet
    Dim backupWs    As Worksheet
    Dim lastRow     As Long
    Dim i           As Long
    Dim deletedCnt  As Integer
    Dim statusVal   As String
    Dim amountVal   As Double

    Set ws = ActiveSheet

    ' 삭제 전 백업 시트 생성
    ws.Copy After:=Worksheets(Worksheets.Count)
    Set backupWs = ActiveSheet
    backupWs.Name = "백업_" & Format(Now(), "YYYYMMDD_HHMM")
    ws.Activate

    lastRow    = ws.Cells(ws.Rows.Count, STATUS_COL).End(xlUp).Row
    deletedCnt = 0

    Application.ScreenUpdating = False

    ' 아래에서 위로 순회 (행 삭제 시 인덱스 어긋남 방지)
    For i = lastRow To 2 Step -1
        statusVal = Trim(CStr(ws.Cells(i, STATUS_COL).Value))
        amountVal = 0
        If IsNumeric(ws.Cells(i, AMOUNT_COL).Value) Then
            amountVal = ws.Cells(i, AMOUNT_COL).Value
        End If

        If statusVal = "취소" Or statusVal = "삭제" Or amountVal = 0 Then
            ws.Rows(i).Delete
            deletedCnt = deletedCnt + 1
        End If
    Next i

    Application.ScreenUpdating = True
    MsgBox deletedCnt & "행 삭제 완료." & Chr(13) & _
           "백업 시트: " & backupWs.Name, vbInformation

End Sub
```

---

## 7. 유틸리티 함수

### 스니펫 14. 시트 존재 여부 확인 함수

```vba
'====================================================
' 스니펫 14: 시트 존재 여부 확인 Function (재사용 가능)
' 사용: If SheetExists("원장") Then ...
'====================================================
Function SheetExists(sheetName As String, Optional wb As Workbook) As Boolean
    Dim ws As Worksheet
    If wb Is Nothing Then Set wb = ThisWorkbook
    On Error Resume Next
    Set ws = wb.Worksheets(sheetName)
    On Error GoTo 0
    SheetExists = Not ws Is Nothing
End Function
```

### 스니펫 15. 마지막 데이터 행 찾기 함수

```vba
'====================================================
' 스니펫 15: 지정 열의 마지막 데이터 행 반환 Function
' 사용: lastRow = GetLastRow(ws, 1)  ' A열 기준
'====================================================
Function GetLastRow(ws As Worksheet, Optional colNum As Integer = 1) As Long
    GetLastRow = ws.Cells(ws.Rows.Count, colNum).End(xlUp).Row
End Function

'====================================================
' 스니펫 15b: 마지막 데이터 열 찾기 Function
'====================================================
Function GetLastCol(ws As Worksheet, Optional rowNum As Integer = 1) As Long
    GetLastCol = ws.Cells(rowNum, ws.Columns.Count).End(xlToLeft).Column
End Function
```

### 스니펫 16. 오류 로그 기록 서브루틴

```vba
'====================================================
' 스니펫 16: 오류 발생 시 "오류로그" 시트에 기록
' 사용: Call LogError("MergeFiles", "파일 열기 실패: " & Err.Description)
'====================================================
Sub LogError(procName As String, errMsg As String)

    Const LOG_SHEET As String = "오류로그"

    Dim logWs   As Worksheet
    Dim logRow  As Long

    On Error Resume Next
    Set logWs = ThisWorkbook.Worksheets(LOG_SHEET)
    On Error GoTo 0

    If logWs Is Nothing Then
        Set logWs = ThisWorkbook.Worksheets.Add(After:=Worksheets(Worksheets.Count))
        logWs.Name = LOG_SHEET
        logWs.Range("A1:D1").Value = Array("발생시각", "프로시저", "오류내용", "사용자")
        logWs.Range("A1:D1").Font.Bold = True
    End If

    logRow = GetLastRow(logWs, 1) + 1
    logWs.Cells(logRow, 1).Value = Now()
    logWs.Cells(logRow, 2).Value = procName
    logWs.Cells(logRow, 3).Value = errMsg
    logWs.Cells(logRow, 4).Value = Environ("USERNAME")

End Sub
```

### 스니펫 17. 원화 서식 일괄 적용

```vba
'====================================================
' 스니펫 17: 선택 영역에 원화 서식 (#,##0) 일괄 적용
' 사용법: 금액 범위 선택 후 실행
'====================================================
Sub ApplyKRWFormat()

    Const KRW_FORMAT As String = "#,##0"

    If Selection Is Nothing Then
        MsgBox "서식을 적용할 범위를 선택하세요.", vbExclamation
        Exit Sub
    End If

    Selection.NumberFormat = KRW_FORMAT
    MsgBox "원화 서식 적용 완료.", vbInformation

End Sub
```

---

## VBA 스니펫 빠른 참조

| 스니펫 | 이름 | 주요 용도 |
|--------|------|---------|
| 01 | MergeAllXlsxFiles | 폴더 내 파일 자동 통합 |
| 02 | SplitByDeptCode | 부서별 파일 분리 저장 |
| 03 | CreateMonthlySheets | 월별 시트 12개 자동 생성 |
| 04 | DeleteSheetsByPattern | 패턴 시트 일괄 삭제 |
| 05 | SaveReportsToPDF | 복수 시트 PDF 일괄 저장 |
| 06 | SaveActiveToPDF | 단일 시트 PDF 저장 |
| 07 | SendSheetAsPDF | PDF → Outlook 이메일 |
| 08 | SendBulkEmails | 수신자 목록 이메일 발송 |
| 09 | ApplyAchievementColors | 달성률 구간별 색상 |
| 10 | HighlightNegativeRows | 음수 행 강조 |
| 11 | ConvertTextToNumbers | 텍스트 숫자 변환 |
| 12 | FindDuplicateEntries | 중복 전표 탐지 |
| 13 | DeleteCancelledRows | 취소/삭제 행 정리 |
| 14 | SheetExists (Function) | 시트 존재 확인 |
| 15 | GetLastRow (Function) | 마지막 행 반환 |
| 16 | LogError | 오류 로그 기록 |
| 17 | ApplyKRWFormat | 원화 서식 적용 |

---

*Copilot으로 새 스니펫 생성: [prompts.md](../../prompts.md) P-11~P-17 참조*
