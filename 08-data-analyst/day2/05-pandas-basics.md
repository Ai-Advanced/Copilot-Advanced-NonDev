# 05. pandas 실전 기초 — 분析가를 위한 Python 후처리

## 학습 목표

- SQL 결과를 pandas로 이어받아 후처리하는 흐름 체득
- read_csv / filter / groupby / pivot / merge / apply 6가지 핵심 연산 숙달
- Jupyter Notebook에서 분析 흐름을 구조화하는 방법 파악
- Copilot으로 pandas 코드를 프롬프팅할 때 정확한 결과를 얻는 패턴 학습
- 실습 5개 완성: SQL 결과 → pandas 후처리

**예상 소요**: 75분

---

## 5.1 왜 SQL만으로 부족한가

SQL은 데이터를 집계하고 필터하는 데 강력하지만, 이런 작업은 어렵습니다.

| 작업 | SQL | pandas |
|------|-----|--------|
| 기본 집계, 필터, 조인 | ★★★★★ | ★★★★☆ |
| 복잡한 문자열 파싱 | ★★★☆☆ | ★★★★★ |
| 피벗/언피벗 | ★★★☆☆ (방언 의존) | ★★★★★ |
| 여러 집계 결과를 나란히 비교 | ★★☆☆☆ | ★★★★★ |
| 시각화 연계 | ✗ | ★★★★★ |
| 반복 실행 스크립트 | ★★★☆☆ | ★★★★★ |
| 통계 검정 | ✗ | ★★★★★ |

**실무 흐름**: SQL로 원하는 데이터 형태를 최대한 만들고, pandas는 후처리와 시각화에만 씁니다.
pandas로 수억 행을 직접 처리하려 하지 마세요. DB에서 집계한 결과(수천~수만 행)를 pandas로 받습니다.

---

## 5.2 Jupyter Notebook 기본 설정

### VS Code에서 Jupyter 시작

1. `Ctrl+Shift+P` → "Create: New Jupyter Notebook"
2. 오른쪽 상단 커널 선택 → Python 3.10+
3. 셀 추가: `+Code` 버튼 또는 `B` 키 (명령 모드)
4. 셀 실행: `Shift+Enter`

### Copilot과 Jupyter

Jupyter 셀 안에서도 Inline Chat(`Ctrl+I`)이 작동합니다.
현재 노트북의 이전 셀 내용(import, 변수명 등)을 Copilot이 이해합니다.

```python
# 셀 1: import와 설정
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
import plotly.express as px

# pandas 출력 설정
pd.set_option('display.max_columns', 20)
pd.set_option('display.float_format', '{:.2f}'.format)
pd.set_option('display.max_rows', 100)

print("설정 완료")
```

---

## 5.3 데이터 읽기 (read_csv)

### 기본 읽기

```python
# 기본
df = pd.read_csv('data/users.csv')

# 날짜 컬럼 자동 파싱 (권장)
df = pd.read_csv(
    'data/users.csv',
    parse_dates=['signup_date', 'last_login'],
    dtype={'user_id': 'int64', 'plan': 'str'}
)

# 읽기 후 기초 확인 (항상 이것부터)
print(f"행 수: {len(df):,}")
print(f"열 수: {df.shape[1]}")
print(df.dtypes)
print(df.head(3))
```

### CSV가 아닌 형태로 읽기

```python
# SQL 결과를 직접 DataFrame으로 (DB 연결 있을 때)
import sqlalchemy as sa

engine = sa.create_engine('postgresql://user:pw@host:5432/dbname')

query = """
SELECT user_id, signup_date, plan, SUM(amount) AS total_amount
FROM users u
JOIN payments p ON u.user_id = p.user_id
WHERE signup_date >= '2024-01-01'
GROUP BY user_id, signup_date, plan
"""

df = pd.read_sql(query, engine)

# 엑셀 파일 읽기
df = pd.read_excel('report.xlsx', sheet_name='Sheet1', header=0)
```

### Copilot 프롬프트

```python
# CSV 파일 'data/subscriptions.csv'를 읽는 코드.
# 컬럼: subscription_id, user_id, event_type, plan, event_date, mrr
# event_date는 datetime으로, mrr은 float으로 읽기.
# 읽기 후: 행 수, NULL 현황, event_type 고유값 출력.
```

---

## 5.4 필터링

### 기본 조건 필터

```python
# 단일 조건
df_pro = df[df['plan'] == 'pro'].copy()

# 복합 조건 (and: &, or: |, not: ~)
df_active_pro = df[
    (df['plan'] == 'pro') &
    (df['signup_date'] >= '2024-01-01') &
    (df['amount'] > 0)
].copy()

# isin: 여러 값 중 하나
df_paying = df[df['plan'].isin(['pro', 'enterprise'])].copy()

# ~isin: 특정 값 제외
df_not_basic = df[~df['plan'].isin(['basic'])].copy()

# 날짜 범위 필터
df_march = df[
    (df['signup_date'] >= '2024-03-01') &
    (df['signup_date'] < '2024-04-01')
].copy()

# 결측치 필터
df_valid = df[df['amount'].notna()].copy()
df_nulls = df[df['country'].isna()].copy()
```

### .query() 메서드 (가독성 향상)

```python
# 복잡한 조건을 문자열로 표현
df_filtered = df.query(
    "plan in ['pro', 'enterprise'] and amount > 0 and signup_date >= '2024-01-01'"
).copy()

# 변수 참조 시 @ 사용
min_amount = 10.0
df_filtered = df.query("amount >= @min_amount and plan != 'basic'").copy()
```

---

## 5.5 groupby 집계

### 기본 groupby

```python
# 단일 컬럼 groupby
plan_counts = df.groupby('plan')['user_id'].count().reset_index()
plan_counts.columns = ['plan', 'user_count']

# 여러 집계 함수 동시에
plan_stats = df.groupby('plan').agg(
    user_count  = ('user_id',  'count'),
    total_amount= ('amount',   'sum'),
    avg_amount  = ('amount',   'mean'),
    median_amount=('amount',  'median')
).reset_index()

# 복합 groupby
monthly_plan = df.groupby([
    df['signup_date'].dt.to_period('M').astype(str),
    'plan'
]).agg(
    signups=('user_id', 'nunique')
).reset_index()
monthly_plan.columns = ['year_month', 'plan', 'signups']
```

### Copilot이 자주 틀리는 groupby 실수

```python
# ❌ 문제: agg 후 MultiIndex 컬럼이 남음
result = df.groupby('plan')['amount'].agg(['sum', 'mean', 'count'])
print(result.columns)  # Index(['sum', 'mean', 'count'], dtype='object')
# reset_index 없어서 plan이 index로 남아 있음

# ✅ 해결
result = df.groupby('plan')['amount'].agg(['sum', 'mean', 'count']).reset_index()
result.columns = ['plan', 'amount_sum', 'amount_mean', 'count']

# ❌ 문제: named aggregation에서 컬럼명 충돌
result = df.groupby('plan').agg({'amount': ['sum', 'mean']})
print(result.columns)  # MultiIndex [('amount', 'sum'), ('amount', 'mean')]
# 접근 시: result[('amount', 'sum')] — 불편함

# ✅ 해결: named aggregation 사용
result = df.groupby('plan').agg(
    amount_sum  = ('amount', 'sum'),
    amount_mean = ('amount', 'mean')
).reset_index()
```

### Transform: 그룹 통계를 원본 행에 붙이기

```python
# 각 행에 "같은 plan의 평균 금액"을 붙이기 (SQL Window Function과 동일)
df = df.copy()
df['plan_avg_amount'] = df.groupby('plan')['amount'].transform('mean')

# 각 행이 plan 내에서 몇 번째인지 (ROW_NUMBER와 동일)
df['rank_within_plan'] = df.groupby('plan')['amount'].rank(method='first', ascending=False)
```

---

## 5.6 피벗 테이블

### pivot_table 기본

```python
# 월별 × plan별 신규 가입자 수 피벗
pivot = df.pivot_table(
    index='year_month',    # 행
    columns='plan',        # 열
    values='user_id',      # 값
    aggfunc='nunique',     # 집계 함수
    fill_value=0           # 결측치를 0으로
)

# 합계 행/열 추가
pivot['Total'] = pivot.sum(axis=1)   # 행 합계
pivot.loc['Total'] = pivot.sum(axis=0)  # 열 합계

print(pivot)
```

### 피벗 → 언피벗 (melt)

```python
# 피벗 테이블을 다시 긴 형식(long format)으로
long_df = pivot.reset_index().melt(
    id_vars='year_month',
    var_name='plan',
    value_name='signups'
)
```

### 코호트 리텐션 피벗 (핵심 사례)

```python
# SQL 결과: cohort_month, month_number, retention_rate
retention_raw = pd.read_csv('data/retention_raw.csv')

# 피벗
retention_pivot = retention_raw.pivot_table(
    index='cohort_month',
    columns='month_number',
    values='retention_rate',
    aggfunc='first'
)

# 컬럼명 정리
retention_pivot.columns = [f'month_{int(c)}' for c in retention_pivot.columns]

print(retention_pivot.round(2))
```

---

## 5.7 merge (JOIN)

### LEFT JOIN (가장 자주 씀)

```python
# users와 payments를 user_id로 LEFT JOIN
merged = pd.merge(
    left=users_df,
    right=payments_agg,  # payments를 user_id별로 집계한 것
    on='user_id',
    how='left'
)

# 조인 후 NULL 채우기 (결제 없는 사용자)
merged['total_amount'] = merged['total_amount'].fillna(0)
merged['payment_count'] = merged['payment_count'].fillna(0).astype(int)

# 조인 전후 행 수 확인 (반드시!)
print(f"users: {len(users_df):,}행")
print(f"merged: {len(merged):,}행")
# LEFT JOIN이면 merged >= users_df (1:多 관계 시 행이 늘어날 수 있음)
```

### 조인 실수 탐지

```python
# 1:多 관계로 인한 행 중복 탐지
before_rows = len(users_df)
after_rows = len(merged)

if after_rows > before_rows:
    print(f"경고: 조인 후 행이 {after_rows - before_rows:,}개 늘었습니다.")
    print("원인: 우측 테이블에 같은 user_id가 여러 행 있음. 집계 후 조인 권장.")

# 중복 user_id 확인
dupl = merged[merged.duplicated(subset='user_id', keep=False)]
print(f"중복 user_id 행: {len(dupl):,}개")
```

### 컬럼명 충돌 처리

```python
# 두 테이블에 같은 컬럼명이 있을 때 (_x, _y 접미사 생성됨)
merged = pd.merge(df_left, df_right, on='user_id', how='left', suffixes=('_left', '_right'))

# 필요한 컬럼만 선택해서 정리
merged = merged.rename(columns={'plan_left': 'current_plan', 'plan_right': 'previous_plan'})
merged = merged.drop(columns=['unnecessary_col'])
```

---

## 5.8 apply: 컬럼별 사용자 정의 변환

### 단순 매핑은 map이 빠름

```python
# plan → 월 요금 매핑 (map이 apply보다 빠름)
price_map = {'basic': 9.99, 'pro': 19.99, 'enterprise': 49.99}
df = df.copy()
df['monthly_price'] = df['plan'].map(price_map)
# map에 없는 값은 NaN이 됨 (기본)
```

### 복잡한 로직은 apply

```python
# 구독 기간에 따른 세그먼트 분류
def categorize_tenure(days):
    if pd.isna(days):
        return 'unknown'
    if days < 30:
        return 'new'
    elif days < 90:
        return 'growing'
    elif days < 365:
        return 'established'
    else:
        return 'loyal'

df = df.copy()
df['tenure_segment'] = df['tenure_days'].apply(categorize_tenure)

# 여러 컬럼을 동시에 참조하는 apply (axis=1)
def calculate_ltv_tier(row):
    if row['plan'] == 'enterprise' and row['tenure_months'] >= 12:
        return 'high_value'
    elif row['total_amount'] >= 500:
        return 'high_value'
    elif row['total_amount'] >= 100:
        return 'mid_value'
    else:
        return 'low_value'

df['ltv_tier'] = df.apply(calculate_ltv_tier, axis=1)
```

### SettingWithCopyWarning 완전 이해

```python
# 상황 1: 슬라이싱된 df에 값 대입 (경고 발생)
pro_users = df[df['plan'] == 'pro']    # 슬라이스 (뷰 or 복사, 불확실)
pro_users['price'] = 19.99             # 경고: 원본 df에 반영될지 보장 불가

# 해결: .copy() 명시
pro_users = df[df['plan'] == 'pro'].copy()   # 명확한 복사
pro_users['price'] = 19.99                   # 안전

# 상황 2: 조건부 대입
df['discount'] = 0.0
df[df['plan'] == 'pro']['discount'] = 0.1   # 경고 (체인 인덱싱)

# 해결: .loc 사용
df.loc[df['plan'] == 'pro', 'discount'] = 0.1   # 안전
```

---

## 5.9 시계열 처리

```python
# 날짜 컬럼으로 시계열 집계
df['signup_date'] = pd.to_datetime(df['signup_date'])

# 연/월/일/요일 추출
df = df.copy()
df['year']    = df['signup_date'].dt.year
df['month']   = df['signup_date'].dt.month
df['day']     = df['signup_date'].dt.day
df['weekday'] = df['signup_date'].dt.day_name()
df['week']    = df['signup_date'].dt.isocalendar().week.astype(int)
df['quarter'] = df['signup_date'].dt.quarter

# 월별 집계
monthly = df.set_index('signup_date').resample('M')['user_id'].nunique()
monthly.index = monthly.index.strftime('%Y-%m')

# 이동 평균 (7일)
df_daily = df.set_index('signup_date').resample('D')['user_id'].count().reset_index()
df_daily.columns = ['date', 'daily_signups']
df_daily['rolling_7d'] = df_daily['daily_signups'].rolling(window=7, min_periods=1).mean()

# 전월 대비 변화율
monthly_df = monthly.reset_index()
monthly_df.columns = ['month', 'signups']
monthly_df['prev_signups'] = monthly_df['signups'].shift(1)
monthly_df['growth_rate'] = (monthly_df['signups'] - monthly_df['prev_signups']) / monthly_df['prev_signups'] * 100
```

---

## 5.10 실습: SQL 결과 → pandas 후처리 5개

### 실습 1. 월별 신규 가입 트렌드 후처리

**상황**: SQL에서 뽑은 월별 신규 가입 결과를 pandas로 후처리합니다.

**Copilot 프롬프트**:
```python
# 가상 데이터로 월별 신규 가입 DataFrame 생성 후 후처리.
# 컬럼: year_month (str 'YYYY-MM'), plan, signups (int)
#
# 후처리 항목:
# 1. year_month를 datetime Period로 변환
# 2. plan별 피벗 (행=year_month, 열=plan, 값=signups, fill_value=0)
# 3. Total 열 추가 (행 합계)
# 4. 전월 대비 Total 증감율(%) 열 추가
# 5. 최근 6개월만 필터
# 6. 결과를 monthly_pivot.csv로 저장
#
# 가상 데이터: 2023-10 ~ 2024-03, plan=[basic/pro/enterprise], 각 랜덤 signups
# SettingWithCopyWarning 없이.
```

**예상 출력**:
```
year_month  basic   pro  enterprise  Total  total_growth_pct
2023-10      5234  1823         412   7469              NaN
2023-11      5512  1940         445   7897             5.7%
2023-12      6023  2100         512   8635             9.3%
2024-01      5890  2050         490   8430            -2.4%
2024-02      6234  2200         556   8990             6.6%
2024-03      7120  2540         580  10240            13.9%
```

### 실습 2. 코호트 리텐션 피벗

**Copilot 프롬프트**:
```python
# SQL 결과 형태의 리텐션 데이터를 pandas로 피벗.
#
# 가상 데이터 생성:
# cohort_month: 2024-01 ~ 2024-04 (4개 코호트)
# month_number: 0 ~ 5
# cohort_users: 코호트별 고정값
# retained_users: 코호트 크기 × 리텐션 비율 (Month 0=100%, 이후 점감)
# retention_rate: retained_users / cohort_users
#
# 피벗 후:
# - 행: cohort_month, 열: month_0~month_5, 값: retention_rate (소수)
# - 출력 시 % 형식으로 포맷
# - 코호트 크기(cohort_users) 열도 포함
```

### 실습 3. RFM 세그먼트 후처리

**Copilot 프롬프트**:
```python
# 가상 RFM 데이터로 세그먼트별 분析 DataFrame 생성.
#
# 가상 데이터 (500명):
# user_id: 1~500
# recency_days: 0~365 (정규분포 근사)
# frequency: 1~50
# monetary: 10~1000
#
# 처리:
# 1. R/F/M 각각 NTILE(5) 스코어링 (pandas qcut 사용)
#    R: 낮을수록 높은 점수 (ascending=False 스코어링)
# 2. rfm_score = r_score + f_score + m_score
# 3. 세그먼트 분류: Champions(13~15) / Loyal(10~12) / At Risk(6~9) / Lost(3~5)
# 4. 세그먼트별 사용자 수, 평균 monetary, 평균 frequency 출력
# 5. 시각화용 컬러 매핑 딕셔너리도 생성
```

### 실습 4. A/B 테스트 결과 비교

**Copilot 프롬프트**:
```python
# A/B 테스트 결과를 pandas + scipy로 분析.
#
# 가상 데이터:
# control: 12,340명 중 2,254명 전환 (conversion=1/0)
# treatment: 12,289명 중 2,668명 전환
#
# 분析:
# 1. DataFrame으로 생성 (user_id, variant, converted)
# 2. variant별 전환율 계산
# 3. scipy.stats.proportions_ztest로 유의성 검정
# 4. 95% 신뢰구간 계산 (Wilson score interval)
# 5. 결과를 DataFrame으로 정리 (variant, conversions, total, rate, ci_lower, ci_upper)
# 6. 비즈니스 임팩트 계산: treatment 전환율로 바꿨을 때 월 추가 전환 예상 (규모: 월 25,000명 노출)
```

### 실습 5. 이탈 사용자 행동 패턴 비교

**Copilot 프롬프트**:
```python
# 이탈 사용자 vs 유지 사용자의 30일 전 행동 패턴 비교.
#
# 가상 데이터 생성:
# users_df: user_id, churned (0/1), plan
# activity_df: user_id, days_before_churn (1~30), event_count
#
# 분析:
# 1. 두 DataFrame merge (user_id 기준 LEFT JOIN)
# 2. churned 그룹별 × days_before_churn별 평균 event_count 집계
# 3. 이탈/유지 그룹의 마지막 30일 event_count 시계열 비교 DataFrame 생성
# 4. 이탈 그룹의 "이탈 7일 전" 이벤트 급감 시점을 찾는 코드 (diff() 활용)
# 5. 그룹별 평균 이벤트 수 비교 출력
```

---

## 5.11 pandas 효율화 팁

### 빠른 확인 코드 모음

```python
# 한 줄로 컬럼 요약
df.info()                     # 타입 + 비어있지 않은 값 수
df.describe(include='all')    # 수치형 + 범주형 통계
df.value_counts('plan')       # 단일 컬럼 빈도
df.nunique()                  # 각 컬럼 고유값 수

# 결측치 현황
df.isnull().sum()             # 컬럼별 NULL 수
df.isnull().sum() / len(df)   # NULL 비율

# 중복 확인
df.duplicated().sum()                    # 전체 중복 행 수
df.duplicated(subset=['user_id']).sum()  # user_id 기준 중복
```

### 메모리 최적화 (대용량 CSV 읽을 때)

```python
# dtype을 명시해서 메모리 절약
df = pd.read_csv('large_file.csv', dtype={
    'user_id':   'int32',      # int64 대신 (4바이트 절약)
    'plan':      'category',   # 반복 문자열을 category로 (큰 절약)
    'country':   'category',
    'amount':    'float32'     # float64 대신
})

# 필요한 컬럼만 읽기
df = pd.read_csv('large_file.csv', usecols=['user_id', 'plan', 'amount', 'signup_date'])

# 청크 단위로 읽기 (수백 MB 이상)
chunks = []
for chunk in pd.read_csv('huge_file.csv', chunksize=100_000):
    # 각 청크에서 집계만 해서 저장
    agg = chunk.groupby('plan')['amount'].sum().reset_index()
    chunks.append(agg)
result = pd.concat(chunks).groupby('plan')['amount'].sum().reset_index()
```

---

## 핵심 포인트

1. **흐름**: SQL에서 집계 → pandas는 후처리·시각화만. pandas로 수억 행 처리는 피한다
2. **groupby 후 컬럼명**: named aggregation `agg(name=('col', func))` + `reset_index()` 패턴이 가장 깔끔
3. **merge는 LEFT JOIN이 기본**: 행 수 변화 반드시 확인. 1:多 관계 조인 전에 집계 먼저
4. **SettingWithCopyWarning**: 슬라이싱 후 `.copy()`, 조건부 대입은 `.loc[]` — Copilot 프롬프트에 항상 명시
5. **apply는 마지막 수단**: map > vectorized 연산 > apply 순으로 사용. apply는 느림

---

**다음 챕터**: [06-visualization-code.md](./06-visualization-code.md) — 시각화 코드: matplotlib/seaborn/plotly 차트 6종
