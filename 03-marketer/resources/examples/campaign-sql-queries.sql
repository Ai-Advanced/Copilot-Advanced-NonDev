-- ============================================================
-- 마케터용 캠페인 SQL 쿼리 예시 모음
-- DB: PostgreSQL 14+
-- 작성: Copilot-Advanced-NonDev 03-marketer 과정
--
-- 사용 전 주의사항:
--   1. read-only 계정으로만 실행하세요
--   2. 프로덕션 DB가 아닌 개발/스테이징 환경에서 먼저 확인하세요
--   3. 개인정보 컬럼(email, phone 등)이 포함된 결과는
--      슬랙/이메일로 공유하지 마세요
-- ============================================================

-- 스키마 참고:
-- ad_performance(id, campaign_id, campaign_name, channel, ad_set_name,
--                date, impressions, clicks, cost, conversions, revenue)
-- orders(id, order_id, customer_id, product_id, product_name,
--        category, amount, quantity, channel, created_at)
-- customers(id, email, signup_date, plan, country)
-- products(id, name, category, price, cost_price)


-- ============================================================
-- 쿼리 1. 최근 30일 채널별 일별 매출 추이
-- 목적: 채널별 일별 매출 패턴을 보고 요일/채널 효과를 파악
-- 사용 시점: 주간 성과 리뷰 시 트렌드 확인
-- ============================================================

SELECT
    DATE(o.created_at)          AS sale_date,
    o.channel,
    COUNT(o.id)                 AS order_count,
    SUM(o.amount)               AS total_revenue,
    ROUND(AVG(o.amount), 0)     AS avg_order_value
FROM orders o
WHERE o.created_at >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY DATE(o.created_at), o.channel
ORDER BY sale_date DESC, total_revenue DESC;


-- ============================================================
-- 쿼리 2. 주간 채널별 광고 성과 + ROAS + CPA
-- 목적: 어떤 채널이 가장 효율적인지 한눈에 파악
-- 사용 시점: 매주 월요일 주간 리포트 작성 시
-- ============================================================

SELECT
    a.channel,
    SUM(a.impressions)                                                  AS total_impressions,
    SUM(a.clicks)                                                       AS total_clicks,
    ROUND(SUM(a.clicks) * 100.0
          / NULLIF(SUM(a.impressions), 0), 2)                           AS ctr,
    SUM(a.cost)                                                         AS total_cost,
    SUM(a.conversions)                                                  AS total_conversions,
    SUM(a.revenue)                                                      AS total_revenue,
    ROUND(SUM(a.revenue)
          / NULLIF(SUM(a.cost), 0) * 100, 1)                           AS roas,
    ROUND(SUM(a.cost)
          / NULLIF(SUM(a.conversions), 0), 0)                          AS cpa
FROM ad_performance a
WHERE a.date >= DATE_TRUNC('week', CURRENT_DATE) - INTERVAL '7 days'
  AND a.date <  DATE_TRUNC('week', CURRENT_DATE)
GROUP BY a.channel
ORDER BY roas DESC NULLS LAST;


-- ============================================================
-- 쿼리 3. 이번 달 캠페인별 성과 상위 10개
-- 목적: 이번 달 어떤 캠페인이 효과적이었는지 비교
-- 사용 시점: 월간 캠페인 리뷰, 예산 재배분 의사결정
-- ============================================================

SELECT
    a.campaign_name,
    a.channel,
    SUM(a.cost)                                                         AS total_cost,
    SUM(a.conversions)                                                  AS total_conversions,
    SUM(a.revenue)                                                      AS total_revenue,
    ROUND(SUM(a.revenue)
          / NULLIF(SUM(a.cost), 0) * 100, 1)                           AS roas,
    ROUND(SUM(a.cost)
          / NULLIF(SUM(a.conversions), 0), 0)                          AS cpa
FROM ad_performance a
WHERE a.date >= DATE_TRUNC('month', CURRENT_DATE)
GROUP BY a.campaign_name, a.channel
ORDER BY roas DESC NULLS LAST
LIMIT 10;


-- ============================================================
-- 쿼리 4. 이번 주 vs 전주 채널별 성과 비교
-- 목적: 주간 증감률을 빠르게 파악해서 이상 징후 조기 발견
-- 사용 시점: 주간 리포트 작성, 팀 브리핑
-- ============================================================

WITH this_week AS (
    SELECT
        channel,
        SUM(cost)        AS cost_tw,
        SUM(revenue)     AS revenue_tw,
        SUM(conversions) AS conv_tw,
        ROUND(SUM(revenue) / NULLIF(SUM(cost), 0) * 100, 1) AS roas_tw
    FROM ad_performance
    WHERE date >= DATE_TRUNC('week', CURRENT_DATE) - INTERVAL '7 days'
      AND date <  DATE_TRUNC('week', CURRENT_DATE)
    GROUP BY channel
),
last_week AS (
    SELECT
        channel,
        SUM(cost)        AS cost_lw,
        SUM(revenue)     AS revenue_lw,
        SUM(conversions) AS conv_lw,
        ROUND(SUM(revenue) / NULLIF(SUM(cost), 0) * 100, 1) AS roas_lw
    FROM ad_performance
    WHERE date >= DATE_TRUNC('week', CURRENT_DATE) - INTERVAL '14 days'
      AND date <  DATE_TRUNC('week', CURRENT_DATE) - INTERVAL '7 days'
    GROUP BY channel
)
SELECT
    COALESCE(t.channel, l.channel)          AS channel,
    l.cost_lw,
    t.cost_tw,
    ROUND((t.cost_tw - l.cost_lw)
          / NULLIF(l.cost_lw, 0) * 100, 1) AS cost_change_pct,
    l.roas_lw,
    t.roas_tw,
    ROUND(t.roas_tw - l.roas_lw, 1)        AS roas_change
FROM this_week t
FULL OUTER JOIN last_week l ON t.channel = l.channel
ORDER BY COALESCE(t.cost_tw, 0) DESC;


-- ============================================================
-- 쿼리 5. 매출 상위 10개 상품 (이번 달)
-- 목적: 어떤 상품이 매출을 견인하는지 파악
-- 사용 시점: 재고 관리, 광고 소재 우선순위 결정
-- ============================================================

SELECT
    p.name              AS product_name,
    p.category,
    COUNT(o.id)         AS order_count,
    SUM(o.quantity)     AS total_quantity,
    SUM(o.amount)       AS total_revenue,
    ROUND(AVG(o.amount), 0) AS avg_order_value
FROM orders o
JOIN products p ON o.product_id = p.id
WHERE o.created_at >= DATE_TRUNC('month', CURRENT_DATE)
GROUP BY p.name, p.category
ORDER BY total_revenue DESC
LIMIT 10;


-- ============================================================
-- 쿼리 6. 신규 vs 재구매 고객 비율 (이번 달)
-- 목적: 신규 고객 획득과 기존 고객 유지 균형 파악
-- 사용 시점: 월간 성과 리뷰, 마케팅 전략 수립
-- ============================================================

WITH this_month_buyers AS (
    SELECT DISTINCT customer_id
    FROM orders
    WHERE created_at >= DATE_TRUNC('month', CURRENT_DATE)
),
returning_buyers AS (
    SELECT DISTINCT tmb.customer_id
    FROM this_month_buyers tmb
    WHERE EXISTS (
        SELECT 1 FROM orders o
        WHERE o.customer_id = tmb.customer_id
          AND o.created_at < DATE_TRUNC('month', CURRENT_DATE)
    )
)
SELECT
    COUNT(tmb.customer_id)                                          AS total_buyers,
    COUNT(rb.customer_id)                                           AS returning_buyers,
    COUNT(tmb.customer_id) - COUNT(rb.customer_id)                  AS new_buyers,
    ROUND(COUNT(rb.customer_id) * 100.0
          / NULLIF(COUNT(tmb.customer_id), 0), 1)                  AS returning_rate,
    ROUND((COUNT(tmb.customer_id) - COUNT(rb.customer_id)) * 100.0
          / NULLIF(COUNT(tmb.customer_id), 0), 1)                  AS new_buyer_rate
FROM this_month_buyers tmb
LEFT JOIN returning_buyers rb ON tmb.customer_id = rb.customer_id;


-- ============================================================
-- 쿼리 7. 채널별 신규 고객 첫 구매 현황
-- 목적: 어떤 채널이 신규 고객을 가장 많이 데려오는지 파악 (CAC 계산 기반)
-- 사용 시점: 채널 예산 배분, 신규 고객 획득 전략
-- ============================================================

WITH first_orders AS (
    SELECT
        customer_id,
        channel,
        MIN(created_at) AS first_order_at,
        ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY created_at ASC) AS rn
    FROM orders
    GROUP BY customer_id, channel
)
SELECT
    channel,
    COUNT(*)                                AS new_customers,
    ROUND(COUNT(*) * 100.0
          / SUM(COUNT(*)) OVER (), 1)       AS channel_share_pct
FROM first_orders
WHERE rn = 1
  AND first_order_at >= DATE_TRUNC('month', CURRENT_DATE)
GROUP BY channel
ORDER BY new_customers DESC;


-- ============================================================
-- 쿼리 8. 월별 코호트 재구매율 (리텐션 매트릭스)
-- 목적: 고객 생애주기와 이탈 패턴 파악
-- 사용 시점: 분기별 전략 리뷰, 리텐션 캠페인 기획
-- ============================================================

WITH first_purchase AS (
    -- 각 고객의 첫 구매 월 (코호트 기준)
    SELECT
        customer_id,
        DATE_TRUNC('month', MIN(created_at)) AS cohort_month
    FROM orders
    GROUP BY customer_id
),
cohort_activity AS (
    -- 각 주문에 코호트 월과 경과 개월수 연결
    SELECT
        fp.cohort_month,
        o.customer_id,
        EXTRACT(YEAR FROM AGE(DATE_TRUNC('month', o.created_at), fp.cohort_month)) * 12
        + EXTRACT(MONTH FROM AGE(DATE_TRUNC('month', o.created_at), fp.cohort_month))
            AS months_later
    FROM orders o
    JOIN first_purchase fp ON o.customer_id = fp.customer_id
),
cohort_size AS (
    -- 코호트별 초기 고객 수
    SELECT cohort_month, COUNT(DISTINCT customer_id) AS size
    FROM cohort_activity
    WHERE months_later = 0
    GROUP BY cohort_month
)
SELECT
    ca.cohort_month,
    ca.months_later,
    cs.size                                                    AS cohort_size,
    COUNT(DISTINCT ca.customer_id)                             AS active_customers,
    ROUND(COUNT(DISTINCT ca.customer_id) * 100.0
          / NULLIF(cs.size, 0), 1)                            AS retention_rate
FROM cohort_activity ca
JOIN cohort_size cs ON ca.cohort_month = cs.cohort_month
GROUP BY ca.cohort_month, ca.months_later, cs.size
ORDER BY ca.cohort_month, ca.months_later;


-- ============================================================
-- 쿼리 9. 이탈 위험 고객 세그먼트 (재구매 독촉 대상)
-- 목적: 평균 구매 주기의 2배 이상 미구매 고객 식별
-- 사용 시점: 재구매 독촉 이메일/광고 리타겟팅 대상 추출
-- 주의: customer_id만 출력 (email 등 개인정보 포함 금지)
-- ============================================================

WITH purchase_intervals AS (
    SELECT
        customer_id,
        created_at,
        LAG(created_at) OVER (PARTITION BY customer_id ORDER BY created_at) AS prev_order_at,
        COUNT(*) OVER (PARTITION BY customer_id)                             AS total_orders
    FROM orders
),
customer_stats AS (
    SELECT
        customer_id,
        MAX(created_at)                                             AS last_order_at,
        AVG(EXTRACT(EPOCH FROM (created_at - prev_order_at)) / 86400) AS avg_days_between,
        total_orders
    FROM purchase_intervals
    WHERE prev_order_at IS NOT NULL
      AND total_orders >= 2
    GROUP BY customer_id, total_orders
)
SELECT
    customer_id,
    -- email 제외 (개인정보 보호)
    last_order_at::date                     AS last_order_date,
    ROUND(avg_days_between, 0)             AS avg_days_between_orders,
    (CURRENT_DATE - last_order_at::date)   AS days_since_last_order,
    total_orders
FROM customer_stats
WHERE (CURRENT_DATE - last_order_at::date) > avg_days_between * 2
ORDER BY days_since_last_order DESC
LIMIT 200;


-- ============================================================
-- 쿼리 10. RFM 분석 — 고객 세그먼트 분류
-- 목적: 고객을 구매 최신성·빈도·금액 기준으로 세그먼트화
-- 사용 시점: 개인화 마케팅 전략 수립, 세그먼트별 캠페인 기획
-- 주의: customer_id만 출력 (개인정보 제외)
-- ============================================================

WITH rfm_base AS (
    SELECT
        customer_id,
        -- R: 마지막 구매일로부터 경과 일수 (낮을수록 최근)
        CURRENT_DATE - MAX(created_at)::date     AS recency_days,
        -- F: 총 구매 횟수
        COUNT(DISTINCT id)                        AS frequency,
        -- M: 총 구매 금액
        SUM(amount)                               AS monetary
    FROM orders
    GROUP BY customer_id
),
rfm_scored AS (
    SELECT
        customer_id,
        recency_days,
        frequency,
        monetary,
        -- R 점수: 최근일수록 높은 점수 (NTILE 5분위)
        6 - NTILE(5) OVER (ORDER BY recency_days ASC)  AS r_score,
        -- F 점수: 빈도 높을수록 높은 점수
        NTILE(5) OVER (ORDER BY frequency ASC)         AS f_score,
        -- M 점수: 금액 높을수록 높은 점수
        NTILE(5) OVER (ORDER BY monetary ASC)          AS m_score
    FROM rfm_base
)
SELECT
    customer_id,
    recency_days,
    frequency,
    monetary,
    r_score,
    f_score,
    m_score,
    -- RFM 복합 점수 (문자 연결)
    CONCAT(r_score, f_score, m_score)               AS rfm_score,
    -- 세그먼트 분류
    CASE
        WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'VIP 고객'
        WHEN r_score >= 3 AND f_score >= 3                  THEN '충성 고객'
        WHEN r_score >= 4 AND f_score <= 2                  THEN '신규 고객'
        WHEN r_score <= 2 AND f_score >= 3                  THEN '이탈 위험'
        WHEN r_score = 1                                     THEN '휴면 고객'
        ELSE '일반 고객'
    END AS segment
FROM rfm_scored
ORDER BY monetary DESC;


-- ============================================================
-- 쿼리 11. 카테고리별 월별 매출 추이 (피벗 없이)
-- 목적: 카테고리 성장 트렌드와 시즌 패턴 파악
-- 사용 시점: 상품 기획 회의, 광고 예산 배분
-- ============================================================

SELECT
    DATE_TRUNC('month', o.created_at)::date     AS month,
    p.category,
    COUNT(o.id)                                  AS order_count,
    SUM(o.amount)                                AS total_revenue,
    ROUND(AVG(o.amount), 0)                      AS avg_order_value
FROM orders o
JOIN products p ON o.product_id = p.id
WHERE o.created_at >= CURRENT_DATE - INTERVAL '6 months'
GROUP BY DATE_TRUNC('month', o.created_at), p.category
ORDER BY month DESC, total_revenue DESC;


-- ============================================================
-- 쿼리 12. 시간대별 주문 패턴
-- 목적: 광고 집행 시간대(스케줄링) 최적화 기준 마련
-- 사용 시점: 광고 시간대 설정, SNS 게시 최적 타이밍
-- ============================================================

SELECT
    EXTRACT(HOUR FROM created_at)   AS hour_of_day,
    EXTRACT(DOW FROM created_at)    AS day_of_week, -- 0=일, 1=월, ..., 6=토
    COUNT(*)                        AS order_count,
    SUM(amount)                     AS total_revenue,
    ROUND(AVG(amount), 0)           AS avg_order_value
FROM orders
WHERE created_at >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY hour_of_day, day_of_week
ORDER BY order_count DESC
LIMIT 20;


-- ============================================================
-- 쿼리 13. 고객 LTV(생애가치) 근사 계산
-- 목적: 고가치 고객 파악, CAC 대비 LTV 분석 기반
-- 사용 시점: 마케팅 예산 ROI 계산, VIP 프로그램 설계
-- 주의: customer_id만 출력 (email 제외)
-- ============================================================

SELECT
    customer_id,
    -- 개인정보 컬럼(email) 의도적으로 제외
    COUNT(DISTINCT id)                                          AS order_count,
    SUM(amount)                                                 AS total_ltv,
    MIN(created_at)::date                                       AS first_order_date,
    MAX(created_at)::date                                       AS last_order_date,
    (MAX(created_at)::date - MIN(created_at)::date)             AS customer_lifespan_days,
    ROUND(AVG(amount), 0)                                       AS avg_order_value,
    -- 월평균 매출 (고객 생애 기간 기준)
    ROUND(SUM(amount) / NULLIF(
        (MAX(created_at)::date - MIN(created_at)::date) / 30.0, 0
    ), 0)                                                       AS monthly_avg_revenue
FROM orders
GROUP BY customer_id
HAVING COUNT(DISTINCT id) >= 2  -- 2회 이상 구매 고객만
ORDER BY total_ltv DESC
LIMIT 100;


-- ============================================================
-- 쿼리 14. 광고 성과 이상 탐지 (전일 대비 급변 감지)
-- 목적: ROAS·CTR이 평균에서 크게 벗어난 캠페인 자동 탐지
-- 사용 시점: 매일 아침 이상 징후 모니터링
-- ============================================================

WITH daily_avg AS (
    -- 최근 14일 채널별 평균 성과 (어제 제외)
    SELECT
        channel,
        ROUND(AVG(clicks * 100.0 / NULLIF(impressions, 0)), 2) AS avg_ctr,
        ROUND(AVG(revenue / NULLIF(cost, 0) * 100), 1)         AS avg_roas
    FROM ad_performance
    WHERE date >= CURRENT_DATE - INTERVAL '15 days'
      AND date <  CURRENT_DATE - INTERVAL '1 day'
    GROUP BY channel
),
yesterday AS (
    -- 어제 성과
    SELECT
        channel,
        SUM(impressions)    AS impressions,
        SUM(clicks)         AS clicks,
        SUM(cost)           AS cost,
        SUM(revenue)        AS revenue,
        ROUND(SUM(clicks) * 100.0 / NULLIF(SUM(impressions), 0), 2) AS ctr,
        ROUND(SUM(revenue) / NULLIF(SUM(cost), 0) * 100, 1)         AS roas
    FROM ad_performance
    WHERE date = CURRENT_DATE - INTERVAL '1 day'
    GROUP BY channel
)
SELECT
    y.channel,
    y.ctr           AS yesterday_ctr,
    d.avg_ctr       AS avg_14d_ctr,
    y.roas          AS yesterday_roas,
    d.avg_roas      AS avg_14d_roas,
    -- 이상 탐지 플래그
    CASE
        WHEN y.ctr < d.avg_ctr * 0.7 THEN '[경고] CTR 급감 (평균 대비 30% 이상 하락)'
        WHEN y.ctr > d.avg_ctr * 1.5 THEN '[주목] CTR 급등 (평균 대비 50% 이상 상승)'
        ELSE '정상'
    END AS ctr_flag,
    CASE
        WHEN y.roas < d.avg_roas * 0.7 THEN '[경고] ROAS 급감'
        WHEN y.roas > d.avg_roas * 1.5 THEN '[주목] ROAS 급등'
        ELSE '정상'
    END AS roas_flag
FROM yesterday y
LEFT JOIN daily_avg d ON y.channel = d.channel
ORDER BY y.cost DESC;


-- ============================================================
-- 쿼리 15. 재구매 주기 분포 분석
-- 목적: 재구매 독촉 이메일 발송 타이밍 최적화
-- 사용 시점: 이메일 자동화 워크플로우 설계, 재구매 캠페인
-- ============================================================

WITH purchase_gaps AS (
    SELECT
        customer_id,
        EXTRACT(DAY FROM
            created_at -
            LAG(created_at) OVER (PARTITION BY customer_id ORDER BY created_at)
        ) AS days_between_orders
    FROM orders
)
SELECT
    CASE
        WHEN days_between_orders <= 7   THEN '0-7일'
        WHEN days_between_orders <= 14  THEN '8-14일'
        WHEN days_between_orders <= 30  THEN '15-30일'
        WHEN days_between_orders <= 60  THEN '31-60일'
        WHEN days_between_orders <= 90  THEN '61-90일'
        ELSE '90일 초과'
    END                         AS days_range,
    COUNT(*)                    AS order_pairs,
    ROUND(COUNT(*) * 100.0
          / SUM(COUNT(*)) OVER (), 1) AS pct
FROM purchase_gaps
WHERE days_between_orders IS NOT NULL
GROUP BY
    CASE
        WHEN days_between_orders <= 7   THEN '0-7일'
        WHEN days_between_orders <= 14  THEN '8-14일'
        WHEN days_between_orders <= 30  THEN '15-30일'
        WHEN days_between_orders <= 60  THEN '31-60일'
        WHEN days_between_orders <= 90  THEN '61-90일'
        ELSE '90일 초과'
    END,
    -- 정렬용
    MIN(days_between_orders)
ORDER BY MIN(days_between_orders) ASC;
