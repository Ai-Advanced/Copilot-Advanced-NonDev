-- ============================================================
-- 분析가용 SQL 패턴 15개+
-- 데이터베이스: PostgreSQL (BigQuery/Snowflake 주요 차이 주석 표기)
-- 대상 스키마: Zeta 구독 서비스
--   users(user_id, signup_date, plan, country, channel, age_group)
--   subscriptions(subscription_id, user_id, event_type, plan, event_date, mrr)
--   events(event_id, user_id, event_name, event_date, session_id)
--   payments(payment_id, user_id, amount, status, paid_at)
-- ============================================================


-- ============================================================
-- PATTERN 01. 월별 신규 가입 집계 + 전월 대비 증감
-- 용도: 성장 트렌드 파악, 마케팅 채널 효과 측정
-- ============================================================
WITH monthly_signups AS (
    SELECT
        DATE_TRUNC('month', signup_date)::DATE AS year_month,
        -- BigQuery: DATE_TRUNC(signup_date, MONTH)
        -- Snowflake: DATE_TRUNC('MONTH', signup_date)
        COUNT(DISTINCT user_id) AS signups
    FROM users
    WHERE signup_date >= '2023-01-01'
    GROUP BY DATE_TRUNC('month', signup_date)
)
SELECT
    year_month,
    signups,
    LAG(signups) OVER (ORDER BY year_month) AS prev_month_signups,
    signups - LAG(signups) OVER (ORDER BY year_month) AS change,
    ROUND(
        (signups - LAG(signups) OVER (ORDER BY year_month))::NUMERIC
        / NULLIF(LAG(signups) OVER (ORDER BY year_month), 0) * 100,
        1
    ) AS change_pct
FROM monthly_signups
ORDER BY year_month;


-- ============================================================
-- PATTERN 02. 코호트 리텐션 분析
-- 용도: 제품 stickiness 파악, 코호트별 리텐션 개선 효과 측정
-- 결과: cohort_month × month_0~12 형태
-- ============================================================
WITH
-- CTE 1: 각 사용자의 첫 구독 월 (코호트 정의)
cohort_base AS (
    SELECT
        user_id,
        DATE_TRUNC('month', MIN(event_date))::DATE AS cohort_month
    FROM subscriptions
    WHERE event_type = 'subscribe'
    GROUP BY user_id
),
-- CTE 2: 사용자별 월별 활동 (구독 유지 월)
monthly_activity AS (
    SELECT DISTINCT
        user_id,
        DATE_TRUNC('month', event_date)::DATE AS activity_month
    FROM subscriptions
    WHERE event_type IN ('subscribe', 'upgrade', 'downgrade')
    -- cancel 이벤트는 포함하지 않음
),
-- CTE 3: 코호트 기준 경과 월수 계산
cohort_activity AS (
    SELECT
        c.cohort_month,
        c.user_id,
        m.activity_month,
        (DATE_PART('year', m.activity_month) - DATE_PART('year', c.cohort_month)) * 12
        + (DATE_PART('month', m.activity_month) - DATE_PART('month', c.cohort_month))
        AS month_number
    FROM cohort_base c
    LEFT JOIN monthly_activity m ON c.user_id = m.user_id
),
-- CTE 4: 코호트 크기
cohort_sizes AS (
    SELECT cohort_month, COUNT(DISTINCT user_id) AS cohort_size
    FROM cohort_base
    GROUP BY cohort_month
),
-- CTE 5: 월별 리텐션 사용자 수
retention_counts AS (
    SELECT
        cohort_month,
        month_number,
        COUNT(DISTINCT user_id) AS retained
    FROM cohort_activity
    WHERE month_number >= 0
    GROUP BY cohort_month, month_number
)
SELECT
    r.cohort_month,
    cs.cohort_size,
    r.month_number,
    r.retained,
    ROUND(r.retained::NUMERIC / cs.cohort_size, 4) AS retention_rate
FROM retention_counts r
JOIN cohort_sizes cs ON r.cohort_month = cs.cohort_month
ORDER BY r.cohort_month, r.month_number;


-- ============================================================
-- PATTERN 03. 퍼널 전환율 分析
-- 용도: 온보딩/가입 퍼널의 이탈 지점 파악
-- 주의: 각 단계는 독립적 집계 (이전 단계 도달 여부와 무관)
-- ============================================================
WITH funnel_stages AS (
    SELECT
        1 AS step_order, 'landing_view'        AS event_name, 'Landing View'       AS stage_label
    UNION ALL SELECT 2, 'signup_start',        'Signup Start'
    UNION ALL SELECT 3, 'signup_complete',     'Signup Complete'
    UNION ALL SELECT 4, 'trial_start',         'Trial Start'
    UNION ALL SELECT 5, 'subscription_start',  'Subscription Start'
),
stage_users AS (
    SELECT
        fs.step_order,
        fs.stage_label,
        COUNT(DISTINCT e.user_id) AS users
    FROM funnel_stages fs
    LEFT JOIN events e
        ON e.event_name = fs.event_name
        AND e.event_date >= '2024-01-01'
        AND e.event_date <  '2024-04-01'
    GROUP BY fs.step_order, fs.stage_label
)
SELECT
    step_order,
    stage_label,
    users,
    LAG(users) OVER (ORDER BY step_order) AS prev_step_users,
    ROUND(
        users::NUMERIC / NULLIF(LAG(users) OVER (ORDER BY step_order), 0) * 100,
        1
    ) AS step_conversion_pct,
    ROUND(
        users::NUMERIC / NULLIF(FIRST_VALUE(users) OVER (ORDER BY step_order), 0) * 100,
        1
    ) AS overall_conversion_pct
FROM stage_users
ORDER BY step_order;


-- ============================================================
-- PATTERN 04. RFM 세그먼테이션
-- 용도: 고객 가치 세그먼트 분류, 마케팅 타겟팅
-- 주의: R 스코어는 낮을수록(최근일수록) 높은 점수
-- ============================================================
WITH rfm_raw AS (
    SELECT
        user_id,
        CURRENT_DATE - MAX(paid_at::DATE)    AS recency_days,
        COUNT(*)                             AS frequency,
        SUM(amount)                          AS monetary
    FROM payments
    WHERE status = 'success'
    GROUP BY user_id
),
rfm_scored AS (
    SELECT
        user_id,
        recency_days,
        frequency,
        monetary,
        -- R: 낮을수록(최근) 높은 점수 → DESC 정렬로 NTILE
        NTILE(5) OVER (ORDER BY recency_days DESC)  AS r_score,
        NTILE(5) OVER (ORDER BY frequency ASC)      AS f_score,
        NTILE(5) OVER (ORDER BY monetary ASC)       AS m_score
    FROM rfm_raw
),
rfm_segmented AS (
    SELECT
        *,
        r_score + f_score + m_score AS rfm_total,
        CASE
            WHEN r_score + f_score + m_score >= 13 THEN 'Champions'
            WHEN r_score + f_score + m_score >= 10 THEN 'Loyal'
            WHEN r_score + f_score + m_score >= 6  THEN 'At Risk'
            ELSE 'Lost'
        END AS segment
    FROM rfm_scored
)
SELECT
    segment,
    COUNT(*)                           AS user_count,
    ROUND(AVG(monetary), 2)            AS avg_monetary,
    ROUND(AVG(frequency), 1)           AS avg_frequency,
    ROUND(AVG(recency_days), 0)        AS avg_recency_days
FROM rfm_segmented
GROUP BY segment
ORDER BY avg_monetary DESC;


-- ============================================================
-- PATTERN 05. 세션 분离 (LAG 활용)
-- 용도: 사용자 세션 정의, 세션별 행동 분析
-- 기준: 이전 이벤트로부터 30분 이상 간격 = 새 세션
-- ============================================================
WITH with_prev_event AS (
    SELECT
        event_id,
        user_id,
        event_name,
        event_date,
        LAG(event_date) OVER (
            PARTITION BY user_id
            ORDER BY event_date
        ) AS prev_event_date
    FROM events
),
with_session_flag AS (
    SELECT
        *,
        CASE
            WHEN prev_event_date IS NULL THEN 1
            WHEN event_date - prev_event_date > INTERVAL '30 minutes' THEN 1
            ELSE 0
        END AS is_new_session
    FROM with_prev_event
),
with_session_number AS (
    SELECT
        *,
        SUM(is_new_session) OVER (
            PARTITION BY user_id
            ORDER BY event_date
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS session_number
    FROM with_session_flag
)
-- 세션별 통계 집계
SELECT
    user_id,
    session_number,
    MIN(event_date)                  AS session_start,
    MAX(event_date)                  AS session_end,
    EXTRACT(EPOCH FROM (MAX(event_date) - MIN(event_date))) / 60.0
                                     AS duration_minutes,
    COUNT(*)                         AS event_count
FROM with_session_number
GROUP BY user_id, session_number
ORDER BY user_id, session_number;


-- ============================================================
-- PATTERN 06. MRR 분解 (Waterfall)
-- 용도: MRR 변동 원인 파악 (신규/확장/축소/이탈)
-- ============================================================
WITH mrr_by_event AS (
    SELECT
        DATE_TRUNC('month', event_date)::DATE AS year_month,
        event_type,
        SUM(mrr) AS mrr_contribution
    FROM subscriptions
    GROUP BY DATE_TRUNC('month', event_date), event_type
)
SELECT
    year_month,
    SUM(CASE WHEN event_type = 'subscribe'  THEN mrr_contribution ELSE 0 END) AS new_mrr,
    SUM(CASE WHEN event_type = 'upgrade'    THEN mrr_contribution ELSE 0 END) AS expansion_mrr,
    SUM(CASE WHEN event_type = 'downgrade'  THEN -mrr_contribution ELSE 0 END) AS contraction_mrr,
    SUM(CASE WHEN event_type = 'cancel'     THEN -mrr_contribution ELSE 0 END) AS churn_mrr,
    SUM(CASE WHEN event_type = 'subscribe'  THEN mrr_contribution ELSE 0 END)
    + SUM(CASE WHEN event_type = 'upgrade'  THEN mrr_contribution ELSE 0 END)
    - SUM(CASE WHEN event_type = 'downgrade' THEN mrr_contribution ELSE 0 END)
    - SUM(CASE WHEN event_type = 'cancel'   THEN mrr_contribution ELSE 0 END) AS net_new_mrr
FROM mrr_by_event
GROUP BY year_month
ORDER BY year_month;


-- ============================================================
-- PATTERN 07. 이탈 전 행동 패턴 분析
-- 용도: 이탈 선행 신호 탐지, 개입 시점 결정
-- ============================================================
WITH churned_users AS (
    SELECT DISTINCT user_id, MIN(event_date) AS churn_date
    FROM subscriptions
    WHERE event_type = 'cancel'
      AND event_date >= '2024-01-01' AND event_date < '2024-04-01'
    GROUP BY user_id
),
retained_users AS (
    -- 같은 기간 이탈하지 않은 활성 사용자 (샘플)
    SELECT DISTINCT s.user_id
    FROM subscriptions s
    WHERE s.event_type IN ('subscribe', 'upgrade', 'downgrade')
      AND s.event_date >= '2024-01-01'
      AND s.user_id NOT IN (SELECT user_id FROM churned_users)
    LIMIT 5000
),
pre_churn_activity AS (
    -- 이탈 그룹: 이탈 30일 전 이벤트
    SELECT
        c.user_id,
        1 AS is_churned,
        COUNT(*) AS event_count_30d,
        COUNT(DISTINCT e.event_date::DATE) AS active_days_30d
    FROM churned_users c
    LEFT JOIN events e
        ON e.user_id = c.user_id
        AND e.event_date BETWEEN c.churn_date - INTERVAL '30 days' AND c.churn_date
    GROUP BY c.user_id
),
pre_retained_activity AS (
    -- 유지 그룹: 동기간 이벤트 (2024-02 기준)
    SELECT
        r.user_id,
        0 AS is_churned,
        COUNT(*) AS event_count_30d,
        COUNT(DISTINCT e.event_date::DATE) AS active_days_30d
    FROM retained_users r
    LEFT JOIN events e
        ON e.user_id = r.user_id
        AND e.event_date BETWEEN '2024-02-01' AND '2024-03-01'
    GROUP BY r.user_id
),
all_activity AS (
    SELECT * FROM pre_churn_activity
    UNION ALL
    SELECT * FROM pre_retained_activity
)
SELECT
    is_churned,
    COUNT(*) AS user_count,
    ROUND(AVG(event_count_30d), 1) AS avg_events,
    ROUND(AVG(active_days_30d), 1) AS avg_active_days
FROM all_activity
GROUP BY is_churned;


-- ============================================================
-- PATTERN 08. LTV 계산 + plan별 분解
-- 용도: 고객 가치 파악, 요금제별 수익성 비교
-- ============================================================
WITH user_ltv AS (
    SELECT
        p.user_id,
        u.plan,
        SUM(p.amount) AS ltv,
        COUNT(*) AS payment_count,
        MIN(p.paid_at) AS first_payment,
        MAX(p.paid_at) AS last_payment,
        EXTRACT(DAY FROM MAX(p.paid_at) - MIN(p.paid_at)) AS tenure_days
    FROM payments p
    JOIN users u ON p.user_id = u.user_id
    WHERE p.status = 'success'
    GROUP BY p.user_id, u.plan
)
SELECT
    plan,
    COUNT(*) AS user_count,
    ROUND(AVG(ltv), 2) AS avg_ltv,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY ltv), 2) AS median_ltv,
    ROUND(PERCENTILE_CONT(0.9) WITHIN GROUP (ORDER BY ltv), 2) AS p90_ltv,
    ROUND(AVG(tenure_days), 0) AS avg_tenure_days
FROM user_ltv
GROUP BY plan
ORDER BY avg_ltv DESC;


-- ============================================================
-- PATTERN 09. A/B 테스트 결과 집계 + 95% 신뢰구간
-- 용도: 제품 실험 결과 통계적 유의성 확인
-- Wilson score interval 적용
-- ============================================================
WITH ab_conversions AS (
    SELECT
        a.variant,
        COUNT(DISTINCT a.user_id) AS total_users,
        COUNT(DISTINCT CASE WHEN e.event_name = 'subscription_start' THEN e.user_id END) AS conversions
    FROM ab_assignments a  -- 테이블: ab_assignments(user_id, variant, assigned_at)
    LEFT JOIN events e
        ON a.user_id = e.user_id
        AND e.event_date BETWEEN a.assigned_at AND a.assigned_at + INTERVAL '14 days'
        AND e.event_name = 'subscription_start'
    GROUP BY a.variant
),
with_rate AS (
    SELECT
        variant,
        total_users AS n,
        conversions AS k,
        ROUND(conversions::NUMERIC / total_users, 4) AS conv_rate
    FROM ab_conversions
)
SELECT
    variant,
    n,
    k,
    conv_rate,
    -- Wilson score 95% 신뢰구간 (z=1.96)
    ROUND((conv_rate + 1.96*1.96/(2*n)
           - 1.96 * SQRT((conv_rate*(1-conv_rate) + 1.96*1.96/(4*n)) / n))
          / (1 + 1.96*1.96/n), 4) AS ci_lower,
    ROUND((conv_rate + 1.96*1.96/(2*n)
           + 1.96 * SQRT((conv_rate*(1-conv_rate) + 1.96*1.96/(4*n)) / n))
          / (1 + 1.96*1.96/n), 4) AS ci_upper
FROM with_rate;


-- ============================================================
-- PATTERN 10. 이탈 경로 分析 (downgrade → cancel 탐지)
-- 용도: 이탈 선행 신호로서 다운그레이드 역할 파악
-- ============================================================
WITH cancel_events AS (
    SELECT user_id, MIN(event_date) AS cancel_date
    FROM subscriptions
    WHERE event_type = 'cancel'
    GROUP BY user_id
),
downgrade_before_cancel AS (
    SELECT
        c.user_id,
        c.cancel_date,
        MAX(s.event_date) AS last_downgrade_date,
        CASE
            WHEN MAX(s.event_date) IS NULL THEN 'A_direct_cancel'
            WHEN c.cancel_date - MAX(s.event_date) <= 60 THEN 'B_downgrade_60d'
            ELSE 'C_downgrade_old'
        END AS churn_path
    FROM cancel_events c
    LEFT JOIN subscriptions s
        ON s.user_id = c.user_id
        AND s.event_type = 'downgrade'
        AND s.event_date < c.cancel_date
    GROUP BY c.user_id, c.cancel_date
)
SELECT
    churn_path,
    COUNT(*) AS user_count,
    ROUND(COUNT(*)::NUMERIC / SUM(COUNT(*)) OVER () * 100, 1) AS pct
FROM downgrade_before_cancel
GROUP BY churn_path
ORDER BY user_count DESC;


-- ============================================================
-- PATTERN 11. 데이터 품질 오디팅
-- 용도: 새 데이터 수신 시 첫 5분 오디팅 루틴
-- ============================================================
-- 행 수
SELECT COUNT(*) AS total_rows FROM events;

-- 컬럼별 NULL 현황
SELECT
    SUM(CASE WHEN user_id    IS NULL THEN 1 ELSE 0 END) AS user_id_null,
    SUM(CASE WHEN event_name IS NULL THEN 1 ELSE 0 END) AS event_name_null,
    SUM(CASE WHEN event_date IS NULL THEN 1 ELSE 0 END) AS event_date_null,
    ROUND(SUM(CASE WHEN user_id    IS NULL THEN 1 ELSE 0 END)::NUMERIC / COUNT(*) * 100, 2) AS user_id_null_pct,
    ROUND(SUM(CASE WHEN event_name IS NULL THEN 1 ELSE 0 END)::NUMERIC / COUNT(*) * 100, 2) AS event_name_null_pct
FROM events;

-- 날짜 범위
SELECT MIN(event_date) AS earliest, MAX(event_date) AS latest,
       MAX(event_date) - MIN(event_date) AS range_days
FROM events;

-- 중복 탐지
SELECT user_id, event_date::DATE, event_name, COUNT(*) AS cnt
FROM events
GROUP BY user_id, event_date::DATE, event_name
HAVING COUNT(*) > 1
ORDER BY cnt DESC LIMIT 20;

-- event_name 고유값 및 빈도
SELECT event_name, COUNT(*) AS cnt,
       ROUND(COUNT(*)::NUMERIC / SUM(COUNT(*)) OVER () * 100, 1) AS pct
FROM events
GROUP BY event_name
ORDER BY cnt DESC;


-- ============================================================
-- PATTERN 12. 사용자 최초 행동까지의 시간 (TTA)
-- 용도: 온보딩 품질 측정, 활성화 속도 파악
-- ============================================================
WITH first_action AS (
    SELECT
        u.user_id,
        u.signup_date,
        u.plan,
        MIN(e.event_date::DATE) AS first_feature_date
    FROM users u
    LEFT JOIN events e
        ON e.user_id = u.user_id
        AND e.event_name = 'feature_use'  -- 핵심 행동 이벤트명 교체
    GROUP BY u.user_id, u.signup_date, u.plan
)
SELECT
    plan,
    COUNT(*) AS cohort_size,
    -- 각 기간 내 활성화 비율
    ROUND(SUM(CASE WHEN first_feature_date - signup_date <= 1  THEN 1 ELSE 0 END)::NUMERIC / COUNT(*) * 100, 1) AS activated_d1,
    ROUND(SUM(CASE WHEN first_feature_date - signup_date <= 3  THEN 1 ELSE 0 END)::NUMERIC / COUNT(*) * 100, 1) AS activated_d3,
    ROUND(SUM(CASE WHEN first_feature_date - signup_date <= 7  THEN 1 ELSE 0 END)::NUMERIC / COUNT(*) * 100, 1) AS activated_d7,
    ROUND(SUM(CASE WHEN first_feature_date - signup_date <= 14 THEN 1 ELSE 0 END)::NUMERIC / COUNT(*) * 100, 1) AS activated_d14,
    ROUND(SUM(CASE WHEN first_feature_date - signup_date <= 30 THEN 1 ELSE 0 END)::NUMERIC / COUNT(*) * 100, 1) AS activated_d30,
    -- 중앙값 TTA (일수)
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (
        ORDER BY CASE WHEN first_feature_date IS NOT NULL THEN first_feature_date - signup_date END
    ), 1) AS median_tta_days
FROM first_action
WHERE signup_date >= '2024-01-01'
GROUP BY plan
ORDER BY activated_d7 DESC;


-- ============================================================
-- PATTERN 13. 요일 × 시간대 사용 패턴
-- 용도: 마케팅 발송 시간, 알림 최적 타이밍 결정
-- ============================================================
SELECT
    EXTRACT(DOW FROM event_date) AS day_of_week,  -- 0=일요일, 6=토요일
    -- BigQuery: EXTRACT(DAYOFWEEK FROM event_date) 1=일요일
    TO_CHAR(event_date, 'Dy') AS day_name,
    EXTRACT(HOUR FROM event_date) AS hour_of_day,
    COUNT(*) AS event_count,
    COUNT(DISTINCT user_id) AS unique_users
FROM events
WHERE event_date >= CURRENT_DATE - INTERVAL '90 days'
GROUP BY
    EXTRACT(DOW FROM event_date),
    TO_CHAR(event_date, 'Dy'),
    EXTRACT(HOUR FROM event_date)
ORDER BY day_of_week, hour_of_day;


-- ============================================================
-- PATTERN 14. NRR (Net Revenue Retention) 계산
-- 용도: 기존 고객에서의 수익 유지 및 성장 측정
-- NRR > 100% = 이탈을 expansion이 초과 보상
-- ============================================================
WITH starting_mrr AS (
    -- 12개월 전 기준 구독 중인 사용자의 당시 MRR
    SELECT
        user_id,
        SUM(mrr) AS mrr_12m_ago
    FROM subscriptions
    WHERE DATE_TRUNC('month', event_date)::DATE = DATE_TRUNC('month', CURRENT_DATE - INTERVAL '12 months')::DATE
      AND event_type IN ('subscribe', 'upgrade', 'downgrade')
    GROUP BY user_id
),
current_mrr AS (
    -- 동일 사용자의 현재 MRR
    SELECT
        user_id,
        SUM(mrr) AS mrr_current
    FROM subscriptions
    WHERE DATE_TRUNC('month', event_date)::DATE = DATE_TRUNC('month', CURRENT_DATE)::DATE
      AND event_type IN ('subscribe', 'upgrade', 'downgrade')
    GROUP BY user_id
)
SELECT
    SUM(s.mrr_12m_ago)             AS starting_mrr,
    SUM(COALESCE(c.mrr_current,0)) AS ending_mrr,
    ROUND(
        SUM(COALESCE(c.mrr_current, 0))::NUMERIC
        / NULLIF(SUM(s.mrr_12m_ago), 0) * 100,
        1
    ) AS nrr_pct
FROM starting_mrr s
LEFT JOIN current_mrr c ON s.user_id = c.user_id;


-- ============================================================
-- PATTERN 15. 이상치 탐지 (IQR 방식)
-- 용도: 데이터 품질 오디팅, 비정상 거래 탐지
-- ============================================================
WITH stats AS (
    SELECT
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY amount) AS q1,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY amount) AS q3
    FROM payments
    WHERE status = 'success' AND amount > 0
),
bounds AS (
    SELECT
        q1,
        q3,
        q3 - q1                  AS iqr,
        q1 - 1.5 * (q3 - q1)    AS lower_bound,
        q3 + 1.5 * (q3 - q1)    AS upper_bound
    FROM stats
)
SELECT
    b.lower_bound,
    b.upper_bound,
    COUNT(*) FILTER (WHERE p.amount < b.lower_bound OR p.amount > b.upper_bound) AS outlier_count,
    COUNT(*) AS total_count,
    ROUND(
        COUNT(*) FILTER (WHERE p.amount < b.lower_bound OR p.amount > b.upper_bound)::NUMERIC
        / COUNT(*) * 100, 2
    ) AS outlier_pct,
    -- 이상치 샘플 (별도 쿼리 또는 서브쿼리로 확인)
    MIN(p.amount) FILTER (WHERE p.amount > b.upper_bound) AS min_upper_outlier,
    MAX(p.amount) FILTER (WHERE p.amount > b.upper_bound) AS max_upper_outlier
FROM payments p
CROSS JOIN bounds b
WHERE p.status = 'success';


-- ============================================================
-- PATTERN 16. CTAS + 분析용 임시 테이블 생성
-- 용도: 반복 사용되는 중간 결과 테이블화
-- ============================================================
-- PostgreSQL
CREATE TABLE IF NOT EXISTS analytics.cohort_retention_2024 AS
SELECT
    r.cohort_month,
    cs.cohort_size,
    r.month_number,
    r.retained,
    ROUND(r.retained::NUMERIC / cs.cohort_size, 4) AS retention_rate
FROM retention_counts r  -- 위 PATTERN 02 CTE 참고
JOIN cohort_sizes cs ON r.cohort_month = cs.cohort_month;

-- BigQuery 버전
-- CREATE OR REPLACE TABLE `project.analytics.cohort_retention_2024` AS SELECT ...

-- 인덱스 추가 (읽기 성능)
-- CREATE INDEX idx_cohort_month ON analytics.cohort_retention_2024 (cohort_month);
