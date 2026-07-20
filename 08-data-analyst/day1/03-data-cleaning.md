# 03. 데이터 클리닝 — 결측치·이상치·중복·타입 처리

## 학습 목표

- 실무 데이터 오염 4가지(결측치/이상치/중복/타입 불일치)의 원인과 탐지 방법 파악
- SQL 클리닝 vs Python(pandas) 클리닝의 선택 기준 체득
- Copilot으로 데이터 오디팅 쿼리와 클리닝 코드를 빠르게 생성
- 지저분한 CSV 3개를 클린 데이터로 변환하는 실습 완료

**예상 소요**: 60분

---

## 3.1 왜 클리닝이 분析의 80%인가

"데이터를 믿을 수 없으면 분析 결과도 믿을 수 없다"는 말은 진부하지만 사실입니다.
분析가가 잘못된 수치를 보고하면 신뢰를 잃습니다. 한 번 잃은 신뢰는 되찾기 어렵습니다.

실무에서 흔히 마주치는 오염 사례:

| 오염 유형 | 현실적인 예 | 발견 안 하면 |
|---------|-----------|-----------|
| 결측치 | 구독 취소 후 plan 컬럼이 NULL | 이탈률 계산에서 일부 사용자가 제외됨 |
| 이상치 | 금액이 99999999 (테스트 데이터) | MRR이 실제보다 수백 배 높게 나옴 |
| 중복 | 웹훅 재전송으로 같은 이벤트 두 번 | 퍼널 전환율이 100% 초과 |
| 타입 불일치 | 날짜가 '2024/01/05' (슬래시 구분) | DATE 함수 오류, 기간 필터 안 됨 |

**클리닝 원칙**:
1. 먼저 오염 현황을 **탐지(Detect)**
2. 처리 방법을 **결정(Decide)** (제거 / 대체 / 플래그)
3. 처리를 **적용(Apply)**
4. 처리 전후 결과를 **검증(Verify)**

---

## 3.2 데이터 오디팅: 새 데이터를 받으면 첫 5분

새 테이블이나 CSV를 받으면 분析 시작 전에 반드시 아래 오디팅을 먼저 수행합니다.

### SQL 오디팅 쿼리

```sql
-- ============================================================
-- 데이터 품질 오디팅 템플릿 (PostgreSQL)
-- [테이블명], [컬럼목록] 교체해서 사용
-- ============================================================

-- 1. 전체 행 수
SELECT COUNT(*) AS total_rows FROM [테이블명];

-- 2. 컬럼별 NULL 수 및 비율
SELECT
    COUNT(*) AS total,
    COUNT(user_id)       AS user_id_non_null,
    COUNT(*) - COUNT(user_id) AS user_id_null,
    ROUND((COUNT(*) - COUNT(user_id))::NUMERIC / COUNT(*) * 100, 2) AS user_id_null_pct,
    COUNT(event_date)    AS event_date_non_null,
    COUNT(*) - COUNT(event_date) AS event_date_null,
    ROUND((COUNT(*) - COUNT(event_date))::NUMERIC / COUNT(*) * 100, 2) AS event_date_null_pct
    -- 컬럼 추가 시 같은 패턴 반복
FROM [테이블명];

-- 3. 숫자형 컬럼 기초 통계
SELECT
    MIN(amount)    AS min_amount,
    MAX(amount)    AS max_amount,
    AVG(amount)    AS avg_amount,
    STDDEV(amount) AS std_amount,
    PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY amount) AS q1,
    PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY amount) AS median,
    PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY amount) AS q3
FROM [테이블명]
WHERE amount IS NOT NULL;

-- 4. 날짜형 컬럼 범위
SELECT
    MIN(event_date) AS earliest,
    MAX(event_date) AS latest,
    MAX(event_date) - MIN(event_date) AS date_range_days
FROM [테이블명];

-- 5. 중복 행 탐지
SELECT
    user_id, event_date, event_name,
    COUNT(*) AS duplicate_count
FROM [테이블명]
GROUP BY user_id, event_date, event_name
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC
LIMIT 20;
```

### Copilot 프롬프트

```
PostgreSQL. 다음 테이블의 데이터 품질 오디팅 SQL을 작성해줘.

테이블: events(event_id BIGINT, user_id BIGINT, event_name VARCHAR, event_date TIMESTAMP, amount NUMERIC)

포함 항목:
- 전체 행 수
- 컬럼별 NULL 수 및 NULL 비율(%)
- amount의 MIN/MAX/AVG/STDDEV/Q1/MEDIAN/Q3
- event_date 범위(최솟값, 최댓값, 기간)
- user_id + event_date + event_name 조합 중복 탐지 (상위 20개)
- event_name 고유값 목록 및 각 빈도
```

---

## 3.3 결측치 처리

### 결측치 탐지

```sql
-- 컬럼별 결측치 현황 요약 (PostgreSQL)
SELECT
    'plan'       AS column_name, COUNT(*) FILTER (WHERE plan IS NULL)        AS null_count FROM users
UNION ALL
SELECT
    'country'    AS column_name, COUNT(*) FILTER (WHERE country IS NULL)     AS null_count FROM users
UNION ALL
SELECT
    'channel'    AS column_name, COUNT(*) FILTER (WHERE channel IS NULL)     AS null_count FROM users;
```

### 결측치 처리 방법 결정 기준

| 상황 | 처리 방법 |
|------|---------|
| 비율 5% 미만, 무작위 결측 | 해당 행 제거 (DROP) |
| 비율 5~20%, 패턴 있음 | 대체값으로 채우기 (IMPUTE) |
| 비율 20% 초과 | 별도 컬럼으로 플래그 처리 후 분析 방법 재검토 |
| 비즈니스 로직상 의미 있는 NULL | 'unknown' 또는 '(none)'으로 명시적 표시 |

### SQL에서 결측치 채우기

```sql
-- COALESCE: NULL을 대체값으로
SELECT
    user_id,
    COALESCE(country, 'unknown') AS country,
    COALESCE(channel, 'direct')  AS channel,
    COALESCE(amount, 0)          AS amount
FROM users;

-- NULLIF: 특정 값을 NULL로 변환 (예: 빈 문자열을 NULL로)
SELECT
    user_id,
    NULLIF(TRIM(country), '') AS country  -- 공백만 있는 값을 NULL로
FROM users;

-- 그룹별 중앙값으로 채우기 (Window Function 활용)
WITH medians AS (
    SELECT
        plan,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY amount) AS median_amount
    FROM payments
    WHERE amount IS NOT NULL
    GROUP BY plan
)
SELECT
    p.user_id,
    p.plan,
    COALESCE(p.amount, m.median_amount) AS amount_filled
FROM payments p
LEFT JOIN medians m ON p.plan = m.plan;
```

---

## 3.4 이상치 처리

### IQR 방법 (분析가에게 가장 실용적)

IQR(Interquartile Range) = Q3 - Q1
이상치 기준: Q1 - 1.5×IQR 미만 또는 Q3 + 1.5×IQR 초과

```sql
-- IQR 방식 이상치 탐지 (PostgreSQL)
WITH stats AS (
    SELECT
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY amount) AS q1,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY amount) AS q3
    FROM payments
    WHERE amount IS NOT NULL
),
bounds AS (
    SELECT
        q1,
        q3,
        q3 - q1                   AS iqr,
        q1 - 1.5 * (q3 - q1)     AS lower_bound,
        q3 + 1.5 * (q3 - q1)     AS upper_bound
    FROM stats
)
SELECT
    b.lower_bound,
    b.upper_bound,
    COUNT(*) FILTER (WHERE p.amount < b.lower_bound OR p.amount > b.upper_bound) AS outlier_count,
    COUNT(*) AS total_count,
    ROUND(COUNT(*) FILTER (WHERE p.amount < b.lower_bound OR p.amount > b.upper_bound)::NUMERIC / COUNT(*) * 100, 2) AS outlier_pct
FROM payments p
CROSS JOIN bounds b;
```

### 이상치 처리 선택지

```sql
-- 선택 1: 제거 (분析에서 제외)
DELETE FROM payments
WHERE amount < [lower_bound] OR amount > [upper_bound];

-- 선택 2: 플래그 표시 (제거하지 않고 분析 시 필터)
ALTER TABLE payments ADD COLUMN is_outlier BOOLEAN DEFAULT FALSE;

UPDATE payments SET is_outlier = TRUE
WHERE amount < [lower_bound] OR amount > [upper_bound];

-- 이후 분析에서:
SELECT * FROM payments WHERE is_outlier = FALSE;

-- 선택 3: 경계값으로 대체 (Winsorizing)
UPDATE payments
SET amount = CASE
    WHEN amount < [lower_bound] THEN [lower_bound]
    WHEN amount > [upper_bound] THEN [upper_bound]
    ELSE amount
END;
```

**권장**: 제거보다 **플래그 표시**가 안전합니다. 나중에 "왜 이 행이 없냐"는 질문을 받을 때 설명이 가능합니다.

---

## 3.5 중복 제거

### 중복의 3가지 원인

1. **데이터 수집 중복**: 웹훅 재전송, ETL 재실행
2. **기준 불일치**: "같은 이벤트"의 정의가 다름 (같은 분·초도 다른 이벤트?)
3. **조인 곱집합**: 1:多 관계 테이블을 잘못 조인하면 행이 곱으로 증가

### SQL 중복 제거

```sql
-- 중복 현황 먼저 파악
SELECT
    user_id,
    event_date::DATE,
    event_name,
    COUNT(*) AS cnt
FROM events
GROUP BY user_id, event_date::DATE, event_name
HAVING COUNT(*) > 1
ORDER BY cnt DESC
LIMIT 20;

-- 중복 제거 (event_id 가장 큰 것 = 최신 것 보존)
WITH deduped AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY user_id, event_date::DATE, event_name
            ORDER BY event_id DESC  -- 최신 ID 보존
        ) AS rn
    FROM events
)
SELECT * FROM deduped WHERE rn = 1;

-- DELETE로 직접 제거 (주의: read-only 환경에서는 불가)
DELETE FROM events
WHERE event_id NOT IN (
    SELECT MAX(event_id)
    FROM events
    GROUP BY user_id, event_date::DATE, event_name
);
```

**Copilot이 자주 틀리는 중복 제거 실수**:
```sql
-- ❌ GROUP BY로 MAX를 뽑을 때 다른 컬럼이 누락되는 경우
SELECT user_id, MAX(event_id), event_name  -- event_name이 GROUP BY에 없으면 오류
FROM events GROUP BY user_id;

-- ✅ ROW_NUMBER() 방식이 모든 컬럼을 보존하면서 안전
```

---

## 3.6 타입 불일치 처리

### 자주 발생하는 타입 문제

```sql
-- 문제 1: 날짜가 VARCHAR로 저장됨
-- '2024/01/05', '20240105', 'Jan 5, 2024' 등 다양한 형식

-- PostgreSQL에서 형식별 변환
SELECT
    TO_DATE('2024/01/05', 'YYYY/MM/DD') AS slash_format,
    TO_DATE('20240105', 'YYYYMMDD')     AS compact_format,
    TO_DATE('Jan 5, 2024', 'Mon DD, YYYY') AS text_format;

-- 변환 실패 행 탐지 (PostgreSQL 14+)
SELECT event_date_raw
FROM raw_events
WHERE event_date_raw !~ '^\d{4}-\d{2}-\d{2}$';  -- YYYY-MM-DD 형식 아닌 것

-- 문제 2: 금액이 '1,234.56' 또는 '₩1,234' 형식
SELECT REPLACE(REPLACE(amount_raw, ',', ''), '₩', '')::NUMERIC AS amount
FROM raw_payments;

-- 문제 3: 불리언이 0/1 또는 'Y'/'N' 등
SELECT
    CASE WHEN is_active IN ('Y', 'y', '1', 'true', 'True') THEN TRUE ELSE FALSE END AS is_active
FROM raw_users;
```

### 스키마 유효성 검증

```sql
-- plan 컬럼의 허용 외 값 탐지
SELECT DISTINCT plan, COUNT(*) AS cnt
FROM users
WHERE plan NOT IN ('basic', 'pro', 'enterprise')
   OR plan IS NULL
GROUP BY plan;

-- email 형식 검증 (@ 포함 여부)
SELECT user_id, email
FROM users
WHERE email NOT LIKE '%@%'
   OR email LIKE '%@%@%';  -- @ 두 개 이상

-- 음수 금액 탐지 (환불 제외)
SELECT payment_id, amount FROM payments
WHERE amount < 0 AND status != 'refunded';
```

---

## 3.7 SQL 클리닝 vs Python 클리닝

어떤 도구를 써야 할지 결정하는 기준:

| 상황 | 권장 도구 | 이유 |
|------|---------|------|
| DB에 이미 있는 대용량 데이터 | **SQL** | 데이터를 로컬로 가져오지 않아도 됨 |
| CSV 파일로 받은 데이터 | **Python/pandas** | DB 없이 바로 처리 가능 |
| 복잡한 문자열 파싱 (정규표현식) | **Python** | SQL 정규식보다 pandas str가 직관적 |
| 재현 가능한 클리닝 파이프라인 | **Python** | 코드로 버전 관리, 재실행 용이 |
| 즉석 탐색, 숫자 빠른 확인 | **SQL** | 결과가 즉시 보임 |

---

## 3.8 pandas 클리닝 (기초 — 심화는 Day 2)

Day 2에서 pandas를 깊게 다루지만, 클리닝 맥락에서 꼭 알아야 할 것만 먼저 소개합니다.

```python
import pandas as pd

# 1. CSV 로드
df = pd.read_csv('raw_data.csv', parse_dates=['signup_date', 'last_login'])

# 2. 기초 탐색
print(df.shape)          # (행 수, 열 수)
print(df.dtypes)         # 각 컬럼 타입
print(df.isnull().sum()) # 컬럼별 NULL 수
print(df.duplicated().sum())  # 중복 행 수

# 3. 헤더 정제
df.columns = df.columns.str.lower().str.replace(' ', '_').str.strip()

# 4. 금액 컬럼 정제 (쉼표, 원화기호 제거)
df['amount'] = df['amount'].astype(str).str.replace(',', '').str.replace('₩', '').astype(float)

# 5. 결측치 처리
df['country'] = df['country'].fillna('unknown')
df['amount']  = df['amount'].fillna(0)
df = df.dropna(subset=['user_id', 'signup_date'])  # 필수 컬럼 NULL이면 행 제거

# 6. 중복 제거 (signup_date 기준 최신 행 보존)
df = df.sort_values('signup_date', ascending=False)
df = df.drop_duplicates(subset=['user_id'], keep='first').copy()
# .copy() 필수: SettingWithCopyWarning 방지

# 7. 타입 변환
df['signup_date'] = pd.to_datetime(df['signup_date'], errors='coerce')
# errors='coerce': 변환 실패 → NaT (오류 아님)

# 8. 이상치 플래그
q1 = df['amount'].quantile(0.25)
q3 = df['amount'].quantile(0.75)
iqr = q3 - q1
df = df.copy()
df['is_outlier'] = (df['amount'] < q1 - 1.5 * iqr) | (df['amount'] > q3 + 1.5 * iqr)

# 9. 저장
df.to_csv('clean_data.csv', index=False)
print(f"클리닝 완료: {len(df)}행, {df['is_outlier'].sum()}개 이상치 플래그")
```

### SettingWithCopyWarning: Copilot이 자주 유발하는 문제

```python
# ❌ 경고 발생 (chained assignment)
df_filtered = df[df['plan'] == 'pro']
df_filtered['price'] = 19.99  # SettingWithCopyWarning!

# ✅ 해결 1: .copy() 추가
df_filtered = df[df['plan'] == 'pro'].copy()
df_filtered['price'] = 19.99  # 경고 없음

# ✅ 해결 2: .loc 사용
df.loc[df['plan'] == 'pro', 'price'] = 19.99  # 원본 df에 직접 적용
```

**Copilot에 명시적으로 요청**:
```python
# 프롬프트에 항상 추가:
# "SettingWithCopyWarning 없이, 슬라이싱 후 .copy() 사용"
```

---

## 3.9 실습: 지저분한 CSV 3개 클리닝

아래 3개 가상 CSV 데이터를 각각 정제합니다.
실제 파일 없이 코드 안에서 데이터를 직접 만들어서 실습합니다.

### 실습 1. 사용자 등록 데이터 (타입 + 결측치 문제)

**Copilot 프롬프트**:
```
pandas로 아래 지저분한 사용자 데이터를 클리닝하는 Python 코드 작성.
SettingWithCopyWarning 없이.

입력 데이터 (코드 안에서 직접 DataFrame 생성):
user_id: [101, 102, 103, 104, 105, 102]
email: ['alice@example.com', 'bob@example.com', '', 'dave@example.com', 'EVE@EXAMPLE.COM', 'bob@example.com']
signup_date: ['2024/01/15', '2024-02-20', '20240310', None, '2024-04-05', '2024-02-20']
plan: ['Pro', 'basic', 'ENTERPRISE', 'pro', None, 'basic']
amount: ['1,200', '9.99', '49,999', '-5', '19.99', '9.99']

클리닝 항목:
1. email 소문자화, 빈 문자열 → NaN, 형식 검증(@ 포함 여부)
2. signup_date를 datetime으로 통일 변환
3. plan 소문자화, 허용값(basic/pro/enterprise) 외는 'unknown'
4. amount 쉼표 제거 후 float 변환, 음수 → NaN
5. user_id 중복 제거 (signup_date 최신 기준 유지)
6. 클리닝 전후 통계 출력
```

**예상 생성 코드 구조**:

```python
import pandas as pd
import numpy as np

# 데이터 생성
raw_data = {
    'user_id':     [101, 102, 103, 104, 105, 102],
    'email':       ['alice@example.com', 'bob@example.com', '', 'dave@example.com', 'EVE@EXAMPLE.COM', 'bob@example.com'],
    'signup_date': ['2024/01/15', '2024-02-20', '20240310', None, '2024-04-05', '2024-02-20'],
    'plan':        ['Pro', 'basic', 'ENTERPRISE', 'pro', None, 'basic'],
    'amount':      ['1,200', '9.99', '49,999', '-5', '19.99', '9.99']
}

df_raw = pd.DataFrame(raw_data)
print(f"원본: {len(df_raw)}행")

# 클리닝 시작 (.copy()로 원본 보호)
df = df_raw.copy()

# 1. email 정제
df['email'] = df['email'].str.lower().str.strip()
df['email'] = df['email'].replace('', np.nan)
df['email_valid'] = df['email'].notna() & df['email'].str.contains('@', na=False)

# 2. signup_date 통일 변환
df['signup_date'] = pd.to_datetime(df['signup_date'], errors='coerce', infer_datetime_format=True)

# 3. plan 정제
df['plan'] = df['plan'].str.lower().str.strip()
df['plan'] = df['plan'].where(df['plan'].isin(['basic', 'pro', 'enterprise']), other='unknown')

# 4. amount 정제
df['amount'] = df['amount'].astype(str).str.replace(',', '').astype(float)
df['amount'] = df['amount'].where(df['amount'] >= 0, other=np.nan)

# 5. 중복 제거
df = df.sort_values('signup_date', ascending=False, na_position='last')
df = df.drop_duplicates(subset=['user_id'], keep='first').copy()

# 결과 출력
print(f"클리닝 후: {len(df)}행")
print(df.dtypes)
print(df)
```

### 실습 2. 결제 로그 (중복 + 이상치 문제)

**Copilot 프롬프트**:
```
pandas로 결제 로그 데이터를 클리닝하는 Python 코드.
SettingWithCopyWarning 없이.

데이터 (코드 안에서 생성):
payment_id: [1, 2, 3, 4, 5, 3, 6]  ← payment_id=3 중복
user_id:    [101, 102, 103, 104, 105, 103, 106]
amount:     [19.99, 9.99, 49.99, 99999999, 19.99, 49.99, -10.0]
paid_at:    ['2024-01-15', '2024-01-16', '2024-01-17', '2024-01-18', '2024-01-19', '2024-01-17', '2024-01-20']
status:     ['success', 'success', 'success', 'success', 'success', 'success', 'refunded']

클리닝:
1. payment_id 중복 제거 (payment_id 기준, 중복은 제거)
2. paid_at을 datetime으로 변환
3. IQR 방식 이상치 탐지 (is_outlier 컬럼 추가, 제거는 하지 않음)
4. 음수 amount 중 status='refunded'는 허용, 그 외는 NaN
5. 클리닝 요약 통계 출력
```

### 실습 3. 이벤트 로그 (타입 + 날짜 갭 문제)

**Copilot 프롬프트**:
```
pandas로 이벤트 로그를 클리닝 + 탐색하는 Python 코드.

데이터 (코드 안에서 생성, 날짜는 2024-01-01 ~ 2024-01-31 범위로 랜덤):
import numpy as np
np.random.seed(42)
n = 200
events_data = {
    'event_id': range(1, n+1),
    'user_id': np.random.choice([101, 102, 103, 104, 105], n),
    'event_name': np.random.choice(['login', 'feature_use', 'upgrade_click', None, 'LOGOUT'], n),
    'event_date': pd.date_range('2024-01-01', periods=n, freq='3H'),
    'session_id': [f'sess_{np.random.randint(1,50):03d}' for _ in range(n)]
}

클리닝:
1. event_name 소문자화, None → 'unknown'
2. event_date를 날짜(date)와 시간(hour) 컬럼으로 분리
3. 동일 user_id + event_date + event_name 조합 중복 제거
4. 날짜별 이벤트 수 집계 + 0인 날짜 탐지 (갭 확인)
5. event_name별 빈도 상위 5개 출력
```

---

## 3.10 클리닝 루틴 정착시키기

매번 새 데이터를 받을 때 반복하는 작업을 **오디팅 노트북 템플릿**으로 만들어두면 30분이 5분으로 줄어듭니다.

**Copilot 프롬프트**:
```
pandas + Jupyter Notebook용 데이터 오디팅 함수 모음을 작성해줘.

함수 1: audit_dataframe(df) — 기초 통계 출력
함수 2: find_outliers(df, col, method='iqr') — IQR 이상치 탐지
함수 3: clean_text_column(series) — 소문자화 + 공백 제거 + 빈값 → NaN
함수 4: safe_to_datetime(series) — 다양한 날짜 형식 자동 변환, 실패 → NaT
함수 5: remove_duplicates(df, key_cols, keep='latest', date_col=None) — 안전한 중복 제거

각 함수에 docstring + 사용 예시 주석 포함.
SettingWithCopyWarning 없이.
```

---

## 핵심 포인트

1. **클리닝 4단계**: 탐지(Detect) → 결정(Decide) → 적용(Apply) → 검증(Verify)
2. **이상치는 제거보다 플래그**: 나중에 "왜 이 행이 없냐"는 질문에 답해야 함
3. **SQL vs pandas 선택**: DB 데이터는 SQL, CSV 파일은 pandas. 복잡한 문자열 파싱은 Python 우세
4. **SettingWithCopyWarning**: 슬라이싱 후 `.copy()` 추가가 해결책. Copilot 프롬프트에 명시하면 처음부터 올바르게 생성
5. **중복 제거**: ROW_NUMBER() 방식이 모든 컬럼을 보존하면서 가장 안전. Copilot이 GROUP BY + MAX 방식으로 생성하면 다른 컬럼 누락 확인

---

**다음 챕터**: [04-day1-lab.md](./04-day1-lab.md) — Day 1 종합 실습: 월간 사용자 리포트
