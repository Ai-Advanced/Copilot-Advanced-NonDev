# 07. 월/분기 리포트 자동화

## 학습 목표

- 다중 시트 통합과 Excel 리포트 자동 생성 파이프라인 구성
- PDF 자동 생성 및 이메일 자동화 구현
- 이상치 알림 시스템 만들기
- Python + openpyxl 또는 VBA 방식 선택 기준 이해
- 실습: 월간 재무 리포트 자동 생성 + 이메일 발송

**예상 소요**: 45분 (실습 포함)

---

## 7.1 리포트 자동화의 구조

월간 재무 리포트 자동화는 다음 4단계 파이프라인으로 구성됩니다:

```
[1단계] 데이터 수집
  CSV / Excel / DB 쿼리 결과

        ↓

[2단계] 데이터 가공
  집계, 피벗, 편차 계산

        ↓

[3단계] 리포트 생성
  Excel 서식 적용 / PDF 변환

        ↓

[4단계] 배포
  이메일 발송 / 폴더 저장 / 알림
```

### Python vs VBA 선택 기준

| 상황 | 추천 |
|------|------|
| 데이터 소스가 Excel 파일들 | VBA (같은 환경) |
| 데이터 소스가 CSV/DB | Python |
| 이메일 발송 자동화 | Python (더 안정적) |
| 서식이 복잡한 Excel 리포트 | VBA (Excel 네이티브 서식 제어) |
| 대용량 데이터 (수만 행+) | Python |
| 스케줄 실행 (새벽 자동화) | Python (Task Scheduler 연동) |

---

## 7.2 다중 시트 통합 (Python)

### Copilot 프롬프트

```
Python 스크립트 작성. pandas + openpyxl 사용.

목적: 여러 부서 실적 Excel 파일을 하나의 리포트로 통합

입력:
- C:\Finance\Monthly\ 폴더의 모든 .xlsx 파일
- 각 파일의 "실적" 시트 구조: 계정코드, 계정명, 금액 (헤더 + 데이터)

처리:
1. 폴더 내 모든 .xlsx 파일 순회
2. 각 파일의 "실적" 시트 읽기 (없는 파일은 건너뜀, 경고 출력)
3. 파일명에서 부서코드 추출 (파일명 형식: "DEPT코드_실적.xlsx")
4. 부서코드 컬럼 추가 후 하나의 DataFrame으로 concat
5. 계정코드별 합계 집계

출력: consolidated_report.xlsx
- 시트1 "원본통합": 모든 데이터 (부서코드 포함)
- 시트2 "계정별집계": 계정코드별 합계
- 시트3 "부서별집계": 부서코드별 합계

처리 로그: 파일명, 행 수, 처리 상태 출력
```

### 완성 스크립트

```python
"""
다중 부서 실적 파일 통합 스크립트
입력: C:\Finance\Monthly\*.xlsx (각 파일의 "실적" 시트)
출력: consolidated_report.xlsx
"""

import pandas as pd
from pathlib import Path
import sys

INPUT_FOLDER = Path(r"C:\Finance\Monthly")


def load_dept_file(file_path: Path) -> pd.DataFrame | None:
    """단일 파일에서 실적 시트를 읽어 부서코드 컬럼 추가."""
    # 파일명에서 부서코드 추출 (예: SALES_실적.xlsx → SALES)
    dept_code = file_path.stem.split("_")[0]

    try:
        df = pd.read_excel(file_path, sheet_name="실적")
    except Exception as e:
        print(f"  [건너뜀] {file_path.name}: {e}")
        return None

    df.insert(0, "부서코드", dept_code)
    df.insert(1, "파일명", file_path.name)
    print(f"  [완료] {file_path.name}: {len(df)}행")
    return df


def main():
    if not INPUT_FOLDER.exists():
        print(f"오류: 폴더 없음 - {INPUT_FOLDER}")
        sys.exit(1)

    xlsx_files = list(INPUT_FOLDER.glob("*.xlsx"))
    if not xlsx_files:
        print("오류: .xlsx 파일 없음")
        sys.exit(1)

    print(f"파일 {len(xlsx_files)}개 처리 중...")

    all_dfs = []
    for f in sorted(xlsx_files):
        df = load_dept_file(f)
        if df is not None:
            all_dfs.append(df)

    if not all_dfs:
        print("처리된 파일 없음. 종료.")
        sys.exit(1)

    combined = pd.concat(all_dfs, ignore_index=True)

    # 금액 컬럼 정제
    combined["금액"] = pd.to_numeric(
        combined["금액"].astype(str).str.replace(",", ""),
        errors="coerce"
    ).fillna(0)

    # 집계
    by_account = (
        combined.groupby(["계정코드", "계정명"])["금액"]
        .sum().reset_index()
        .sort_values("계정코드")
    )
    by_dept = (
        combined.groupby("부서코드")["금액"]
        .sum().reset_index()
        .sort_values("금액", ascending=False)
    )

    # Excel 저장
    with pd.ExcelWriter("consolidated_report.xlsx", engine="openpyxl") as writer:
        combined.to_excel(writer, sheet_name="원본통합", index=False)
        by_account.to_excel(writer, sheet_name="계정별집계", index=False)
        by_dept.to_excel(writer, sheet_name="부서별집계", index=False)

    print(f"\n통합 완료: 총 {len(combined):,}행")
    print(f"계정과목: {by_account['계정코드'].nunique()}개")
    print(f"부서: {by_dept['부서코드'].nunique()}개")
    print("출력: consolidated_report.xlsx")


if __name__ == "__main__":
    main()
```

---

## 7.3 Excel 리포트 서식 자동 적용 (openpyxl)

집계 데이터에 재무 리포트다운 서식을 자동으로 적용합니다.

**Copilot 프롬프트**:
```
Python 스크립트 작성. openpyxl 사용.

목적: 손익계산서 DataFrame을 서식 있는 Excel로 저장

입력 DataFrame 컬럼: pl_category, account_name, curr_amount, prev_amount, variance, growth_pct

서식 요구사항:
1. 1행 헤더: 굵은 글씨, 진한 파란 배경(1F4E79), 흰 글씨, 가운데 정렬
2. 소계/합계 행 (pl_category가 "소계" 또는 "합계" 포함): 굵은 글씨, 연회색 배경(D9D9D9), 상단 테두리
3. 금액 컬럼 (curr_amount, prev_amount, variance): 원화 서식 (#,##0), 오른쪽 정렬
4. growth_pct 컬럼: 0.0% 서식, < 0이면 빨간 글씨
5. 음수 금액: 빨간 글씨
6. 열 너비 자동 조정 (최소 10, 최대 30)
7. 첫 행 고정 (freeze_panes)

전체 코드 + 주석.
```

### 핵심 openpyxl 패턴

```python
from openpyxl import load_workbook
from openpyxl.styles import (
    Font, PatternFill, Alignment, Border, Side, numbers
)
from openpyxl.utils import get_column_letter

wb = load_workbook("report.xlsx")
ws = wb.active

# 헤더 서식
HEADER_FILL = PatternFill("solid", fgColor="1F4E79")
HEADER_FONT = Font(bold=True, color="FFFFFF", size=11)

for cell in ws[1]:
    cell.fill = HEADER_FILL
    cell.font = HEADER_FONT
    cell.alignment = Alignment(horizontal="center", vertical="center")

# 금액 서식 (#,##0)
KRW_FORMAT = '#,##0'
for row in ws.iter_rows(min_row=2, max_row=ws.max_row):
    for cell in row:
        if isinstance(cell.value, (int, float)):
            cell.number_format = KRW_FORMAT
            if cell.value < 0:
                cell.font = Font(color="FF0000")  # 음수 빨간 글씨

# 열 너비 자동 조정
for col in ws.columns:
    max_len = max(
        (len(str(cell.value)) for cell in col if cell.value),
        default=10
    )
    ws.column_dimensions[get_column_letter(col[0].column)].width = min(max(max_len + 2, 10), 30)

# 첫 행 고정
ws.freeze_panes = "A2"

wb.save("report_formatted.xlsx")
```

---

## 7.4 PDF 자동 생성

### Python으로 PDF 변환

Python에서 Excel → PDF 변환은 Microsoft Excel이 설치된 Windows 환경에서 `win32com`을 사용하는 것이 가장 안정적입니다.

**Copilot 프롬프트**:
```
Python 스크립트 작성. win32com 사용 (Windows + Excel 필요).

목적: Excel 파일의 특정 시트를 PDF로 변환
입력: report_formatted.xlsx, 시트명 "손익계산서"
출력: C:\Reports\YYYYMMDD_손익계산서.pdf

동작:
1. Excel COM 객체로 파일 열기 (Visible=False)
2. 지정 시트 선택
3. 인쇄 영역 설정 (사용된 범위 기준)
4. PDF 저장 (ExportAsFixedFormat)
5. Excel 닫기 (저장 없이)
6. 오류 시 Excel이 열린 채로 남지 않도록 finally 블록에서 처리

전체 코드 + 주석.
```

### win32com PDF 저장 패턴

```python
import win32com.client
from pathlib import Path
from datetime import date

def excel_to_pdf(xlsx_path: str, sheet_name: str, pdf_folder: str) -> str:
    """Excel 시트를 PDF로 변환 (win32com 필요)."""
    excel = None
    wb = None

    try:
        excel = win32com.client.Dispatch("Excel.Application")
        excel.Visible = False
        excel.DisplayAlerts = False

        wb = excel.Workbooks.Open(str(Path(xlsx_path).resolve()))
        ws = wb.Sheets(sheet_name)

        # 출력 파일 경로
        date_str = date.today().strftime("%Y%m%d")
        pdf_path = str(Path(pdf_folder) / f"{date_str}_{sheet_name}.pdf")

        # PDF 저장
        ws.ExportAsFixedFormat(
            Type=0,           # xlTypePDF
            Filename=pdf_path,
            Quality=0,        # xlQualityStandard
            IncludeDocProperties=True,
            IgnorePrintAreas=False,
            OpenAfterPublish=False
        )
        return pdf_path

    except Exception as e:
        raise RuntimeError(f"PDF 변환 오류: {e}") from e

    finally:
        if wb:
            wb.Close(SaveChanges=False)
        if excel:
            excel.Quit()
```

---

## 7.5 이메일 자동화

### Python + smtplib (사내 SMTP 서버)

**Copilot 프롬프트**:
```
Python 스크립트 작성. smtplib + email 표준 라이브러리 사용.

목적: 월간 재무 리포트 PDF를 이메일로 자동 발송

설정 (환경변수로 관리):
- SMTP_HOST: smtp.company.com
- SMTP_PORT: 587
- EMAIL_USER: finance@company.com
- EMAIL_PASS: (환경변수)

수신자 목록: 파일 recipients.csv (이름, 이메일, 역할)
- 역할이 "CFO" 또는 "임원"인 경우만 발송

이메일 내용:
- 제목: f"[재무팀] {연도}년 {월}월 월간 재무 리포트"
- 본문: HTML 형식
  - 재무 요약 테이블 (계정과목, 예산, 실적, 달성률)
  - 주요 특이사항 3개 (params로 받음)
  - 서명: "재무팀 | finance@company.com"
- 첨부: PDF 파일

환경변수 없으면 오류 메시지 후 종료.
실제 발송 전 드라이런 모드 (--dry-run 인수) 지원.
```

### 이메일 자동화 핵심 패턴

```python
import smtplib
import os
from email.mime.multipart import MIMEMultipart
from email.mime.text     import MIMEText
from email.mime.base     import MIMEBase
from email import encoders
from pathlib import Path


def send_finance_report(
    recipients: list[dict],
    pdf_path: str,
    summary_table: str,  # HTML 테이블 문자열
    highlights: list[str],
    year: int,
    month: int,
    dry_run: bool = False
) -> None:
    """월간 재무 리포트 이메일 발송."""

    smtp_host = os.environ.get("SMTP_HOST", "")
    smtp_port = int(os.environ.get("SMTP_PORT", 587))
    user      = os.environ.get("EMAIL_USER", "")
    password  = os.environ.get("EMAIL_PASS", "")

    if not all([smtp_host, user, password]):
        raise EnvironmentError("SMTP_HOST, EMAIL_USER, EMAIL_PASS 환경변수를 설정하세요.")

    subject = f"[재무팀] {year}년 {month}월 월간 재무 리포트"

    highlights_html = "".join(f"<li>{h}</li>" for h in highlights)

    body_html = f"""
    <html><body>
    <p>안녕하세요,</p>
    <p>{year}년 {month}월 월간 재무 리포트를 공유드립니다.</p>

    <h3>주요 재무 현황</h3>
    {summary_table}

    <h3>주요 특이사항</h3>
    <ul>{highlights_html}</ul>

    <p>자세한 내용은 첨부 PDF를 참고해 주시기 바랍니다.</p>
    <br>
    <p>감사합니다.<br>
    <strong>재무팀</strong> | finance@company.com</p>
    </body></html>
    """

    for recipient in recipients:
        msg = MIMEMultipart("alternative")
        msg["Subject"] = subject
        msg["From"]    = user
        msg["To"]      = recipient["이메일"]

        msg.attach(MIMEText(body_html, "html", "utf-8"))

        # PDF 첨부
        with open(pdf_path, "rb") as f:
            part = MIMEBase("application", "octet-stream")
            part.set_payload(f.read())
            encoders.encode_base64(part)
            part.add_header(
                "Content-Disposition",
                f'attachment; filename="{Path(pdf_path).name}"'
            )
            msg.attach(part)

        if dry_run:
            print(f"[드라이런] {recipient['이름']} <{recipient['이메일']}> 발송 예정")
            continue

        with smtplib.SMTP(smtp_host, smtp_port) as server:
            server.ehlo()
            server.starttls()
            server.login(user, password)
            server.send_message(msg)

        print(f"발송 완료: {recipient['이름']} <{recipient['이메일']}>")
```

---

## 7.6 이상치 알림 시스템

월 결산 전 자동으로 이상치를 탐지하고 알림을 보내는 스크립트입니다.

**Copilot 프롬프트**:
```
Python 스크립트 작성. pandas 사용.

목적: 재무 데이터 이상치 자동 탐지 + 알림

입력: gl_entries.csv (entry_date, account_code, account_name, dept_code, debit, credit)
기준월: 인수로 받음 (예: "2026-06")

탐지 규칙:
1. 중복 전표: 동일 날짜 + 계정코드 + 금액 조합 2건 이상
2. 금액 이상치: 계정별 평균 ± 2 표준편차 초과
3. 주말 입력: 토/일 entry_date
4. 라운드 넘버 집중: 1천만원 단위 정수 거래가 전체 10% 이상
5. 마이너스 금액: debit 또는 credit 음수

출력:
- anomaly_report.xlsx (이상 유형별 시트)
- 콘솔 요약: 유형별 건수

임계값은 상수로 관리.
```

### 이상치 탐지 핵심 로직

```python
import pandas as pd
import numpy as np
from datetime import datetime

def detect_anomalies(df: pd.DataFrame, target_month: str) -> dict[str, pd.DataFrame]:
    """재무 데이터 이상치 탐지."""
    anomalies = {}

    # 기준월 필터
    df["entry_date"] = pd.to_datetime(df["entry_date"])
    target = df[df["entry_date"].dt.to_period("M").astype(str) == target_month]

    # 1. 중복 전표
    dup_key = ["entry_date", "account_code", "debit", "credit"]
    dups = target[target.duplicated(subset=dup_key, keep=False)]
    if len(dups):
        anomalies["중복전표"] = dups

    # 2. 금액 이상치 (계정별 ±2 표준편차)
    amounts = target["debit"] + target["credit"]
    mean  = amounts.mean()
    std   = amounts.std()
    outliers = target[(amounts > mean + 2 * std) | (amounts < mean - 2 * std)]
    if len(outliers):
        anomalies["금액이상치"] = outliers

    # 3. 주말 전표
    weekends = target[target["entry_date"].dt.dayofweek >= 5]
    if len(weekends):
        anomalies["주말입력"] = weekends

    # 4. 라운드 넘버
    total_amount = target["debit"] + target["credit"]
    round_mask = (total_amount % 10_000_000 == 0) & (total_amount > 0)
    round_pct = round_mask.sum() / len(target) * 100
    if round_pct > 10:
        anomalies["라운드넘버집중"] = target[round_mask]

    # 5. 음수 금액
    negatives = target[(target["debit"] < 0) | (target["credit"] < 0)]
    if len(negatives):
        anomalies["음수금액"] = negatives

    return anomalies


# 결과 출력 및 Excel 저장
anomalies = detect_anomalies(df, "2026-06")
if anomalies:
    print("\n=== 이상 항목 탐지 ===")
    for name, items in anomalies.items():
        print(f"  {name}: {len(items)}건")

    with pd.ExcelWriter("anomaly_report.xlsx", engine="openpyxl") as writer:
        for name, items in anomalies.items():
            items.to_excel(writer, sheet_name=name[:31], index=False)  # 시트명 31자 제한
    print("\nanomaly_report.xlsx 저장 완료. 담당자 검토 필요.")
else:
    print("이상 항목 없음.")
```

---

## 7.7 실습: 월간 재무 리포트 자동 생성

### 전체 파이프라인 스크립트

**Copilot 프롬프트**:
```
Python 스크립트 작성. pandas + openpyxl + win32com 사용.

목적: 월간 재무 리포트 생성 자동화 파이프라인

단계:
1. actuals.csv 읽기 + 계정마스터 조인
2. 손익계산서 집계 (계정유형별 합계, 소계 행 삽입)
3. 전월 데이터(prev_actuals.csv)와 비교, 증감 계산
4. openpyxl로 서식 있는 Excel 생성:
   - 시트1: 손익계산서 (소계 행 굵은 서식)
   - 시트2: 계정별 상세
5. Win32com으로 PDF 저장
6. 이메일 발송 (--send 인수 있을 때만)

실행 방법:
  python monthly_report.py --month 2026-06
  python monthly_report.py --month 2026-06 --send

argparse로 인수 처리. 환경변수 .env 파일 지원 (python-dotenv).
각 단계 완료 시 로그 출력.
```

### 실행 및 검증 체크리스트

```
파이프라인 실행 후:
[ ] actuals.csv 총 행수가 콘솔 출력과 일치하는지
[ ] 손익계산서 영업이익 = 매출 - 원가 - 판관비 수동 계산 확인
[ ] PDF 파일이 C:\Reports\ 폴더에 생성됐는지
[ ] PDF 열어서 페이지 잘림 없는지
[ ] --dry-run 모드로 이메일 수신자 목록 확인 후 --send 실행
[ ] 발송 후 수신 이메일 확인 (자기 자신에게 테스트 발송 권장)
```

---

## 핵심 포인트

1. **파이프라인 4단계**: 수집 → 가공 → 생성 → 배포, 각 단계 로그 기록
2. **Python vs VBA**: 데이터 소스가 CSV/DB면 Python, Excel 내부 작업이면 VBA
3. **openpyxl 서식**: 헤더/소계/음수에 일관된 서식 적용으로 전문성 확보
4. **이메일은 드라이런 먼저**: `--dry-run` 으로 수신자 확인 후 실제 발송
5. **이상치 탐지는 결산 D-3일**: 마감 전 자동 탐지해서 수동 검토 시간 확보

---

**다음**: [08-capstone.md](./08-capstone.md) — 캡스톤: 월 결산 자동화 A~Z
