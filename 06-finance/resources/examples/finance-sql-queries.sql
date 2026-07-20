-- =============================================================================
-- 재무 SQL 완성 예시 모음
-- 파일: finance-sql-queries.sql
-- DB: PostgreSQL (다른 DB는 주석으로 방언 차이 표시)
-- 용도: 재무/회계팀 실무에서 바로 복붙하여 사용
--
-- 주의: 실행 전 테이블명/컬럼명을 사내 ERP 스키마에 맞게 수정하세요.
--       프로덕션 DB에는 반드시 READ-ONLY 계정으로 실행하세요.
-- =============================================================================

-- =============================================================================
-- [공통 테이블 스키마 가정]
--
-- gl_entries (원장)
--   id           SERIAL PRIMARY KEY
--   entry_date   DATE
--   account_code VARCHAR(10)
--   dept_code    VARCHAR(20)
--   debit        NUMERIC(18,2)
--   credit       NUMERIC(18,2)
--   description  TEXT
--
-- account_master (계정마스터)
--   account_code  VARCHAR(10) PRIMARY KEY
--   account_name  VARCHAR(100)
--   account_type  VARCHAR(20)   -- 'revenue','cogs','sg_and_a','asset','liability','equity'
--   pl_category   VARCHAR(50)   -- 손익 항목명
--   pl_order      INTEGER       -- 손익 표시 순서
--   bs_category   VARCHAR(50)   -- 재무상태표 항목명
--   cf_category   VARCHAR(50)   -- 현금흐름 항목명
--
-- dept_master (부서마스터)
--   dept_code     VARCHAR(20) PRIMARY KEY
--   dept_name     VARCHAR(100)
--   division_name VARCHAR(100)
--
-- budget (예산)
--   year          INTEGER
--   month         INTEGER
--   dept_code     VARCHAR(20)
--   account_code  VARCHAR(10)
--   budget_amount NUMERIC(18,2)
--
-- exchange_rates (환율)
--   rate_date     DATE
--   currency_code VARCHAR(3)
--   krw_rate      NUMERIC(10,4)
--
-- receivables (미수금/매출채권)
--   invoice_id    SERIAL PRIMARY KEY
--   customer_id   VARCHAR(20)
--   invoice_date  DATE
--   due_date      DATE
--   amount        NUMERIC(18,2)
--   paid_date     DATE
-- =============================================================================


-- =============================================================================
-- 쿼리 01. 월별 손익계산서 (P&L)
-- 용도: 특정 월의 손익계산서 항목별 금액 집계
-- =============================================================================
SELECT
    m.pl_order,
    m.pl_category                                       AS "P&L 항목",
    SUM(
        CASE
            WHEN m.account_type = 'revenue' THEN e.credit - e.debit
            ELSE                                  e.debit  - e.credit
        END
    )                                                   AS "금액(원)"
FROM gl_entries      e
JOIN account_master  m ON e.account_code = m.account_code
WHERE e.entry_date >= '2026-06-01'
  AND e.entry_date  < '2026-07-01'
  AND m.pl_category IS NOT NULL
GROUP BY m.pl_order, m.pl_category
ORDER BY m.pl_order;

-- 소계 행 포함 버전 (UNION ALL)
-- WITH pl_base AS (
--     SELECT m.pl_order, m.pl_category,
--            SUM(CASE WHEN m.account_type = 'revenue' THEN e.credit - e.debit
--                     ELSE e.debit - e.credit END) AS amount
--     FROM gl_entries e JOIN account_master m ON e.account_code = m.account_code
--     WHERE e.entry_date >= '2026-06-01' AND e.entry_date < '2026-07-01'
--     GROUP BY m.pl_order, m.pl_category
-- )
-- SELECT pl_order, pl_category, amount FROM pl_base
-- UNION ALL
-- SELECT 20, '매출총이익', SUM(CASE WHEN pl_order < 20 THEN amount ELSE 0 END) FROM pl_base WHERE pl_order < 20
-- UNION ALL
-- SELECT 40, '영업이익', SUM(CASE WHEN pl_order < 20 THEN amount WHEN pl_order BETWEEN 20 AND 39 THEN -amount ELSE 0 END) FROM pl_base WHERE pl_order < 40
-- ORDER BY 1;


-- =============================================================================
-- 쿼리 02. 부문별 손익 피벗 (CASE WHEN 방식)
-- 용도: 부문(division)별로 열로 펼쳐진 P&L 표
-- =============================================================================
SELECT
    m.pl_order,
    m.pl_category                                              AS "항목",
    SUM(CASE WHEN d.division_name = '영업본부'
             THEN CASE WHEN m.account_type = 'revenue' THEN e.credit - e.debit
                       ELSE e.debit - e.credit END
             ELSE 0 END)                                       AS "영업본부",
    SUM(CASE WHEN d.division_name = '제조본부'
             THEN CASE WHEN m.account_type = 'revenue' THEN e.credit - e.debit
                       ELSE e.debit - e.credit END
             ELSE 0 END)                                       AS "제조본부",
    SUM(CASE WHEN d.division_name = '관리본부'
             THEN CASE WHEN m.account_type = 'revenue' THEN e.credit - e.debit
                       ELSE e.debit - e.credit END
             ELSE 0 END)                                       AS "관리본부",
    SUM(
        CASE WHEN m.account_type = 'revenue' THEN e.credit - e.debit
             ELSE e.debit - e.credit END
    )                                                          AS "합계"
FROM gl_entries     e
JOIN account_master m ON e.account_code = m.account_code
JOIN dept_master    d ON e.dept_code    = d.dept_code
WHERE e.entry_date >= '2026-01-01'
  AND e.entry_date  < '2026-07-01'
  AND m.pl_category IS NOT NULL
GROUP BY m.pl_order, m.pl_category
ORDER BY m.pl_order;


-- =============================================================================
-- 쿼리 03. 전년 동기 대비 매출 비교 (YoY)
-- 용도: 월별 매출 당기/전기 비교, 증감액, 증감률
-- =============================================================================
WITH curr_year AS (
    SELECT
        DATE_TRUNC('month', entry_date)  AS month,
        SUM(credit - debit)              AS revenue
    FROM gl_entries
    WHERE account_code LIKE '4%'
      AND entry_date >= '2026-01-01'
      AND entry_date  < '2027-01-01'
    GROUP BY DATE_TRUNC('month', entry_date)
),
prev_year AS (
    SELECT
        DATE_TRUNC('month', entry_date)  AS month,
        SUM(credit - debit)              AS revenue
    FROM gl_entries
    WHERE account_code LIKE '4%'
      AND entry_date >= '2025-01-01'
      AND entry_date  < '2026-01-01'
    GROUP BY DATE_TRUNC('month', entry_date)
)
SELECT
    TO_CHAR(c.month, 'YYYY-MM')                            AS "월",
    COALESCE(c.revenue, 0)                                 AS "당기매출",
    COALESCE(p.revenue, 0)                                 AS "전기매출",
    COALESCE(c.revenue, 0) - COALESCE(p.revenue, 0)       AS "증감액",
    ROUND(
        (COALESCE(c.revenue, 0) - COALESCE(p.revenue, 0))
        / NULLIF(ABS(COALESCE(p.revenue, 0)), 0) * 100,
        1
    )                                                      AS "증감률(%)"
FROM curr_year c
LEFT JOIN prev_year p
  ON c.month = p.month + INTERVAL '1 year'
ORDER BY c.month;


-- =============================================================================
-- 쿼리 04. 분기별 영업이익 QoQ (윈도우 함수)
-- 용도: 분기별 영업이익과 전 분기 대비 증감
-- =============================================================================
WITH quarterly_income AS (
    SELECT
        DATE_PART('year',    entry_date)    AS yr,
        DATE_PART('quarter', entry_date)    AS qtr,
        SUM(
            CASE
                WHEN account_code LIKE '4%' THEN credit - debit  -- 수익
                WHEN account_code LIKE '5%' THEN -(debit - credit) -- 비용
                ELSE 0
            END
        )                                   AS op_income
    FROM gl_entries
    WHERE entry_date >= '2025-01-01'
    GROUP BY DATE_PART('year', entry_date),
             DATE_PART('quarter', entry_date)
)
SELECT
    yr                                                         AS "연도",
    qtr                                                        AS "분기",
    ROUND(op_income)                                           AS "영업이익",
    ROUND(LAG(op_income) OVER (ORDER BY yr, qtr))              AS "전분기",
    ROUND(op_income - LAG(op_income) OVER (ORDER BY yr, qtr)) AS "QoQ증감",
    ROUND(
        (op_income - LAG(op_income) OVER (ORDER BY yr, qtr))
        / NULLIF(ABS(LAG(op_income) OVER (ORDER BY yr, qtr)), 0) * 100,
        1
    )                                                          AS "QoQ증감률(%)"
FROM quarterly_income
ORDER BY yr, qtr;


-- =============================================================================
-- 쿼리 05. 예산 대비 실적 편차 분석
-- 용도: 계정과목 + 부서별 예산-실적 비교, 편차 내림차순
-- =============================================================================
SELECT
    b.dept_code                                            AS "부서코드",
    b.account_code                                         AS "계정코드",
    m.account_name                                         AS "계정명",
    ROUND(b.budget_amount)                                 AS "예산",
    ROUND(COALESCE(a.actual_amount, 0))                    AS "실적",
    ROUND(COALESCE(a.actual_amount, 0) - b.budget_amount)  AS "편차",
    CASE
        WHEN b.budget_amount = 0 THEN NULL
        ELSE ROUND(
            COALESCE(a.actual_amount, 0) / b.budget_amount * 100,
            1
        )
    END                                                    AS "달성률(%)"
FROM budget b
LEFT JOIN (
    SELECT
        dept_code,
        account_code,
        SUM(
            CASE
                WHEN account_code LIKE '4%' THEN credit - debit
                ELSE debit - credit
            END
        ) AS actual_amount
    FROM gl_entries
    WHERE entry_date >= '2026-01-01'
      AND entry_date  < '2026-07-01'
    GROUP BY dept_code, account_code
) a
  ON b.dept_code    = a.dept_code
 AND b.account_code = a.account_code
JOIN account_master m ON b.account_code = m.account_code
WHERE b.year = 2026
ORDER BY ABS(COALESCE(a.actual_amount, 0) - b.budget_amount) DESC;


-- =============================================================================
-- 쿼리 06. 거래일 기준 환율 적용 외화 매출 원화 환산
-- 용도: 외화 거래를 거래일 기준 고시 환율로 원화 환산
--       환율이 없는 날은 직전 영업일 환율 사용
-- =============================================================================
WITH dated_rates AS (
    SELECT
        rate_date,
        currency_code,
        krw_rate,
        LEAD(rate_date) OVER (
            PARTITION BY currency_code
            ORDER BY rate_date
        ) AS next_date
    FROM exchange_rates
)
SELECT
    e.entry_date                                            AS "전표일자",
    e.account_code                                          AS "계정코드",
    e.dept_code                                             AS "부서코드",
    -- 여기서는 description에 통화 코드가 있다고 가정 (실제는 별도 컬럼으로)
    r.currency_code                                         AS "통화",
    ROUND(e.credit - e.debit)                               AS "외화금액",
    r.krw_rate                                              AS "적용환율",
    ROUND((e.credit - e.debit) * r.krw_rate)               AS "원화환산액"
FROM gl_entries e
-- 통화 코드 기준 환율 조인 (거래일 직전 최신 환율)
JOIN dated_rates r
  ON r.currency_code = 'USD'          -- 실제는 거래별 통화 컬럼 참조
 AND r.rate_date    <= e.entry_date
 AND (r.next_date    > e.entry_date OR r.next_date IS NULL)
WHERE e.account_code LIKE '4%'
  AND e.entry_date >= '2026-01-01'
  AND e.entry_date  < '2026-07-01'
ORDER BY e.entry_date;


-- =============================================================================
-- 쿼리 07. 미수금 Aging 분석
-- 용도: 미결제 채권을 경과일 구간별로 집계
-- 기준일: 실행 당일 (CURRENT_DATE)
-- =============================================================================
SELECT
    customer_id                                                        AS "거래처코드",
    COUNT(*)                                                           AS "미결제건수",
    ROUND(SUM(amount))                                                 AS "미결제합계",
    ROUND(SUM(CASE WHEN CURRENT_DATE - due_date <=  30 THEN amount ELSE 0 END)) AS "30일이내",
    ROUND(SUM(CASE WHEN CURRENT_DATE - due_date BETWEEN  31 AND  60 THEN amount ELSE 0 END)) AS "31~60일",
    ROUND(SUM(CASE WHEN CURRENT_DATE - due_date BETWEEN  61 AND  90 THEN amount ELSE 0 END)) AS "61~90일",
    ROUND(SUM(CASE WHEN CURRENT_DATE - due_date  > 90 THEN amount ELSE 0 END)) AS "90일초과",
    MAX(CURRENT_DATE - due_date)                                       AS "최장연체일"
FROM receivables
WHERE paid_date IS NULL
GROUP BY customer_id
ORDER BY SUM(amount) DESC;

-- 전체 합계 행 추가 버전
-- SELECT * FROM (...위 쿼리...)
-- UNION ALL
-- SELECT '합계', COUNT(*), SUM(amount), ...
-- FROM receivables WHERE paid_date IS NULL;


-- =============================================================================
-- 쿼리 08. 재무상태표 계정 잔액 (기초 + 당기 증감)
-- 용도: 특정 기간의 자산/부채/자본 계정 잔액 산출
-- =============================================================================
WITH opening_balance AS (
    -- 기초 잔액 (2026-01-01 이전 누적)
    SELECT
        account_code,
        SUM(debit) - SUM(credit)   AS opening
    FROM gl_entries
    WHERE entry_date < '2026-01-01'
    GROUP BY account_code
),
period_movement AS (
    -- 당기 증감 (2026년 상반기)
    SELECT
        account_code,
        SUM(debit)    AS period_dr,
        SUM(credit)   AS period_cr
    FROM gl_entries
    WHERE entry_date >= '2026-01-01'
      AND entry_date  < '2026-07-01'
    GROUP BY account_code
)
SELECT
    m.account_code                                        AS "계정코드",
    m.account_name                                        AS "계정명",
    m.bs_category                                         AS "재무상태표항목",
    ROUND(COALESCE(o.opening, 0))                         AS "기초잔액",
    ROUND(COALESCE(p.period_dr, 0))                       AS "당기차변",
    ROUND(COALESCE(p.period_cr, 0))                       AS "당기대변",
    ROUND(
        COALESCE(o.opening, 0)
        + COALESCE(p.period_dr, 0)
        - COALESCE(p.period_cr, 0)
    )                                                     AS "기말잔액"
FROM account_master       m
LEFT JOIN opening_balance o ON m.account_code = o.account_code
LEFT JOIN period_movement p ON m.account_code = p.account_code
WHERE m.bs_category IS NOT NULL
ORDER BY m.account_code;


-- =============================================================================
-- 쿼리 09. 현금흐름 월별 집계
-- 용도: 현금 계정(보통예금, 당좌예금 등) 월별 증감 분석
-- =============================================================================
SELECT
    TO_CHAR(DATE_TRUNC('month', entry_date), 'YYYY-MM')   AS "월",
    SUM(debit)                                             AS "현금유입",
    SUM(credit)                                            AS "현금유출",
    SUM(debit) - SUM(credit)                               AS "순증감",
    SUM(SUM(debit) - SUM(credit))
        OVER (ORDER BY DATE_TRUNC('month', entry_date))   AS "누적잔액변동"
FROM gl_entries
WHERE account_code IN ('1010', '1011', '1012')  -- 현금, 보통예금, 당좌예금
  AND entry_date >= '2026-01-01'
  AND entry_date  < '2027-01-01'
GROUP BY DATE_TRUNC('month', entry_date)
ORDER BY "월";


-- =============================================================================
-- 쿼리 10. 계정과목별 시산표 (Trial Balance)
-- 용도: 특정 기간의 계정별 차변/대변 합계 및 잔액
-- =============================================================================
SELECT
    e.account_code                                        AS "계정코드",
    m.account_name                                        AS "계정명",
    m.account_type                                        AS "계정유형",
    ROUND(SUM(e.debit))                                   AS "차변합계",
    ROUND(SUM(e.credit))                                  AS "대변합계",
    ROUND(
        CASE
            WHEN m.account_type IN ('asset', 'expense')
                THEN SUM(e.debit) - SUM(e.credit)
            ELSE
                SUM(e.credit) - SUM(e.debit)
        END
    )                                                     AS "잔액"
FROM gl_entries      e
JOIN account_master  m ON e.account_code = m.account_code
WHERE e.entry_date >= '2026-01-01'
  AND e.entry_date  < '2026-07-01'
GROUP BY e.account_code, m.account_name, m.account_type
ORDER BY e.account_code;

-- 합계 검증 (차변 합계 = 대변 합계 여부)
-- SELECT
--     SUM(debit) AS total_debit, SUM(credit) AS total_credit,
--     SUM(debit) - SUM(credit) AS diff
-- FROM gl_entries
-- WHERE entry_date >= '2026-01-01' AND entry_date < '2026-07-01';


-- =============================================================================
-- 쿼리 11. 비용 구조 분석 (판관비 상세)
-- 용도: 판관비 계정별 금액, 전체 판관비 대비 비중
-- =============================================================================
WITH sg_and_a_total AS (
    SELECT SUM(debit - credit) AS total
    FROM gl_entries e
    JOIN account_master m ON e.account_code = m.account_code
    WHERE m.account_type = 'sg_and_a'
      AND e.entry_date >= '2026-01-01'
      AND e.entry_date  < '2026-07-01'
)
SELECT
    e.account_code                                        AS "계정코드",
    m.account_name                                        AS "계정명",
    ROUND(SUM(e.debit - e.credit))                        AS "금액",
    ROUND(
        SUM(e.debit - e.credit) / NULLIF(t.total, 0) * 100,
        1
    )                                                     AS "비중(%)"
FROM gl_entries      e
JOIN account_master  m ON e.account_code = m.account_code
CROSS JOIN sg_and_a_total t
WHERE m.account_type = 'sg_and_a'
  AND e.entry_date >= '2026-01-01'
  AND e.entry_date  < '2026-07-01'
GROUP BY e.account_code, m.account_name, t.total
ORDER BY SUM(e.debit - e.credit) DESC;


-- =============================================================================
-- 쿼리 12. 이상치 탐지 - 중복 전표 확인
-- 용도: 동일 날짜 + 계정코드 + 금액이 반복 입력된 전표 목록
-- =============================================================================
SELECT
    entry_date                                            AS "전표일자",
    account_code                                          AS "계정코드",
    debit                                                 AS "차변",
    credit                                                AS "대변",
    COUNT(*)                                              AS "중복건수"
FROM gl_entries
WHERE entry_date >= '2026-01-01'
  AND entry_date  < '2026-07-01'
GROUP BY entry_date, account_code, debit, credit
HAVING COUNT(*) > 1
ORDER BY COUNT(*) DESC, entry_date;


-- =============================================================================
-- 쿼리 13. 월별 부서별 매출 현황 (집계 테이블)
-- 용도: 월 × 부서 매트릭스 형태 매출 현황
-- =============================================================================
SELECT
    d.division_name                                       AS "본부",
    d.dept_name                                           AS "부서",
    TO_CHAR(DATE_TRUNC('month', e.entry_date), 'YYYY-MM') AS "월",
    ROUND(SUM(e.credit - e.debit))                        AS "매출"
FROM gl_entries     e
JOIN account_master m ON e.account_code = m.account_code
JOIN dept_master    d ON e.dept_code    = d.dept_code
WHERE m.account_type = 'revenue'
  AND e.entry_date  >= '2026-01-01'
  AND e.entry_date   < '2026-07-01'
GROUP BY d.division_name, d.dept_name,
         DATE_TRUNC('month', e.entry_date)
ORDER BY d.division_name, d.dept_name,
         DATE_TRUNC('month', e.entry_date);


-- =============================================================================
-- 쿼리 14. 재무비율 계산 뷰 (요약)
-- 용도: 주요 재무비율을 한 번에 조회
-- =============================================================================
WITH period_data AS (
    SELECT
        SUM(CASE WHEN account_code LIKE '4%' THEN credit - debit ELSE 0 END) AS revenue,
        SUM(CASE WHEN account_code = '5200'  THEN debit - credit ELSE 0 END) AS cogs,
        SUM(CASE WHEN account_code LIKE '5%'
                  AND account_code != '5200' THEN debit - credit ELSE 0 END) AS sg_and_a
    FROM gl_entries
    WHERE entry_date >= '2026-01-01'
      AND entry_date  < '2026-07-01'
)
SELECT
    ROUND(revenue)                                        AS "매출",
    ROUND(cogs)                                           AS "매출원가",
    ROUND(revenue - cogs)                                 AS "매출총이익",
    ROUND(sg_and_a)                                       AS "판관비",
    ROUND(revenue - cogs - sg_and_a)                      AS "영업이익",
    ROUND((revenue - cogs) / NULLIF(revenue, 0) * 100, 1) AS "매출총이익률(%)",
    ROUND((revenue - cogs - sg_and_a)
          / NULLIF(revenue, 0) * 100, 1)                  AS "영업이익률(%)",
    ROUND(cogs / NULLIF(revenue, 0) * 100, 1)             AS "매출원가율(%)",
    ROUND(sg_and_a / NULLIF(revenue, 0) * 100, 1)         AS "판관비율(%)"
FROM period_data;


-- =============================================================================
-- 쿼리 15. 감사 지원 - 표본 거래 추출 (금액 기준 층화)
-- 용도: 외부 감사 대응 샘플 거래 추출
-- 기준: 1억 이상 전수, 1천만~1억 30%, 1천만 미만 10%
-- =============================================================================
WITH classified AS (
    SELECT
        *,
        debit + credit AS total_amount,
        CASE
            WHEN debit + credit >= 100000000 THEN '전수(1억+)'
            WHEN debit + credit >=  10000000 THEN '30%(1천만~1억)'
            ELSE                                   '10%(1천만미만)'
        END AS tier
    FROM gl_entries
    WHERE entry_date >= '2026-01-01'
      AND entry_date  < '2026-07-01'
),
tier1 AS (
    SELECT *, 1.0 AS sample_weight FROM classified WHERE tier = '전수(1억+)'
),
tier2 AS (
    SELECT *, 0.3 AS sample_weight
    FROM classified
    WHERE tier = '30%(1천만~1억)'
    ORDER BY RANDOM()   -- PostgreSQL random sampling
    LIMIT (SELECT CEIL(COUNT(*) * 0.3)::INT FROM classified WHERE tier = '30%(1천만~1억)')
),
tier3 AS (
    SELECT *, 0.1 AS sample_weight
    FROM classified
    WHERE tier = '10%(1천만미만)'
    ORDER BY RANDOM()
    LIMIT (SELECT CEIL(COUNT(*) * 0.1)::INT FROM classified WHERE tier = '10%(1천만미만)')
)
SELECT
    id              AS "전표ID",
    entry_date      AS "전표일자",
    account_code    AS "계정코드",
    dept_code       AS "부서코드",
    debit           AS "차변",
    credit          AS "대변",
    total_amount    AS "거래금액",
    tier            AS "샘플링층",
    description     AS "적요"
FROM (
    SELECT * FROM tier1
    UNION ALL SELECT * FROM tier2
    UNION ALL SELECT * FROM tier3
) sample
ORDER BY tier, entry_date, total_amount DESC;

-- =============================================================================
-- 검증 쿼리: 시산표 대차 일치 확인
-- 실행 후 diff 컬럼이 0이어야 함
-- =============================================================================
SELECT
    SUM(debit)                    AS "차변합계",
    SUM(credit)                   AS "대변합계",
    SUM(debit) - SUM(credit)      AS "차이(0이어야함)"
FROM gl_entries
WHERE entry_date >= '2026-01-01'
  AND entry_date  < '2026-07-01';

-- =============================================================================
-- [끝] finance-sql-queries.sql
-- 추가 프롬프트: prompts.md P-18~P-25 참조
-- =============================================================================
