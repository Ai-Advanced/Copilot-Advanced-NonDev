"""
pandas 실무 레시피 15개+
분析가를 위한 복붙 가능한 pandas 코드 모음.

사용법:
    각 레시피를 함수 단위로 독립 실행 가능.
    데이터는 각 레시피 안에서 가상으로 생성.
    실제 사용 시 pd.read_csv() 또는 pd.read_sql()로 교체.

환경:
    Python 3.10+, pandas >= 1.5, numpy >= 1.23
    pip install pandas numpy matplotlib seaborn scipy
"""

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import matplotlib as mpl
import seaborn as sns
from scipy import stats
from pathlib import Path

# 한글 폰트 (Windows)
mpl.rcParams['font.family'] = 'Malgun Gothic'
mpl.rcParams['axes.unicode_minus'] = False

# pandas 출력 설정
pd.set_option('display.max_columns', 20)
pd.set_option('display.float_format', '{:.2f}'.format)

np.random.seed(42)


# ============================================================
# RECIPE 01. CSV 읽기 + 기초 검증
# 용도: 새 데이터를 받았을 때 첫 5분 루틴
# ============================================================
def recipe_01_load_and_audit():
    """CSV 읽기 + 기초 데이터 품질 검증."""
    # 가상 데이터 생성 (실제 사용 시 pd.read_csv로 교체)
    n = 1000
    df = pd.DataFrame({
        'user_id':    range(1, n + 1),
        'signup_date': pd.date_range('2024-01-01', periods=n, freq='6H'),
        'plan':       np.random.choice(['basic', 'pro', 'enterprise', None], n, p=[0.6, 0.3, 0.09, 0.01]),
        'country':    np.random.choice(['KR', 'US', 'JP', None], n, p=[0.5, 0.3, 0.15, 0.05]),
        'amount':     np.random.exponential(30, n),
    })

    print("=== 기초 정보 ===")
    print(f"shape: {df.shape}")
    print(f"\n타입:\n{df.dtypes}")
    print(f"\n결측치:\n{df.isnull().sum()}")
    print(f"\n결측치 비율(%):\n{(df.isnull().sum() / len(df) * 100).round(2)}")
    print(f"\n중복 행 수: {df.duplicated().sum()}")
    print(f"\n수치형 통계:\n{df.describe()}")
    print(f"\n범주형 통계:\n{df.describe(include='object')}")
    return df


# ============================================================
# RECIPE 02. 타입 변환 + 문자열 정제
# 용도: 지저분한 원본 데이터를 분析 가능한 형태로
# ============================================================
def recipe_02_type_cleaning():
    """타입 변환, 문자열 정제, 결측치 처리."""
    df = pd.DataFrame({
        'user_id':    [1, 2, 3, 4, 5],
        'email':      ['Alice@Ex.COM', '  bob@test.com  ', '', 'dave@example.com', None],
        'signup_date':['2024/01/15', '2024-02-20', '20240310', None, '2024-04-05'],
        'plan':       ['Pro', 'BASIC', 'enterprise', 'pro', None],
        'amount':     ['1,200', '9.99', '₩49,999', '-5', '19.99'],
    })

    cleaned = df.copy()

    # email 정제
    cleaned['email'] = cleaned['email'].str.lower().str.strip()
    cleaned['email'] = cleaned['email'].replace('', np.nan)
    cleaned['email_valid'] = cleaned['email'].notna() & cleaned['email'].str.contains('@', na=False)

    # 날짜 변환 (여러 형식 자동 처리)
    cleaned['signup_date'] = pd.to_datetime(cleaned['signup_date'], infer_datetime_format=True, errors='coerce')

    # plan 소문자화 + 허용값 외 → 'unknown'
    cleaned['plan'] = cleaned['plan'].str.lower().str.strip()
    valid_plans = {'basic', 'pro', 'enterprise'}
    cleaned['plan'] = cleaned['plan'].where(cleaned['plan'].isin(valid_plans), other='unknown')

    # 금액 정제 (쉼표, 원화기호 제거 후 float)
    cleaned['amount'] = (
        cleaned['amount'].astype(str)
        .str.replace(',', '', regex=False)
        .str.replace('₩', '', regex=False)
        .astype(float)
    )
    # 음수 → NaN
    cleaned['amount'] = cleaned['amount'].where(cleaned['amount'] >= 0, other=np.nan)

    print("=== 정제 결과 ===")
    print(cleaned)
    print(f"\n타입:\n{cleaned.dtypes}")
    return cleaned


# ============================================================
# RECIPE 03. 결측치 처리 전략
# 용도: 분析 목적에 맞는 결측치 처리 선택
# ============================================================
def recipe_03_missing_values():
    """결측치 현황 파악 + 처리 전략별 코드."""
    n = 500
    df = pd.DataFrame({
        'user_id': range(1, n + 1),
        'plan':    np.random.choice(['basic', 'pro', None], n, p=[0.6, 0.35, 0.05]),
        'country': np.random.choice(['KR', 'US', None], n, p=[0.7, 0.25, 0.05]),
        'amount':  np.where(np.random.random(n) < 0.1, np.nan, np.random.exponential(30, n)),
        'age':     np.where(np.random.random(n) < 0.15, np.nan, np.random.randint(18, 65, n).astype(float)),
    })

    print("=== 결측치 현황 ===")
    null_summary = pd.DataFrame({
        'null_count': df.isnull().sum(),
        'null_pct':   (df.isnull().sum() / len(df) * 100).round(2),
    })
    print(null_summary)

    result = df.copy()

    # 전략 1: 범주형 → 'unknown' 또는 최빈값
    result['plan']    = result['plan'].fillna('unknown')
    result['country'] = result['country'].fillna(result['country'].mode()[0])

    # 전략 2: 수치형 → 중앙값 대체
    result['amount'] = result['amount'].fillna(result['amount'].median())

    # 전략 3: 그룹별 중앙값 대체
    group_medians = result.groupby('plan')['age'].transform('median')
    result['age'] = result['age'].fillna(group_medians)

    # 전략 4: 필수 컬럼 NULL이면 행 제거
    result = result.dropna(subset=['user_id']).copy()

    print(f"\n처리 후 결측치:\n{result.isnull().sum()}")
    return result


# ============================================================
# RECIPE 04. 중복 제거
# 용도: 데이터 수집 중복, 재전송으로 인한 중복 제거
# ============================================================
def recipe_04_deduplication():
    """중복 탐지 + 제거 (최신 행 보존)."""
    df = pd.DataFrame({
        'event_id':   [1, 2, 3, 4, 5, 3, 6],
        'user_id':    [101, 102, 103, 104, 105, 103, 106],
        'event_name': ['login', 'signup', 'purchase', 'login', 'signup', 'purchase', 'login'],
        'event_date': pd.to_datetime(['2024-01-01', '2024-01-02', '2024-01-03',
                                       '2024-01-04', '2024-01-05', '2024-01-03', '2024-01-06']),
    })

    print(f"원본: {len(df)}행")
    print(f"중복 event_id: {df.duplicated(subset='event_id').sum()}건")

    # event_id 기준 중복 제거 (최신 event_date 보존)
    deduped = (
        df.sort_values('event_date', ascending=False)
          .drop_duplicates(subset='event_id', keep='first')
          .sort_values('event_id')
          .copy()
    )

    # user_id + event_name 조합 기준 중복 제거 (최신 행 보존)
    deduped2 = (
        df.sort_values('event_id', ascending=False)
          .drop_duplicates(subset=['user_id', 'event_name'], keep='first')
          .sort_values('event_id')
          .copy()
    )

    print(f"event_id 기준 제거 후: {len(deduped)}행")
    print(f"user+event 기준 제거 후: {len(deduped2)}행")
    return deduped


# ============================================================
# RECIPE 05. groupby 집계 (named aggregation)
# 용도: plan별, 채널별, 월별 집계에 반복 사용
# ============================================================
def recipe_05_groupby():
    """다양한 groupby 패턴 + named aggregation."""
    n = 5000
    df = pd.DataFrame({
        'user_id': range(1, n + 1),
        'plan':    np.random.choice(['basic', 'pro', 'enterprise'], n, p=[0.6, 0.3, 0.1]),
        'country': np.random.choice(['KR', 'US', 'JP', 'GB'], n, p=[0.5, 0.25, 0.15, 0.1]),
        'amount':  np.random.exponential(25, n),
        'signup_date': pd.date_range('2024-01-01', periods=n, freq='2H'),
    })

    # 단일 컬럼 집계
    plan_stats = df.groupby('plan').agg(
        user_count   = ('user_id',  'count'),
        total_amount = ('amount',   'sum'),
        avg_amount   = ('amount',   'mean'),
        median_amount= ('amount',   'median'),
        p90_amount   = ('amount',   lambda x: x.quantile(0.9)),
    ).reset_index()

    # 복합 groupby
    monthly_plan = df.groupby([
        df['signup_date'].dt.to_period('M').astype(str),
        'plan',
    ]).agg(
        signups = ('user_id', 'count'),
        revenue = ('amount',  'sum'),
    ).reset_index()
    monthly_plan.columns = ['year_month', 'plan', 'signups', 'revenue']

    # 비율 컬럼 추가 (transform)
    df_with_pct = df.copy()
    df_with_pct['plan_total'] = df_with_pct.groupby('plan')['amount'].transform('sum')
    df_with_pct['pct_of_plan'] = df_with_pct['amount'] / df_with_pct['plan_total'] * 100

    print("=== plan별 통계 ===")
    print(plan_stats.round(2))
    print(f"\n=== 월별 × plan 집계 (처음 6행) ===")
    print(monthly_plan.head(6))
    return plan_stats, monthly_plan


# ============================================================
# RECIPE 06. 피벗 테이블 + 언피벗 (melt)
# 용도: 코호트 분析, 교차 테이블, 리포트 포맷
# ============================================================
def recipe_06_pivot():
    """피벗 테이블 생성 + 합계 추가 + 언피벗."""
    n = 3000
    df = pd.DataFrame({
        'year_month': np.random.choice(
            ['2024-01', '2024-02', '2024-03'], n
        ),
        'plan':    np.random.choice(['basic', 'pro', 'enterprise'], n, p=[0.6, 0.3, 0.1]),
        'user_id': range(1, n + 1),
        'amount':  np.random.exponential(25, n),
    })

    # 월별 × plan별 고유 사용자 수 피벗
    pivot = df.pivot_table(
        index='year_month',
        columns='plan',
        values='user_id',
        aggfunc='nunique',
        fill_value=0,
    )

    # 합계 열/행 추가
    pivot['Total'] = pivot.sum(axis=1)
    pivot.loc['Total'] = pivot.sum(axis=0)

    # 전월 대비 성장률 (Total 행 제외)
    pivot_no_total = pivot.drop('Total', axis=0).drop('Total', axis=1)
    pivot_no_total['prev_total'] = pivot_no_total.sum(axis=1).shift(1)
    pivot_no_total['growth_pct'] = (
        (pivot_no_total.sum(axis=1) - pivot_no_total['prev_total'])
        / pivot_no_total['prev_total'] * 100
    ).round(1)

    # 언피벗 (wide → long)
    long_df = (
        pivot.drop('Total', axis=0)
             .drop('Total', axis=1)
             .reset_index()
             .melt(id_vars='year_month', var_name='plan', value_name='signups')
    )

    print("=== 피벗 테이블 ===")
    print(pivot)
    print(f"\n=== 언피벗(Long format, 처음 6행) ===")
    print(long_df.head(6))
    return pivot, long_df


# ============================================================
# RECIPE 07. merge (LEFT JOIN) + 검증
# 용도: 사용자 + 결제 + 이벤트 통합 DataFrame
# ============================================================
def recipe_07_merge():
    """안전한 LEFT JOIN + 조인 전후 행 수 검증."""
    users_df = pd.DataFrame({
        'user_id':    [1, 2, 3, 4, 5],
        'plan':       ['basic', 'pro', 'enterprise', 'basic', 'pro'],
        'signup_date': pd.to_datetime(['2024-01', '2024-01', '2024-02', '2024-02', '2024-03']),
    })

    # payments를 user_id별로 집계 (1:1 관계로 만들기)
    payments_raw = pd.DataFrame({
        'payment_id': range(1, 9),
        'user_id':    [1, 1, 2, 3, 3, 3, 4, 5],
        'amount':     [19.99, 19.99, 9.99, 49.99, 49.99, 49.99, 9.99, 19.99],
    })
    payments_agg = payments_raw.groupby('user_id').agg(
        total_amount  = ('amount', 'sum'),
        payment_count = ('amount', 'count'),
    ).reset_index()

    # LEFT JOIN
    before = len(users_df)
    merged = pd.merge(users_df, payments_agg, on='user_id', how='left')
    after  = len(merged)

    if after > before:
        print(f"경고: 조인 후 행 증가 ({before} → {after}). 1:多 관계 확인 필요.")
    else:
        print(f"조인 정상: {before} → {after}행")

    # NULL 채우기
    merged['total_amount']  = merged['total_amount'].fillna(0)
    merged['payment_count'] = merged['payment_count'].fillna(0).astype(int)

    print(merged)
    return merged


# ============================================================
# RECIPE 08. 시계열 리샘플링 + 이동 평균
# 용도: 일별 데이터를 주별/월별로 집계, 트렌드 스무딩
# ============================================================
def recipe_08_timeseries():
    """일별 데이터 리샘플링 + 이동 평균 + 전주 대비."""
    n = 180  # 6개월 일별
    dates = pd.date_range('2024-01-01', periods=n, freq='D')
    signups = (
        np.random.poisson(100, n)
        + np.sin(np.arange(n) * 2 * np.pi / 7) * 20  # 요일 패턴
        + np.linspace(0, 50, n)                        # 성장 트렌드
    ).clip(50, 200).astype(int)

    df_daily = pd.DataFrame({'date': dates, 'signups': signups})
    df_daily = df_daily.set_index('date')

    # 주별 집계
    df_weekly = df_daily.resample('W')['signups'].sum().reset_index()
    df_weekly.columns = ['week', 'weekly_signups']

    # 7일 이동 평균
    df_daily_reset = df_daily.reset_index()
    df_daily_reset['rolling_7d'] = (
        df_daily_reset['signups'].rolling(window=7, min_periods=1).mean().round(1)
    )

    # 전주 대비 변화율
    df_weekly['prev_week'] = df_weekly['weekly_signups'].shift(1)
    df_weekly['wow_pct']   = (
        (df_weekly['weekly_signups'] - df_weekly['prev_week'])
        / df_weekly['prev_week'] * 100
    ).round(1)

    print("=== 주별 집계 (처음 6주) ===")
    print(df_weekly.head(6))
    return df_daily_reset, df_weekly


# ============================================================
# RECIPE 09. apply + 사용자 정의 분류 함수
# 용도: 복잡한 조건 기반 세그먼트 분류
# ============================================================
def recipe_09_apply():
    """map / apply를 활용한 세그먼트 분류 + LTV 티어."""
    n = 1000
    df = pd.DataFrame({
        'user_id':      range(1, n + 1),
        'plan':         np.random.choice(['basic', 'pro', 'enterprise'], n, p=[0.6, 0.3, 0.1]),
        'tenure_months': np.random.randint(1, 36, n),
        'total_amount': np.random.exponential(100, n),
    })

    # map: 단순 매핑 (가장 빠름)
    price_map = {'basic': 9.99, 'pro': 19.99, 'enterprise': 49.99}
    df = df.copy()
    df['monthly_price'] = df['plan'].map(price_map)

    # 구독 기간 구간 (pd.cut 활용, apply보다 빠름)
    df['tenure_segment'] = pd.cut(
        df['tenure_months'],
        bins=[0, 3, 6, 12, 24, float('inf')],
        labels=['0~3개월', '4~6개월', '7~12개월', '13~24개월', '25개월+'],
        right=True
    )

    # apply (여러 컬럼 참조 필요한 복잡한 로직)
    def ltv_tier(row):
        if row['plan'] == 'enterprise' and row['tenure_months'] >= 12:
            return 'Premium'
        elif row['total_amount'] >= 500:
            return 'High'
        elif row['total_amount'] >= 100:
            return 'Mid'
        else:
            return 'Low'

    df['ltv_tier'] = df.apply(ltv_tier, axis=1)

    print("=== 세그먼트 분류 결과 ===")
    print(df.groupby(['plan', 'ltv_tier'])['user_id'].count().unstack(fill_value=0))
    return df


# ============================================================
# RECIPE 10. 이상치 탐지 + 플래그 (IQR)
# 용도: 비정상 결제 탐지, 데이터 품질 플래그
# ============================================================
def recipe_10_outlier_detection():
    """IQR 방식 이상치 탐지 + is_outlier 플래그."""
    n = 1000
    amounts = np.concatenate([
        np.random.exponential(25, int(n * 0.95)),   # 정상 거래
        np.array([9999, 99999, 0.01, -5, 50000]),   # 이상치 5건
        np.random.exponential(25, n - int(n * 0.95) - 5),
    ])
    df = pd.DataFrame({'payment_id': range(1, len(amounts) + 1), 'amount': amounts})

    # IQR 계산
    q1  = df['amount'].quantile(0.25)
    q3  = df['amount'].quantile(0.75)
    iqr = q3 - q1
    lower = q1 - 1.5 * iqr
    upper = q3 + 1.5 * iqr

    # 플래그 추가 (제거하지 않음)
    df = df.copy()
    df['is_outlier'] = (df['amount'] < lower) | (df['amount'] > upper)

    outlier_summary = {
        'total':       len(df),
        'outliers':    df['is_outlier'].sum(),
        'outlier_pct': round(df['is_outlier'].mean() * 100, 2),
        'lower_bound': round(lower, 2),
        'upper_bound': round(upper, 2),
    }
    print("=== 이상치 요약 ===")
    for k, v in outlier_summary.items():
        print(f"  {k}: {v}")
    print(f"\n이상치 샘플:\n{df[df['is_outlier']].head()}")
    return df


# ============================================================
# RECIPE 11. RFM 세그먼테이션 (pandas 버전)
# 용도: SQL 결과 없이 pandas만으로 RFM 계산
# ============================================================
def recipe_11_rfm():
    """pandas로 RFM 세그먼테이션 (NTILE = qcut)."""
    n = 2000
    reference_date = pd.Timestamp('2024-04-01')

    df = pd.DataFrame({
        'user_id':      range(1, n + 1),
        'last_payment': reference_date - pd.to_timedelta(
            np.random.exponential(90, n).clip(1, 730).astype(int), unit='D'
        ),
        'frequency':    np.random.poisson(5, n).clip(1, 50),
        'monetary':     np.random.exponential(150, n).clip(5, 2000),
    })

    rfm = df.copy()
    rfm['recency_days'] = (reference_date - rfm['last_payment']).dt.days

    # qcut으로 NTILE(5) 구현
    # R: 낮을수록(최근) 높은 점수 → ascending=False
    rfm['r_score'] = pd.qcut(rfm['recency_days'].rank(method='first'),
                              q=5, labels=[5, 4, 3, 2, 1]).astype(int)
    rfm['f_score'] = pd.qcut(rfm['frequency'].rank(method='first'),
                              q=5, labels=[1, 2, 3, 4, 5]).astype(int)
    rfm['m_score'] = pd.qcut(rfm['monetary'].rank(method='first'),
                              q=5, labels=[1, 2, 3, 4, 5]).astype(int)

    rfm['rfm_total'] = rfm['r_score'] + rfm['f_score'] + rfm['m_score']
    rfm['segment'] = pd.cut(
        rfm['rfm_total'],
        bins=[2, 5, 9, 12, 15],
        labels=['Lost', 'At Risk', 'Loyal', 'Champions'],
        right=True
    )

    seg_summary = rfm.groupby('segment', observed=True).agg(
        count    = ('user_id',   'count'),
        avg_monetary = ('monetary', 'mean'),
        avg_freq = ('frequency', 'mean'),
    ).round(1)

    print("=== RFM 세그먼트 요약 ===")
    print(seg_summary)
    return rfm


# ============================================================
# RECIPE 12. A/B 테스트 결과 분析
# 용도: 전환율 비교 + 통계 검정 + 비즈니스 임팩트
# ============================================================
def recipe_12_ab_test():
    """A/B 테스트 전환율 비교 + proportions_ztest + Wilson CI."""
    from statsmodels.stats.proportion import proportions_ztest

    # 가상 데이터
    control_n, control_k    = 12340, 2254  # 대조군
    treatment_n, treatment_k = 12289, 2668  # 실험군

    control_rate   = control_k / control_n
    treatment_rate = treatment_k / treatment_n

    # 비율 z-검정
    count = np.array([treatment_k, control_k])
    nobs  = np.array([treatment_n, control_n])
    stat, p_value = proportions_ztest(count, nobs)

    # Wilson score 95% 신뢰구간
    def wilson_ci(k, n, z=1.96):
        p = k / n
        denominator = 1 + z**2 / n
        center = (p + z**2 / (2 * n)) / denominator
        margin = z * np.sqrt(p * (1 - p) / n + z**2 / (4 * n**2)) / denominator
        return round(center - margin, 4), round(center + margin, 4)

    ctrl_ci  = wilson_ci(control_k, control_n)
    treat_ci = wilson_ci(treatment_k, treatment_n)

    # 비즈니스 임팩트 (월 25,000명 노출 기준)
    monthly_exposure = 25000
    impact = (treatment_rate - control_rate) * monthly_exposure

    result = pd.DataFrame({
        'variant':    ['Control', 'Treatment'],
        'n':          [control_n, treatment_n],
        'conversions':[control_k, treatment_k],
        'conv_rate':  [round(control_rate, 4), round(treatment_rate, 4)],
        'ci_lower':   [ctrl_ci[0], treat_ci[0]],
        'ci_upper':   [ctrl_ci[1], treat_ci[1]],
    })

    print("=== A/B 테스트 결과 ===")
    print(result.to_string(index=False))
    print(f"\nz-통계량: {stat:.3f}, p-value: {p_value:.4f}")
    print(f"통계적 유의성: {'✅ 유의 (p < 0.05)' if p_value < 0.05 else '❌ 비유의'}")
    print(f"\n전환율 차이: {(treatment_rate - control_rate)*100:+.2f}%p")
    print(f"95% CI: [{(treat_ci[0]-ctrl_ci[1])*100:.2f}%, {(treat_ci[1]-ctrl_ci[0])*100:.2f}%p]")
    print(f"\n비즈니스 임팩트: 월 {impact:.0f}명 추가 전환 (25,000명 노출 기준)")
    return result


# ============================================================
# RECIPE 13. 코호트 리텐션 피벗 (SQL 결과 → 히트맵 데이터)
# 용도: SQL PATTERN 02 결과를 pandas에서 피벗 + 시각화
# ============================================================
def recipe_13_cohort_pivot():
    """코호트 리텐션 DataFrame 피벗 + 히트맵 시각화."""
    # SQL 결과 형태의 가상 데이터
    cohorts = ['2023-10', '2023-11', '2023-12', '2024-01', '2024-02', '2024-03']
    records = []
    for cohort in cohorts:
        size = np.random.randint(800, 1200)
        retention = 1.0
        for m in range(7):
            if m == 0:
                records.append({'cohort_month': cohort, 'month_number': m,
                                 'cohort_size': size, 'retained': size,
                                 'retention_rate': 1.0})
            else:
                months_elapsed = len(cohorts) - cohorts.index(cohort)
                if m >= months_elapsed:
                    break  # 아직 관측 불가
                retention *= np.random.uniform(0.82, 0.92)
                records.append({'cohort_month': cohort, 'month_number': m,
                                 'cohort_size': size, 'retained': int(size * retention),
                                 'retention_rate': round(retention, 4)})

    df_raw = pd.DataFrame(records)

    # 피벗
    pivot = df_raw.pivot_table(
        index='cohort_month',
        columns='month_number',
        values='retention_rate',
        aggfunc='first',
    )
    pivot.columns = [f'Month {c}' for c in pivot.columns]

    # 코호트 크기 추가
    sizes = df_raw[df_raw['month_number'] == 0].set_index('cohort_month')['cohort_size']
    pivot.insert(0, 'Cohort Size', sizes)

    print("=== 코호트 리텐션 피벗 ===")
    print(pivot.applymap(lambda x: f'{x:.0%}' if isinstance(x, float) else x))

    # 히트맵 시각화
    fig, ax = plt.subplots(figsize=(12, 5))
    retention_only = pivot.drop('Cohort Size', axis=1).astype(float)
    sns.heatmap(
        retention_only, ax=ax,
        cmap='YlGn', annot=True, fmt='.0%',
        linewidths=0.5, linecolor='white',
        vmin=0, vmax=1,
        mask=retention_only.isna(),
        cbar_kws={'label': '리텐션율'}
    )
    ax.set_title('월별 코호트 리텐션 히트맵', fontsize=14, fontweight='bold')
    ax.set_xlabel('가입 후 N개월')
    ax.set_ylabel('가입 코호트')
    plt.tight_layout()
    plt.savefig('cohort_heatmap.png', dpi=120, bbox_inches='tight')
    print("\n히트맵 저장: cohort_heatmap.png")
    return pivot


# ============================================================
# RECIPE 14. 이상치 탐지 시각화 (시계열)
# 용도: 지표 급변 날짜 탐지, 데이터 이상 알림
# ============================================================
def recipe_14_anomaly_viz():
    """시계열 이상치 탐지 + 시각화 (mean ± 2*std)."""
    n = 90
    dates  = pd.date_range('2024-01-01', periods=n, freq='D')
    values = (
        np.random.poisson(100, n)
        + np.sin(np.arange(n) * 2 * np.pi / 7) * 15
    )
    # 이상치 주입
    values[30] = 250
    values[60] = 20

    df = pd.DataFrame({'date': dates, 'signups': values})

    # 이상치 탐지
    mean = df['signups'].mean()
    std  = df['signups'].std()
    df['is_anomaly'] = (df['signups'] > mean + 2 * std) | (df['signups'] < mean - 2 * std)
    df['rolling_7d'] = df['signups'].rolling(7, min_periods=1).mean()

    # 시각화
    fig, ax = plt.subplots(figsize=(14, 5))
    ax.plot(df['date'], df['signups'], color='steelblue', linewidth=1.5, label='일별 가입')
    ax.plot(df['date'], df['rolling_7d'], color='orange', linestyle='--', linewidth=2, label='7일 이동 평균')
    ax.axhline(mean + 2 * std, color='red', linestyle=':', alpha=0.5, label='±2σ 경계')
    ax.axhline(mean - 2 * std, color='red', linestyle=':', alpha=0.5)
    anomaly_pts = df[df['is_anomaly']]
    ax.scatter(anomaly_pts['date'], anomaly_pts['signups'],
               color='red', s=80, zorder=5, label=f'이상치 ({len(anomaly_pts)}건)')
    for _, row in anomaly_pts.iterrows():
        ax.annotate(f"{int(row['signups'])}", (row['date'], row['signups']),
                    textcoords='offset points', xytext=(0, 10), fontsize=9, color='red')
    ax.set_title('일별 신규 가입 이상치 탐지 (±2σ)', fontsize=14, fontweight='bold')
    ax.set_xlabel('날짜')
    ax.set_ylabel('신규 가입자 수')
    ax.legend()
    ax.spines['top'].set_visible(False)
    ax.spines['right'].set_visible(False)
    plt.tight_layout()
    plt.savefig('anomaly_detection.png', dpi=120, bbox_inches='tight')
    print(f"이상치 {len(anomaly_pts)}건 탐지. 저장: anomaly_detection.png")
    return df


# ============================================================
# RECIPE 15. 퀵 EDA 함수
# 용도: 새 DataFrame을 받으면 처음에 호출하는 종합 탐색
# ============================================================
def quick_eda(df: pd.DataFrame, name: str = 'DataFrame') -> None:
    """
    DataFrame 기초 탐색을 한 번에 출력하는 유틸 함수.

    Args:
        df:   탐색할 DataFrame
        name: 이름 (출력 헤더에 사용)

    Usage:
        quick_eda(df, name='사용자 데이터')
    """
    print(f"\n{'='*50}")
    print(f"  EDA 요약: {name}")
    print(f"{'='*50}")
    print(f"Shape : {df.shape[0]:,}행 × {df.shape[1]:,}열")
    print(f"메모리: {df.memory_usage(deep=True).sum() / 1024:.1f} KB")

    print(f"\n--- 타입 ---")
    dtype_counts = df.dtypes.value_counts()
    for dtype, cnt in dtype_counts.items():
        print(f"  {dtype}: {cnt}열")

    print(f"\n--- 결측치 ---")
    null_info = df.isnull().sum()
    null_info = null_info[null_info > 0]
    if len(null_info) == 0:
        print("  결측치 없음")
    else:
        for col, cnt in null_info.items():
            print(f"  {col}: {cnt}건 ({cnt/len(df)*100:.1f}%)")

    print(f"\n--- 중복 행 ---")
    print(f"  {df.duplicated().sum():,}건")

    print(f"\n--- 수치형 통계 ---")
    num_cols = df.select_dtypes(include='number')
    if not num_cols.empty:
        print(num_cols.describe().round(2).to_string())

    print(f"\n--- 범주형 Top 5 ---")
    cat_cols = df.select_dtypes(include=['object', 'category'])
    for col in cat_cols.columns[:5]:
        top = df[col].value_counts().head(3)
        print(f"  {col}: {dict(top)}")

    print(f"{'='*50}\n")


# ============================================================
# 실행 예시
# ============================================================
if __name__ == '__main__':
    print("=== pandas 레시피 실행 ===\n")

    # 기본 레시피 실행 (나머지는 필요에 따라 주석 해제)
    df1 = recipe_01_load_and_audit()
    quick_eda(df1, '가입 데이터 (가상)')

    df2 = recipe_02_type_cleaning()
    df4 = recipe_04_deduplication()
    plan_stats, monthly = recipe_05_groupby()
    pivot, long_df = recipe_06_pivot()

    print("\n=== 고급 레시피 ===")
    # recipe_12_ab_test()     # statsmodels 필요
    # recipe_13_cohort_pivot()  # matplotlib/seaborn 필요 (시각화 포함)
    # recipe_14_anomaly_viz()   # 시각화 포함

    print("\n모든 레시피 실행 완료.")
