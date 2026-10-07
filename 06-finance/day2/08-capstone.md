# 08. 캡스톤: 월 결산 자동화 A~Z

**완성 후 Azure로:** 아래 산출물 검증을 마치면 [공통 배포 캡스톤](../../09-azure-capstone/README.md)에서 가상 집계 보고서를 게시합니다. Python/VBA 자체를 정적 웹에서 실행하지 않습니다. [직군별 요구사항·프롬프트](../../09-azure-capstone/roles.md)를 사용하며, 기존 과정과 별도 편성입니다.

## 개요

이 캡스톤은 2일간 배운 모든 것을 하나의 흐름으로 연결합니다.

```
데이터 수집 (SQL)
    ↓
데이터 정제 (Python/VBA)
    ↓
재무제표 생성 (Excel)
    ↓
이상치 검증
    ↓
임원 리포트 생성
    ↓
PDF/이메일 발송
```

각 단계에서 Copilot을 활용해 코드를 생성하고, 검증까지 직접 수행합니다.
이 캡스톤을 완성하면 실제 월 결산 준비 시간을 50% 이상 단축할 수 있습니다.

**예상 소요**: 60~90분

---

## 시나리오 설정

> 2026년 6월 결산을 처리합니다.
> 회사는 K-IFRS를 적용하며, 회계연도는 1월~12월 결산입니다.
> 매출액, 매출원가, 판관비(급여/임차료/광고선전비)가 주요 계정입니다.
> 4개 부서(SALES, MFG, HR, ADM)로 구성됩니다.

---

## Step 1. 데이터 수집 (SQL)

### 1-1. 원장 데이터 추출 쿼리

**Copilot 프롬프트**:
```
PostgreSQL 쿼리 작성.

목적: 월 결산용 원장 데이터 추출
테이블: gl_entries(id, entry_date, account_code, dept_code, debit, credit, description)

조건: 2026-06-01 ~ 2026-06-30
결과: 모든 컬럼 + account_master에서 account_name, account_type, pl_category 조인
정렬: entry_date, account_code

이 쿼리 결과를 CSV로 내보낼 것이므로 컬럼명은 한국어로 별칭 설정:
entry_date → 전표일자, account_code → 계정코드, 등
```

DB가 없는 경우 Copilot에게 샘플 CSV 생성 요청:

```
SQLite INSERT 또는 CSV 형식으로 샘플 원장 데이터 생성.

헤더: 전표일자,계정코드,계정명,계정유형,부서코드,차변,대변,적요
데이터 특성:
- 2026년 6월 전표 120행
- 계정: 4000/매출/revenue, 5200/매출원가/cogs, 5110/급여/sg_and_a, 5120/임차료/sg_and_a, 5150/광고선전비/sg_and_a
- 부서: SALES, MFG, HR, ADM
- 매출(4000): credit에 금액, debit=0
- 비용(5xxx): debit에 금액, credit=0
- 금액 범위: 1,000,000 ~ 30,000,000원

CSV 120행 출력. 헤더 포함.
```

### 1-2. 예산 데이터 추출

```
SQL 쿼리 작성.

테이블: budget(year, month, dept_code, account_code, budget_amount)
조건: year=2026, month=6
결과: dept_code, account_code, budget_amount
정렬: dept_code, account_code
```

샘플이 필요하면:
```
예산 CSV 샘플 생성.
헤더: 부서코드,계정코드,예산금액
데이터: 4개 부서 × 5개 계정 = 20행
예산금액: 5,000,000 ~ 50,000,000 범위
```

---

## Step 2. 데이터 정제 (Python)

### 2-1. 원장 데이터 정제 스크립트

**Copilot 프롬프트**:
```
Python 스크립트 작성. pandas 사용.

파일명: step2_clean_data.py

입력: raw_gl_202606.csv (Step 1에서 추출한 원장)
헤더: 전표일자,계정코드,계정명,계정유형,부서코드,차변,대변,적요

정제 항목:
1. 전표일자: 날짜 형식 통일 (YYYY-MM-DD)
2. 계정코드: 앞뒤 공백 제거, 4자리 숫자 아닌 것 플래그
3. 차변/대변: 쉼표 제거 후 숫자 변환, 음수이면 경고 로그
4. 부서코드: 대문자 통일, 마스터에 없는 코드 플래그
   유효 부서코드 목록: ["SALES", "MFG", "HR", "ADM"]
5. 결측값: 계정코드/부서코드 결측은 행 제거 (제거 건수 로그)

출력:
- clean_gl_202606.csv (정제 완료)
- data_issues.csv (플래그된 행 목록)

콘솔: 총 행수, 정제 후 행수, 제거 행수, 플래그 건수
```

### 핵심 정제 코드

```python
"""
Step 2: 원장 데이터 정제
입력: raw_gl_202606.csv
출력: clean_gl_202606.csv, data_issues.csv
"""

import pandas as pd
import sys

VALID_DEPTS  = {"SALES", "MFG", "HR", "ADM"}
VALID_TYPES  = {"revenue", "cogs", "sg_and_a", "other"}
INPUT_FILE   = "raw_gl_202606.csv"
OUTPUT_CLEAN = "clean_gl_202606.csv"
OUTPUT_ISSUE = "data_issues.csv"


def clean_gl(df: pd.DataFrame) -> tuple[pd.DataFrame, pd.DataFrame]:
    """원장 정제. (정제본, 이슈본) 반환."""
    issues = []

    # 날짜 변환
    df["전표일자"] = pd.to_datetime(df["전표일자"], errors="coerce")
    date_err = df["전표일자"].isna()
    if date_err.any():
        issues.append(df[date_err].assign(이슈="날짜형식오류"))
        df = df[~date_err]

    # 금액 정제
    for col in ["차변", "대변"]:
        df[col] = (
            df[col].astype(str).str.replace(",", "").str.strip()
        )
        df[col] = pd.to_numeric(df[col], errors="coerce").fillna(0)

    # 음수 금액 플래그
    neg_mask = (df["차변"] < 0) | (df["대변"] < 0)
    if neg_mask.any():
        issues.append(df[neg_mask].assign(이슈="음수금액"))

    # 계정코드 공백 제거 + 검증
    df["계정코드"] = df["계정코드"].astype(str).str.strip()
    invalid_code = ~df["계정코드"].str.match(r"^\d{4}$")
    if invalid_code.any():
        issues.append(df[invalid_code].assign(이슈="계정코드형식오류"))

    # 부서코드 대문자 + 유효성
    df["부서코드"] = df["부서코드"].astype(str).str.upper().str.strip()
    invalid_dept = ~df["부서코드"].isin(VALID_DEPTS)
    if invalid_dept.any():
        issues.append(df[invalid_dept].assign(이슈="미등록부서코드"))

    # 결측 제거
    na_mask = df["계정코드"].isna() | df["부서코드"].isna()
    removed = df[na_mask]
    if len(removed):
        print(f"  결측 행 제거: {len(removed)}건")
    df = df[~na_mask]

    issue_df = pd.concat(issues, ignore_index=True) if issues else pd.DataFrame()
    return df, issue_df


def main():
    try:
        df = pd.read_csv(INPUT_FILE, encoding="utf-8-sig")
    except FileNotFoundError:
        print(f"오류: {INPUT_FILE} 없음")
        sys.exit(1)

    original_len = len(df)
    clean_df, issue_df = clean_gl(df)

    clean_df.to_csv(OUTPUT_CLEAN, index=False, encoding="utf-8-sig")
    if len(issue_df):
        issue_df.to_csv(OUTPUT_ISSUE, index=False, encoding="utf-8-sig")

    print(f"\n[Step 2 완료]")
    print(f"  원본 행수:   {original_len:,}")
    print(f"  정제 후:     {len(clean_df):,}")
    print(f"  이슈 건수:   {len(issue_df):,}  ← data_issues.csv 검토 필요")

    if len(issue_df) > 0:
        print("\n  이슈 유형별 건수:")
        if "이슈" in issue_df.columns:
            for t, cnt in issue_df["이슈"].value_counts().items():
                print(f"    {t}: {cnt}건")


if __name__ == "__main__":
    main()
```

---

## Step 3. 재무제표 생성 (Excel)

### 3-1. 손익계산서 집계 스크립트

**Copilot 프롬프트**:
```
Python 스크립트 작성. pandas + openpyxl 사용.

파일명: step3_build_pl.py

입력:
- clean_gl_202606.csv (전표일자, 계정코드, 계정명, 계정유형, 부서코드, 차변, 대변)
- budget_202606.csv (부서코드, 계정코드, 예산금액)
- prev_gl_202605.csv (5월 동일 구조 - 비교용)

처리:
1. 계정유형별 잔액 계산:
   - revenue: 대변 - 차변
   - cogs / sg_and_a: 차변 - 대변
2. 손익계산서 구조로 집계:
   - 매출 (revenue 합계)
   - 매출원가 (cogs 합계)
   - 매출총이익 = 매출 - 원가
   - 판관비 (sg_and_a 합계)
   - 영업이익 = 매출총이익 - 판관비
3. 예산과 비교 (account_code 기준 JOIN)
4. 전월 실적과 비교

출력 pl_202606.xlsx:
- 시트1 "손익계산서": 행=P&L 항목, 열=당기/예산/편차/달성률/전월/증감
- 시트2 "부서별매출": 부서별 매출 피벗
- 시트3 "상세원장": clean_gl 전체 (필터 가능하도록)

서식: 소계 행 굵은 글씨, 음수 빨간 글씨, 금액 #,##0 서식
```

### 검증 수식 (Excel에서 확인)

Excel에서 생성된 pl_202606.xlsx를 열고 다음을 확인합니다:

```
수동 검증 공식:
영업이익 = 매출 - 매출원가 - 판관비
  → 손익계산서 셀 값과 일치 확인

매출 달성률 = 실적/예산 × 100
  → 공식 직접 계산 후 셀 값과 비교

전월 대비 증감 = 당기 - 전월
  → 직접 뺄셈 확인
```

---

## Step 4. 이상치 검증

### 4-1. 자동 검증 스크립트

**Copilot 프롬프트**:
```
Python 스크립트 작성.

파일명: step4_validate.py

입력: clean_gl_202606.csv

검증 항목 5가지:
1. 대차 일치: 차변 합계 = 대변 합계
2. 계정별 잔액 방향 이상 (자산/비용 계정이 대변 잔액이면 경고)
3. 전월 대비 ±50% 초과 변동 계정 (prev_summary.csv 와 비교)
4. 동일 전표일자+계정코드+금액 중복 건
5. 마지막 2영업일 집중 입력 (월말 몰아치기 의심)

결과:
- 각 항목 PASS/FAIL 출력
- FAIL 항목은 상세 내용 출력
- validation_log_202606.txt 저장
- 전체 PASS면 "검증 완료 - 다음 단계 진행 가능" 출력
- FAIL 있으면 "N개 항목 검토 필요 - 수정 후 재실행" 출력 후 exit code 1
```

### 검증 결과 형태

```
=== 월 결산 데이터 검증 결과 (2026-06) ===

[1] 대차 일치         ✓ PASS  (차변: 287,500,000 / 대변: 287,500,000)
[2] 잔액 방향 이상    ✗ FAIL  3건 발견
    - 계정 5110(급여): 대변 잔액 1,200,000원 (비정상)
    → data_issues.csv 참조하여 수정 후 재실행
[3] 전월 대비 변동    ✓ PASS  (최대 변동: 광고선전비 +42%)
[4] 중복 전표         ✓ PASS
[5] 월말 집중 입력    △ 참고  (마지막 2일 집중율: 28% - 기준치 30% 이하)

전체 결과: 1개 항목 FAIL - 수정 후 재실행 필요
```

---

## Step 5. 임원 리포트 생성

### 5-1. 임원 요약 보고서 (Markdown → PDF)

**Copilot 프롬프트**:
```
Python 스크립트 작성.

파일명: step5_exec_report.py

목적: 손익계산서 데이터를 읽어 임원 보고용 요약 Markdown 자동 생성

입력: pl_202606.xlsx의 "손익계산서" 시트

처리:
1. 주요 지표 읽기: 매출, 영업이익, 달성률
2. 전월 대비 주요 변동 항목 상위 3개 추출
3. 이상치 항목 (달성률 80% 미만 또는 120% 초과) 자동 추출

출력: exec_summary_202606.md

Markdown 구조:
- H1: "2026년 6월 재무 실적 요약"
- 작성일, 작성부서
- H2: "핵심 지표"
  표: KPI, 예산, 실적, 달성률, 전월 대비
- H2: "주요 특이사항"
  자동 생성한 3개 항목 불릿
- H2: "리스크 / 추적 필요 항목"
  달성률 이상 계정 목록
- H2: "다음 달 전망"
  [수동 입력 필요 - 여기에 내용을 추가하세요] 플레이스홀더

금액은 억원 단위 (소수점 1자리).
```

### Markdown → PDF 변환

Markdown 파일을 PDF로 변환하는 방법:

```bash
# pandoc 설치된 경우 (권장)
pandoc exec_summary_202606.md -o exec_summary_202606.pdf --pdf-engine=wkhtmltopdf

# VS Code에서 Markdown PDF 확장 사용
# Ctrl+Shift+P → "Markdown PDF: Export (pdf)"
```

**Copilot 프롬프트 - pandoc 자동화**:
```
Python 스크립트로 pandoc 명령을 subprocess로 실행.
입력: exec_summary_202606.md
출력: C:\Reports\YYYYMMDD_임원리포트.pdf
pandoc 없으면 사용자에게 설치 안내 메시지 출력.
```

---

## Step 6. PDF/이메일 발송

### 6-1. 발송 파이프라인

**Copilot 프롬프트**:
```
Python 스크립트 작성.

파일명: step6_distribute.py

목적: 생성된 리포트를 수신자별로 자동 발송

입력:
- pl_202606.xlsx (재무 담당자용)
- exec_summary_202606.pdf (임원용)
- recipients.csv (이름, 이메일, 역할)
  역할: "재무팀", "CFO", "임원", "부서장"

발송 규칙:
- CFO/임원: exec_summary_202606.pdf 발송
- 재무팀: pl_202606.xlsx + exec_summary_202606.pdf 발송
- 부서장: 해당 부서 데이터만 필터링한 별도 Excel 생성 후 발송
  (dept_code 컬럼으로 필터, 파일명: DEPT코드_202606.xlsx)

실행:
  python step6_distribute.py --month 2026-06 --dry-run   # 확인만
  python step6_distribute.py --month 2026-06 --send      # 실제 발송

각 발송 건 로그 기록 (파일명: send_log_202606.txt).
```

### 부서장용 필터링 Excel 생성

```python
import pandas as pd
from pathlib import Path

def create_dept_report(
    gl_df: pd.DataFrame,
    dept_code: str,
    output_folder: str,
    month: str
) -> str:
    """부서별 필터링 Excel 생성."""
    dept_df = gl_df[gl_df["부서코드"] == dept_code].copy()

    # 부서 요약
    summary = (
        dept_df.groupby(["계정코드", "계정명"])
        .agg(차변합계=("차변", "sum"), 대변합계=("대변", "sum"))
        .reset_index()
    )
    summary["잔액"] = summary.apply(
        lambda r: r["대변합계"] - r["차변합계"]
        if r["계정코드"].startswith("4")
        else r["차변합계"] - r["대변합계"],
        axis=1
    )

    output_path = str(
        Path(output_folder) / f"{dept_code}_{month.replace('-', '')}.xlsx"
    )

    with pd.ExcelWriter(output_path, engine="openpyxl") as writer:
        summary.to_excel(writer, sheet_name="요약", index=False)
        dept_df.to_excel(writer, sheet_name="원장상세", index=False)

    return output_path
```

---

## Step 7. 전체 파이프라인 통합 실행

### 통합 실행 스크립트

**Copilot 프롬프트**:
```
Python 스크립트 작성.

파일명: run_monthly_close.py

목적: Step 1~6을 순서대로 실행하는 오케스트레이터

동작:
1. 각 단계를 subprocess로 또는 직접 함수 호출로 실행
2. 각 단계 시작/완료 시간 기록
3. Step 4 검증에서 FAIL이면 실행 중단 + 사용자 확인 요청
4. 모든 단계 완료 후 소요 시간 요약 출력

실행 방법:
  python run_monthly_close.py --month 2026-06
  python run_monthly_close.py --month 2026-06 --skip-email

단계별 상태를 close_status_202606.json에 기록
(재실행 시 완료된 단계 건너뜀 - idempotent)
```

### 실행 흐름 예시

```
$ python run_monthly_close.py --month 2026-06

=== 2026년 6월 월 결산 자동화 시작 ===
시작 시각: 2026-07-05 09:00:00

[Step 1] 데이터 수집... ✓ (소요: 3초)
         원장 118행, 예산 20행

[Step 2] 데이터 정제... ✓ (소요: 2초)
         정제 완료: 118행, 이슈: 0건

[Step 3] 재무제표 생성... ✓ (소요: 5초)
         pl_202606.xlsx 생성 완료

[Step 4] 이상치 검증... ✗ FAIL
         1개 항목 실패 - 수정 후 재실행 필요
         → validation_log_202606.txt 확인

실행 중단. 검증 통과 후 재실행하세요.
```

수정 후 재실행:

```
$ python run_monthly_close.py --month 2026-06

=== 2026년 6월 월 결산 자동화 재실행 ===

[Step 1] 건너뜀 (이전 실행 완료)
[Step 2] 건너뜀 (이전 실행 완료)
[Step 3] 건너뜀 (이전 실행 완료)

[Step 4] 이상치 검증... ✓ (소요: 2초)
         전체 검증 통과

[Step 5] 임원 리포트 생성... ✓ (소요: 4초)
         exec_summary_202606.md + PDF 생성

[Step 6] 발송 (드라이런)...
         수신자 8명 예정 (CFO 1, 임원 3, 재무팀 2, 부서장 2)
         실제 발송하려면 --send 인수 추가

=== 완료 ===
총 소요 시간: 8분 23초
생성 파일: pl_202606.xlsx, exec_summary_202606.pdf, 부서별 Excel 4개
```

---

## 캡스톤 완료 체크리스트

```
Step 1. 데이터 수집
[ ] 원장 CSV 파일 생성됨 (행수 확인)
[ ] 예산 CSV 파일 생성됨 (20행)

Step 2. 데이터 정제
[ ] clean_gl_202606.csv 생성됨
[ ] 이슈 건수 0 또는 수동 처리 완료
[ ] 금액 합계 원본과 일치

Step 3. 재무제표 생성
[ ] pl_202606.xlsx 3개 시트 확인
[ ] 영업이익 = 매출 - 원가 - 판관비 수동 검증
[ ] 달성률 계산 정확성 2개 이상 수동 확인

Step 4. 이상치 검증
[ ] validation_log_202606.txt 전체 PASS
[ ] 특이 항목 있으면 설명 가능한지 확인

Step 5. 임원 리포트
[ ] exec_summary_202606.md 내용 검토
[ ] "다음 달 전망" 섹션 수동 작성
[ ] PDF 생성 확인 + 내용 검토

Step 6. 배포
[ ] --dry-run으로 수신자 목록 확인
[ ] 테스트 발송 (자기 자신에게)
[ ] 최종 발송 + send_log 확인
```

---

## 재무 담당자를 위한 자동화 후 검증 원칙

이 파이프라인이 아무리 잘 만들어져도, **최종 검증은 사람이 해야 합니다.**

다음 원칙을 항상 지키세요:

### 원칙 1. 숫자는 설명이 가능해야 한다

자동화된 손익계산서의 모든 주요 숫자에 대해 "왜 이 숫자인가"를 설명할 수 있어야 합니다. 설명 못 하는 숫자는 검증이 안 된 것입니다.

### 원칙 2. 전기와 비교하라

전월/전년 동기 대비 급격한 변동은 반드시 원인을 확인합니다. 자동화 오류일 수도, 실제 사업 변화일 수도 있습니다.

### 원칙 3. 합계를 두 번 계산하라

자동화 결과의 합계를 Excel에서 수동으로도 한 번 더 계산합니다. 5분의 투자가 감사 지적 리스크를 없앱니다.

### 원칙 4. 이상치는 무시하지 말라

자동화 스크립트가 FAIL을 냈을 때 "어차피 금액이 작으니까"라며 넘어가지 않습니다. 작은 오류가 쌓이면 큰 오류가 됩니다.

### 원칙 5. 감사 추적을 남겨라

자동화 스크립트, 처리 로그, 검증 결과 파일을 모두 보존합니다. 감사인이 "이 숫자 어떻게 나왔어요?"라고 물을 때 파이프라인 전체를 보여줄 수 있어야 합니다.

---

## 2일 과정 마무리

### 이 과정에서 배운 것

| 챕터 | 핵심 기술 | 적용 업무 |
|------|----------|---------|
| 01 | Copilot 15가지 재무 활용 | 전반적 업무 효율화 |
| 02 | XLOOKUP/SUMIFS/NPV/배열수식 | 재무 모델, 대시보드 |
| 03 | VBA 매크로, PDF 자동화 | 월 결산 반복 업무 |
| 04 | 수식+VBA 통합 실습 | 마감 준비 파일 |
| 05 | SQL 20개 패턴, YoY/QoQ | ERP 데이터 추출 |
| 06 | pandas 자동 분개, 샘플링 | 경비 처리, 감사 준비 |
| 07 | 리포트 파이프라인, 이메일 | 월간 리포트 배포 |
| 08 | 결산 자동화 A~Z (이번 챕터) | 월 결산 전체 흐름 |

### 다음 단계

1. 이 파이프라인을 **실제 업무 데이터**에 적용해보세요 (익명화 후)
2. 이번 달 마감 전에 Step 1~4까지만이라도 실행해보세요
3. 동료와 공유해서 **팀 공통 자동화 자산**으로 만드세요
4. 분기마다 파이프라인을 돌아보고 개선점을 Copilot에게 물어보세요

### 도움이 필요할 때

```
막혔을 때 Copilot 프롬프트:
"아래 Python 코드가 [오류메시지]를 출력해. 원인과 수정 방법 알려줘.
[오류 발생 코드 붙여넣기]"

새 요구사항 생겼을 때:
"현재 step3_build_pl.py에 [새 기능]을 추가하고 싶어.
현재 코드: [코드 붙여넣기]
추가할 기능: [구체적 설명]"
```

---

**과정 완료!** [README.md](../README.md)로 돌아가거나, [prompts.md](../prompts.md)에서 추가 프롬프트를 확인하세요.
