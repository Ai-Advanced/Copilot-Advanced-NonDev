# 06. Python 회계 자동화 (pandas)

## 학습 목표

- pandas로 재무 데이터를 다루는 **핵심 패턴** 습득
- 은행 명세서 자동 분개, 매입매출 매칭, 예산 편차 분석, 감사 샘플링 스크립트 완성
- Copilot으로 pandas 스크립트를 생성하고 검증하는 방법 체득
- Excel과 Python 간 데이터 왕복 (openpyxl 연동)
- 실습: 카드 명세 → 자동 분개 CSV

**예상 소요**: 60분 (실습 포함)

---

## 6.1 Python이 VBA/수식보다 나은 경우

| 상황 | 추천 도구 |
|------|---------|
| Excel 내부에서 빠르게 처리 | VBA |
| 여러 Excel 파일 통합 | VBA 또는 Python |
| CSV/JSON 등 비Excel 데이터 처리 | Python |
| 복잡한 조건 분류 (키워드 매핑) | Python |
| DB 연결 + 데이터 가공 | Python |
| 대용량 데이터 (수만 행+) | Python |
| 통계 분석, 이상치 탐지 | Python |
| 자동 이메일, 스케줄 실행 | Python |

Python이 필요한 가장 흔한 재무 시나리오: **ERP에서 내보낸 CSV를 가공해서 Excel 리포트 생성**.

---

## 6.2 Copilot으로 pandas 스크립트 생성하기

### pandas 프롬프트의 5요소

```
1. 입력: 파일 이름, 형식, 헤더 구조 (샘플 3줄 포함)
2. 처리: 단계별 변환 로직 (조건, 필터, 집계 등)
3. 규칙: 분류 기준, 키워드 딕셔너리 등
4. 출력: 파일 이름, 형식, 컬럼 순서
5. 예외: 빈 값, 오류 행 처리 방식
```

### 기본 pandas 패턴

```python
import pandas as pd

# CSV 읽기
df = pd.read_csv('input.csv', encoding='utf-8-sig')

# Excel 읽기
df = pd.read_excel('input.xlsx', sheet_name='원장')

# 컬럼명 확인
print(df.columns.tolist())
print(df.head())
print(df.dtypes)

# 날짜 컬럼 변환
df['전표일자'] = pd.to_datetime(df['전표일자'])

# 금액 컬럼 정제 (쉼표 제거 후 숫자 변환)
df['금액'] = df['금액'].astype(str).str.replace(',', '').str.strip()
df['금액'] = pd.to_numeric(df['금액'], errors='coerce').fillna(0)

# 필터링
df_sales = df[df['계정코드'].str.startswith('4')]

# 그룹 집계
summary = df.groupby(['계정코드', '부서코드'])['금액'].sum().reset_index()

# CSV 저장
df.to_csv('output.csv', index=False, encoding='utf-8-sig')

# Excel 저장
df.to_excel('output.xlsx', index=False, sheet_name='집계')
```

---

## 6.3 은행 명세서 자동 분개

### 시나리오

은행 명세서 CSV를 받아서 계정과목을 자동으로 분류하고 분개 CSV를 만듭니다.

### 완성 스크립트 (Copilot 생성 + 검증)

**Copilot 프롬프트**:
```
Python 스크립트 작성. pandas 사용.

목적: 은행 명세서 CSV → 회계 분개 CSV 자동 변환

입력 파일: bank_statement.csv
헤더: 거래일자,적요,출금,입금,잔액
샘플:
2026-06-05,매출대금수령 (주)ABC,0,5000000,10000000
2026-06-10,급여지급,3500000,0,6500000
2026-06-15,임차료 강남빌딩,1200000,0,5300000

분개 규칙 (딕셔너리로 관리):
- 입금: 기본 대변=가수금(2190), 차변=보통예금(1011)
- 입금 + 적요에 "매출" 포함: 대변=매출(4000)
- 출금: 기본 차변=경비(5100), 대변=보통예금(1011)
- 출금 + 적요에 "급여" 포함: 차변=급여(5110)
- 출금 + 적요에 "임차" 포함: 차변=임차료(5120)
- 출금 + 적요에 "광고" or "마케팅" 포함: 차변=광고선전비(5150)

출력: journal_entries.csv
컬럼: 거래일자,적요,차변계정코드,차변계정명,대변계정코드,대변계정명,금액,분류방법

미분류 건(기본 규칙 적용): "분류방법" 컬럼에 "기본분류" 표시
키워드 매칭: "키워드매칭:[키워드]" 표시

전체 스크립트 + 주석.
실행 완료 시 콘솔에 총 건수, 키워드 매칭 건수, 기본분류 건수 출력.
```

### 생성 스크립트 예시

```python
"""
은행 명세서 자동 분개 스크립트
입력: bank_statement.csv
출력: journal_entries.csv
실행: python auto_journal.py
"""

import pandas as pd
import sys

# =========================================================
# 분개 규칙 설정 (키워드 → 계정코드/계정명)
# 사내 계정체계에 맞게 수정하세요
# =========================================================

DEBIT_RULES = {
    "급여":    ("5110", "급여"),
    "상여":    ("5120", "상여"),
    "임차":    ("5130", "임차료"),
    "광고":    ("5150", "광고선전비"),
    "마케팅":  ("5150", "광고선전비"),
    "통신":    ("5160", "통신비"),
    "보험":    ("5170", "보험료"),
}

CREDIT_RULES = {
    "매출":    ("4000", "매출"),
    "수령":    ("4000", "매출"),
    "입금":    ("4000", "매출"),
}

BANK_ACCOUNT = ("1011", "보통예금")
DEFAULT_EXPENSE = ("5100", "경비")
DEFAULT_INCOME  = ("2190", "가수금")


def classify_transaction(row: pd.Series) -> dict:
    """거래 1건을 분개로 변환."""
    yoek = str(row["적요"])
    amount = row["입금"] if row["입금"] > 0 else row["출금"]

    if row["입금"] > 0:
        # 입금: 차변 = 보통예금
        debit_code, debit_name = BANK_ACCOUNT
        credit_code, credit_name = DEFAULT_INCOME
        matched_kw = None

        for kw, acc in CREDIT_RULES.items():
            if kw in yoek:
                credit_code, credit_name = acc
                matched_kw = kw
                break

        method = f"키워드매칭:{matched_kw}" if matched_kw else "기본분류"

    else:
        # 출금: 대변 = 보통예금
        credit_code, credit_name = BANK_ACCOUNT
        debit_code, debit_name = DEFAULT_EXPENSE
        matched_kw = None

        for kw, acc in DEBIT_RULES.items():
            if kw in yoek:
                debit_code, debit_name = acc
                matched_kw = kw
                break

        method = f"키워드매칭:{matched_kw}" if matched_kw else "기본분류"

    return {
        "거래일자":     row["거래일자"],
        "적요":        yoek,
        "차변계정코드": debit_code,
        "차변계정명":  debit_name,
        "대변계정코드": credit_code,
        "대변계정명":  credit_name,
        "금액":        int(amount),
        "분류방법":    method,
    }


def main():
    # 입력 파일 읽기
    try:
        df = pd.read_csv("bank_statement.csv", encoding="utf-8-sig")
    except FileNotFoundError:
        print("오류: bank_statement.csv 파일을 찾을 수 없습니다.")
        sys.exit(1)

    # 컬럼 검증
    required = {"거래일자", "적요", "출금", "입금"}
    missing = required - set(df.columns)
    if missing:
        print(f"오류: 필수 컬럼 없음: {missing}")
        sys.exit(1)

    # 숫자 컬럼 정제 (쉼표, 공백 제거)
    for col in ["출금", "입금"]:
        df[col] = (
            df[col].astype(str)
            .str.replace(",", "")
            .str.strip()
        )
        df[col] = pd.to_numeric(df[col], errors="coerce").fillna(0)

    # 날짜 변환
    df["거래일자"] = pd.to_datetime(df["거래일자"]).dt.strftime("%Y-%m-%d")

    # 분개 처리
    journal_rows = [classify_transaction(row) for _, row in df.iterrows()]
    journal_df = pd.DataFrame(journal_rows)

    # 출력 저장
    journal_df.to_csv("journal_entries.csv", index=False, encoding="utf-8-sig")

    # 통계 출력
    total = len(journal_df)
    keyword_matched = journal_df["분류방법"].str.startswith("키워드").sum()
    default_classified = total - keyword_matched

    print(f"분개 처리 완료:")
    print(f"  총 건수:        {total:,}건")
    print(f"  키워드 매칭:    {keyword_matched:,}건")
    print(f"  기본 분류:      {default_classified:,}건  ← 수동 검토 필요")
    print(f"출력 파일: journal_entries.csv")

    # 대차 일치 검증
    total_debit  = journal_df["금액"].sum()
    total_credit = journal_df["금액"].sum()
    # 분개는 각 행이 1:1이므로 항상 같음, 실제는 복잡 분개 시 검증
    print(f"\n[검증] 총 거래 금액: {total_debit:,}원")


if __name__ == "__main__":
    main()
```

### 검증 체크리스트

```
실행 후 반드시 확인:
[ ] journal_entries.csv 열어서 샘플 10건 계정 맞는지 확인
[ ] "기본분류" 건을 모두 열어서 수동 계정 지정
[ ] 입금/출금 금액 합계가 원본 bank_statement.csv와 일치하는지
[ ] 고금액 거래(예: 1천만원 이상)는 개별 확인
```

---

## 6.4 예산 vs 실적 편차 분석

**Copilot 프롬프트**:
```
Python 스크립트 작성. pandas + openpyxl 사용.

입력 파일:
- budget.csv: 계정코드, 계정명, 부서코드, 연간예산
- actuals.csv: 계정코드, 계정명, 부서코드, 월(1~12), 실적금액

처리:
1. actuals를 연간 누계로 집계 (groupby 계정코드+부서코드, sum)
2. budget과 LEFT JOIN (계정코드 + 부서코드 기준)
3. 편차 = 실적 - 예산
4. 달성률 = 실적 / 예산 × 100 (예산이 0이면 NaN → "N/A" 문자열)
5. 편차 절대값 상위 20개 별도 추출

출력: variance_report.xlsx
- 시트1 "전체": 모든 편차 테이블
- 시트2 "TOP20": 편차 상위 20개
- 조건부 서식: 달성률 < 80%면 빨간 배경, > 120%면 노란 배경 (openpyxl 적용)
- 금액 컬럼: 천 단위 구분자 서식 (#,##0)

전체 스크립트 + 주석.
```

### 핵심 pandas 패턴

```python
import pandas as pd
from openpyxl import load_workbook
from openpyxl.styles import PatternFill, numbers
from openpyxl.utils import get_column_letter

# 데이터 읽기 및 집계
budget  = pd.read_csv("budget.csv",  encoding="utf-8-sig")
actuals = pd.read_csv("actuals.csv", encoding="utf-8-sig")

# 실적 연간 누계
actuals_ytd = (
    actuals
    .groupby(["계정코드", "계정명", "부서코드"])["실적금액"]
    .sum()
    .reset_index()
    .rename(columns={"실적금액": "실적누계"})
)

# 예산과 병합 (LEFT JOIN)
merged = budget.merge(
    actuals_ytd,
    on=["계정코드", "부서코드"],
    how="left"
)
merged["실적누계"] = merged["실적누계"].fillna(0)

# 편차, 달성률 계산
merged["편차"] = merged["실적누계"] - merged["연간예산"]
merged["달성률(%)"] = (
    merged.apply(
        lambda r: round(r["실적누계"] / r["연간예산"] * 100, 1)
        if r["연간예산"] != 0 else None,
        axis=1
    )
)

# TOP 20
top20 = merged.reindex(
    merged["편차"].abs().nlargest(20).index
)

# Excel 저장
with pd.ExcelWriter("variance_report.xlsx", engine="openpyxl") as writer:
    merged.to_excel(writer, sheet_name="전체", index=False)
    top20.to_excel(writer, sheet_name="TOP20", index=False)

# 조건부 서식 적용
wb = load_workbook("variance_report.xlsx")
ws = wb["전체"]

RED_FILL    = PatternFill("solid", fgColor="FFC7CE")
YELLOW_FILL = PatternFill("solid", fgColor="FFEB9C")

# 달성률 컬럼 인덱스 찾기
headers = [cell.value for cell in ws[1]]
rate_col = headers.index("달성률(%)") + 1  # 1-based

for row in ws.iter_rows(min_row=2, max_row=ws.max_row):
    rate_cell = row[rate_col - 1]
    if isinstance(rate_cell.value, (int, float)):
        if rate_cell.value < 80:
            rate_cell.fill = RED_FILL
        elif rate_cell.value > 120:
            rate_cell.fill = YELLOW_FILL

wb.save("variance_report.xlsx")
print("variance_report.xlsx 생성 완료.")
```

---

## 6.5 감사 샘플링 스크립트

외부 감사 또는 내부 감사에서 사용하는 **층화 샘플링** 스크립트입니다.

```python
"""
감사 샘플링 스크립트 (층화 샘플링)
입력: transactions.csv (id, tx_date, account_code, amount, dept_code)
출력: audit_sample.xlsx
"""

import pandas as pd
import random

SEED = 42  # 재현 가능성을 위한 고정 시드

def stratified_audit_sample(df: pd.DataFrame) -> pd.DataFrame:
    """금액 기준 층화 샘플링."""
    random.seed(SEED)

    samples = []

    # 층 1: 1억 이상 → 전수 조사
    tier1 = df[df["amount"] >= 100_000_000].copy()
    tier1["sampling_tier"]   = "전수(1억+)"
    tier1["sampling_reason"] = "금액 기준 전수"
    samples.append(tier1)

    # 층 2: 1천만~1억 미만 → 30% 무작위
    tier2_pool = df[(df["amount"] >= 10_000_000) & (df["amount"] < 100_000_000)]
    n2 = max(1, int(len(tier2_pool) * 0.30))
    tier2 = tier2_pool.sample(n=n2, random_state=SEED).copy()
    tier2["sampling_tier"]   = "30%(1천만~1억)"
    tier2["sampling_reason"] = "무작위 30% 추출"
    samples.append(tier2)

    # 층 3: 1천만 미만 → 10% 무작위
    tier3_pool = df[df["amount"] < 10_000_000]
    n3 = max(1, int(len(tier3_pool) * 0.10))
    tier3 = tier3_pool.sample(n=n3, random_state=SEED).copy()
    tier3["sampling_tier"]   = "10%(1천만미만)"
    tier3["sampling_reason"] = "무작위 10% 추출"
    samples.append(tier3)

    return pd.concat(samples, ignore_index=True)


def main():
    df = pd.read_csv("transactions.csv", encoding="utf-8-sig")
    df["amount"] = pd.to_numeric(
        df["amount"].astype(str).str.replace(",", ""), errors="coerce"
    ).fillna(0)

    sample = stratified_audit_sample(df)

    # 요약 통계
    print("\n=== 감사 샘플링 결과 ===")
    for tier in sample["sampling_tier"].unique():
        t = sample[sample["sampling_tier"] == tier]
        pool_size = len(df[df["amount"] >= (
            100_000_000 if "1억+" in tier else
            10_000_000  if "1천만" in tier else 0
        )])
        print(f"\n{tier}")
        print(f"  모집단: {len(df):,}건 / 샘플: {len(t):,}건")
        print(f"  샘플 금액 합계: {t['amount'].sum():,.0f}원")

    print(f"\n총 샘플: {len(sample):,}건")
    print(f"샘플 금액 / 전체 금액: "
          f"{sample['amount'].sum() / df['amount'].sum() * 100:.1f}%")

    # Excel 저장
    with pd.ExcelWriter("audit_sample.xlsx", engine="openpyxl") as writer:
        sample.to_excel(writer, sheet_name="샘플목록", index=False)

        # 층별 요약
        summary = (
            sample.groupby("sampling_tier")
            .agg(건수=("id", "count"), 금액합계=("amount", "sum"))
            .reset_index()
        )
        summary.to_excel(writer, sheet_name="층별요약", index=False)

    print("audit_sample.xlsx 저장 완료.")


if __name__ == "__main__":
    main()
```

---

## 6.6 매입매출 매칭 스크립트

**Copilot 프롬프트**:
```
Python 스크립트 작성. pandas 사용.

목적: 매입 전표와 매출 전표의 자동 매칭 (거래처 + 품목 + 금액 기준)

입력:
- sales.csv: 거래일자, 거래처코드, 품목코드, 금액
- purchases.csv: 거래일자, 거래처코드, 품목코드, 금액

매칭 기준: 거래처코드 + 품목코드 + 금액 동일
날짜 범위: 최대 30일 차이 허용 (매출 날짜 기준 ±30일 이내 매입)

출력:
- matched.csv: 매칭된 쌍 (매출 정보 + 매입 정보)
- unmatched_sales.csv: 미매칭 매출
- unmatched_purchases.csv: 미매칭 매입

콘솔 출력: 매칭률, 미매칭 금액 합계
```

### 핵심 매칭 로직

```python
import pandas as pd

sales     = pd.read_csv("sales.csv",     encoding="utf-8-sig")
purchases = pd.read_csv("purchases.csv", encoding="utf-8-sig")

# 날짜 변환
for df in [sales, purchases]:
    df["거래일자"] = pd.to_datetime(df["거래일자"])

# 정확 매칭 (거래처 + 품목 + 금액)
merged = sales.merge(
    purchases,
    on=["거래처코드", "품목코드", "금액"],
    suffixes=("_매출", "_매입"),
    how="outer",
    indicator=True
)

# 날짜 범위 필터 (±30일)
matched = merged[merged["_merge"] == "both"].copy()
matched["날짜차이"] = (
    matched["거래일자_매출"] - matched["거래일자_매입"]
).dt.days.abs()
matched = matched[matched["날짜차이"] <= 30]

# 미매칭 분리
sales_ids     = set(matched.index)
purchase_ids  = set(matched.index)

unmatched_sales     = sales[~sales.index.isin(sales_ids)]
unmatched_purchases = purchases[~purchases.index.isin(purchase_ids)]

# 저장
matched.to_csv("matched.csv",                index=False, encoding="utf-8-sig")
unmatched_sales.to_csv("unmatched_sales.csv",     index=False, encoding="utf-8-sig")
unmatched_purchases.to_csv("unmatched_purchases.csv", index=False, encoding="utf-8-sig")

# 통계
total_sales = len(sales)
matched_cnt = len(matched)
print(f"매칭률: {matched_cnt / total_sales * 100:.1f}% ({matched_cnt}/{total_sales})")
print(f"미매칭 매출 금액: {unmatched_sales['금액'].sum():,.0f}원")
print(f"미매칭 매입 금액: {unmatched_purchases['금액'].sum():,.0f}원")
```

---

## 6.7 Excel과 데이터 왕복

Python 결과를 기존 Excel 파일의 특정 시트에 쓰거나, Excel에서 Python으로 데이터를 가져오는 패턴입니다.

### Excel 읽기 (특정 시트, 특정 범위)

```python
import pandas as pd

# 시트 이름으로 읽기
df = pd.read_excel("마감준비_2026-06.xlsx", sheet_name="원장")

# 여러 시트 동시 읽기
sheets = pd.read_excel("마감준비_2026-06.xlsx", sheet_name=None)
for name, data in sheets.items():
    print(f"{name}: {len(data)}행")

# 특정 행/열 범위 (skiprows, usecols)
df = pd.read_excel(
    "report.xlsx",
    sheet_name="집계",
    skiprows=2,          # 상단 2행 건너뜀
    usecols="A:F",       # A~F열만
    nrows=100            # 최대 100행
)
```

### Excel 기존 파일에 시트 추가 (기존 내용 유지)

```python
from openpyxl import load_workbook
import pandas as pd

# 기존 파일 열기 (덮어쓰기 방지)
with pd.ExcelWriter(
    "마감준비_2026-06.xlsx",
    engine="openpyxl",
    mode="a",            # append 모드
    if_sheet_exists="replace"
) as writer:
    result_df.to_excel(writer, sheet_name="Python집계결과", index=False)
```

### Copilot 프롬프트 - Excel 왕복

```
Python 스크립트 작성. pandas + openpyxl 사용.

목적: "마감준비_2026-06.xlsx"의 "원장" 시트를 읽어서
      계정코드별 월별 집계를 생성하고
      동일 파일의 "Python집계" 시트에 저장

처리:
1. 원장 시트 읽기 (전표일자, 계정코드, 계정명, 부서코드, 차변, 대변)
2. 전표일자 → 월 추출
3. 계정코드 + 월 기준 차변/대변 합계 집계
4. 잔액 = 계정유형에 따라 (수익: 대변-차변, 비용: 차변-대변)
5. 피벗 테이블 형태 (행: 계정코드, 열: 월)

저장: 기존 파일의 "Python집계" 시트 (없으면 생성, 있으면 덮어씀)
헤더 서식: 굵은 글씨, 회색 배경
금액 서식: 천 단위 구분자
```

---

## 6.8 실습: 카드 명세 → 자동 분개 CSV

### 샘플 데이터 생성

먼저 Copilot에게 샘플 카드 명세 CSV를 만들어달라고 요청합니다:

```
CSV 샘플 데이터 생성. 법인카드 명세서 형식.

헤더: 거래일자,가맹점명,업종,출금금액,잔액
데이터 30행:
- 날짜: 2026-06-01 ~ 2026-06-30
- 가맹점명 예시: 스타벅스, 쿠팡비즈, GS칼텍스, 제주항공, 롯데호텔, 한국전력, KT, 올리브영 등
- 업종: 음식/커피, 사무용품, 주유, 항공, 숙박, 공과금, 통신, 복리후생

CSV 형식으로 30행 출력.
```

### 분개 규칙 설정 파일 만들기

```
Python 스크립트의 분개 규칙을 별도 JSON 파일로 관리하는 방식 작성.

파일명: classification_rules.json

구조:
{
  "keyword_rules": [
    {"keyword": "스타벅스", "account_code": "5180", "account_name": "복리후생비"},
    {"keyword": "항공", "account_code": "5190", "account_name": "여비교통비"},
    ...
  ],
  "industry_rules": [
    {"industry": "주유", "account_code": "5200", "account_name": "차량유지비"},
    ...
  ],
  "default_debit": {"account_code": "5100", "account_name": "일반경비"}
}

20개 규칙 포함. JSON 형식으로 출력.
```

### 스크립트 실행 단계

1. `card_statement.csv` 생성 (샘플 데이터 붙여넣기)
2. `classification_rules.json` 생성 (규칙 파일)
3. Copilot에게 메인 스크립트 요청:

```
Python 스크립트 작성. pandas 사용.

목적: 법인카드 명세서 → 회계 분개 CSV

입력:
- card_statement.csv (거래일자, 가맹점명, 업종, 출금금액, 잔액)
- classification_rules.json (위에서 만든 규칙 파일)

처리:
1. JSON 규칙 로드
2. keyword_rules 먼저 적용 (가맹점명 부분 일치)
3. 매칭 안 되면 industry_rules 적용 (업종 일치)
4. 둘 다 안 되면 default 적용
5. 차변 = 분류된 계정, 대변 = 법인카드미지급금(2150)

출력: card_journal_YYYYMMDD.csv
컬럼: 거래일자, 가맹점명, 차변계정코드, 차변계정명, 대변계정코드, 대변계정명, 금액, 분류방법

통계: 가맹점별 집계, 계정과목별 집계 콘솔 출력
```

4. 실행 후 결과 검증:
   - [ ] 30건 모두 분개됐는지 확인
   - [ ] "기본분류" 비율 확인 (30% 초과면 규칙 보완 필요)
   - [ ] 금액 합계가 원본과 일치하는지
   - [ ] 고금액 건 3개 이상 수동 검토

---

## 핵심 포인트

1. **pandas 프롬프트 5요소**: 입력 + 처리 + 규칙 + 출력 + 예외 처리
2. **분류 규칙은 딕셔너리/JSON으로 관리**: 코드 변경 없이 규칙만 수정 가능
3. **"기본분류" 건은 항상 수동 검토**: 자동화는 80~90%만 처리, 나머지는 사람
4. **감사 샘플링에 random seed 고정**: 재현 가능성 확보, 감사 증적 유지
5. **Excel 왕복은 append 모드**: 기존 시트 보존하면서 결과 시트만 추가

---

**다음**: [07-report-automation.md](./07-report-automation.md) — 월/분기 리포트 자동화
