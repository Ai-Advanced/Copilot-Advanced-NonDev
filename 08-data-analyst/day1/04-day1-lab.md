# 04. Day 1 종합 실습 — "월간 사용자 리포트"

## 실습 개요

Day 1에서 배운 3가지(Copilot 활용 개요 / SQL 심화 / 데이터 클리닝)를 하나의 흐름으로 연결합니다.
실제 분析가가 매달 반복하는 작업: **원본 데이터 오디팅 → SQL로 지표 집계 → 리포트 초안 작성**을 엔드투엔드로 수행합니다.

**시나리오**: 구독 서비스 Zeta의 2024년 3월 월간 사용자 리포트 작성

**완성 결과물**:
1. 데이터 오디팅 보고서 (SQL 결과 요약)
2. 핵심 지표 SQL 3개 (신규 가입 / 리텐션 / 이탈)
3. 임원 보고용 인사이트 문단 초안

**예상 소요**: 60분

---

## 실습 데이터

실제 DB 없이 가상 SQL 결과값을 활용합니다.
SQLTools로 연결된 DB가 있다면 직접 실행하세요.

### 가상 스키마 (Zeta 서비스)

```sql
-- 전 챕터와 동일한 스키마
users          (user_id, signup_date, plan, country, channel, age_group)
subscriptions  (subscription_id, user_id, event_type, plan, event_date, mrr)
events         (event_id, user_id, event_name, event_date, session_id)
payments       (payment_id, user_id, amount, status, paid_at)
```

---

## Step 1. 데이터 오디팅 (15분)

분析 시작 전 반드시 수행하는 데이터 품질 확인.

### 1-1. 오디팅 SQL 생성 (Copilot 활용)

**VS Code Chat 사이드바에서:**

```
PostgreSQL. 다음 4개 테이블의 데이터 품질 오디팅 SQL을 한 번에 작성해줘.

테이블:
- users(user_id, signup_date, plan, country, channel, age_group)
- subscriptions(subscription_id, user_id, event_type, plan, event_date, mrr)
- events(event_id, user_id, event_name, event_date, session_id)
- payments(payment_id, user_id, amount, status, paid_at)

각 테이블에 대해:
1. 전체 행 수
2. 주요 컬럼 NULL 비율 (%)
3. 날짜 컬럼 범위 (MIN ~ MAX)
4. 숫자 컬럼 기초 통계 (MIN/MAX/AVG)

추가: subscriptions의 event_type 고유값 목록, payments의 status 고유값 목록
```

### 1-2. 오디팅 결과 해석

오디팅 SQL을 실행하면 아래와 같은 결과를 가정합니다 (가상 값):

| 테이블 | 총 행 수 | 주요 이슈 |
|--------|---------|---------|
| users | 487,231 | country NULL 2.3% |
| subscriptions | 1,243,890 | mrr NULL 0.8% (해지된 구독) |
| events | 8,732,445 | event_name NULL 0.1% |
| payments | 943,221 | amount 음수 12건 (환불) |

### 1-3. 이슈 정리 및 처리 결정

```markdown
## 데이터 오디팅 결과 메모 (2024년 3월 리포트용)

| 이슈 | 영향 | 처리 방법 |
|------|------|---------|
| users.country NULL 2.3% | 국가별 분析에서 일부 제외 | 'unknown'으로 대체 |
| subscriptions.mrr NULL | 해지 시점 MRR 없음 | 해지 계산에서 제외 처리 |
| payments.amount 음수 12건 | 환불 처리된 것 | status='refunded' 확인 후 제외 |
```

**Copilot으로 처리 SQL 생성**:
```
위 오디팅 결과에서 발견된 이슈를 처리하는 SQL 작성 (PostgreSQL):
1. users.country NULL → 'unknown'으로 채우는 SELECT (UPDATE 아닌 VIEW 형태)
2. subscriptions에서 mrr이 NULL인 행 필터링 조건
3. payments에서 status != 'refunded' 이고 amount < 0인 이상 행 탐지
```

---

## Step 2. 신규 가입 분析 SQL (15분)

### 2-1. 2024년 3월 신규 가입자 집계

**프롬프트**:
```
PostgreSQL. users 테이블(user_id, signup_date, plan, country, channel, age_group) 기준.
2024년 3월(2024-03-01 ~ 2024-03-31) 신규 가입 분析 SQL.

집계 1: 전체 신규 가입자 수 + 전월(2월) 대비 증감 수, 증감률(%)
집계 2: plan별 신규 가입자 수와 비율(%)
집계 3: channel별 신규 가입자 수 (상위 5개 채널)
집계 4: 주차별(1~5주차) 신규 가입자 수 (DATE_TRUNC('week', signup_date) 기준)

모든 집계를 하나의 SQL 파일로. 각 집계는 별도 쿼리 + 설명 주석.
```

**예상 결과 형태**:

```sql
-- ============================================================
-- 2024년 3월 신규 가입 분析
-- ============================================================

-- [집계 1] 전체 신규 가입 + 전월 비교
WITH mar AS (
    SELECT COUNT(*) AS mar_signups
    FROM users
    WHERE signup_date >= '2024-03-01' AND signup_date < '2024-04-01'
),
feb AS (
    SELECT COUNT(*) AS feb_signups
    FROM users
    WHERE signup_date >= '2024-02-01' AND signup_date < '2024-03-01'
)
SELECT
    mar.mar_signups,
    feb.feb_signups,
    mar.mar_signups - feb.feb_signups AS change,
    ROUND((mar.mar_signups - feb.feb_signups)::NUMERIC / feb.feb_signups * 100, 1) AS change_pct
FROM mar, feb;

-- [집계 2] plan별 신규 가입
SELECT
    plan,
    COUNT(*) AS signups,
    ROUND(COUNT(*)::NUMERIC / SUM(COUNT(*)) OVER () * 100, 1) AS pct
FROM users
WHERE signup_date >= '2024-03-01' AND signup_date < '2024-04-01'
GROUP BY plan
ORDER BY signups DESC;
```

### 2-2. 검증 포인트

```sql
-- 전체 합계가 맞는지 확인
SELECT COUNT(*) FROM users
WHERE signup_date >= '2024-03-01' AND signup_date < '2024-04-01';
-- 이 숫자 = plan별 합계의 SUM과 같아야 함

-- 비율 합계가 100%인지 확인
SELECT SUM(pct) FROM (
    SELECT ROUND(COUNT(*)::NUMERIC / SUM(COUNT(*)) OVER () * 100, 1) AS pct
    FROM users
    WHERE signup_date >= '2024-03-01' AND signup_date < '2024-04-01'
    GROUP BY plan
) t;
-- 반올림 오차로 99.9~100.1 범위 허용
```

---

## Step 3. 리텐션 및 이탈 지표 SQL (20분)

### 3-1. 30일 리텐션 집계

**프롬프트**:
```
PostgreSQL. subscriptions(user_id, event_type, event_date) 기준.
2024년 2월 가입자(첫 subscribe 이벤트가 2월인 사용자)의 30일 리텐션 계산.

리텐션 정의: 가입 후 30일 이내(가입일 + 30일)에도 subscribe 상태가 있는 사용자 비율

결과:
- 2월 가입자 코호트 크기
- 30일 이내 리텐션 사용자 수
- 30일 리텐션율(%)
- 전달(1월 가입자의 30일 리텐션)과 비교
```

### 3-2. 이탈 분析 SQL

**프롬프트**:
```
PostgreSQL. subscriptions(user_id, event_type, plan, event_date) 기준.
2024년 3월 이탈 분析 SQL.

이탈 정의: event_type = 'cancel' 이 발생한 사용자

집계 1: 3월 전체 이탈자 수 + 전월 비교
집계 2: 이탈 시점의 plan별 이탈자 수와 비율
집계 3: 이탈 사용자의 구독 기간 분布
  - 구독 기간 = cancel 날짜 - 첫 subscribe 날짜
  - 구간: 0~30일 / 31~90일 / 91~180일 / 181일+

각 집계에 주석.
```

### 3-3. 전환율 집계

**프롬프트**:
```
PostgreSQL. 2024년 3월 플랜 업그레이드 전환율 SQL.
테이블: subscriptions(user_id, event_type, plan, event_date)

basic → pro 업그레이드 전환율:
- 3월에 basic 플랜이었던 사용자 수
- 그 중 3월에 pro로 upgrade한 사용자 수
- 전환율(%)

pro → enterprise 업그레이드 전환율도 같은 방식으로.
```

---

## Step 4. 임원 리포트 초안 작성 (10분)

위 분析 결과(가상 숫자)를 바탕으로 Copilot으로 임원 보고용 인사이트를 생성합니다.

### 4-1. 가상 분析 결과

```
[2024년 3월 분析 결과]

신규 가입:
- 전체: 31,240명 (전월 27,892명, +12.0%)
- plan별: basic 68% / pro 25% / enterprise 7%
- 최다 유입 채널: organic 42%, paid_search 31%, referral 18%

리텐션:
- 30일 리텐션 (2월 코호트): 61.3% (전월 58.7%, +2.6%p)
- 업계 평균: 58%

이탈:
- 3월 이탈자: 4,230명 (전월 3,891명, +8.7%)
- 이탈률: 8.3% (전월 7.1%, +1.2%p 악화)
- 이탈 plan: basic 플랜 71%, pro 22%, enterprise 7%
- 이탈 구독 기간: 0~30일 44% (가장 많음)

전환:
- basic→pro 전환율: 3.2% (목표 4.0%, 미달)
- pro→enterprise 전환율: 1.1% (목표 1.5%, 미달)
```

### 4-2. 인사이트 문장 생성 프롬프트

```
위 2024년 3월 분析 결과를 바탕으로 임원 보고용 리포트 인사이트 섹션 작성.

구조:
1. 헤드라인 (한 문장 요약)
2. 긍정 신호 (2~3가지, 수치 포함)
3. 우려 신호 (2~3가지, 수치 포함)
4. 권고 액션 (2~3가지, 구체적이고 실행 가능한 것)

형식: Markdown, 각 항목은 불릿
톤: 데이터 기반, 수치 반드시 포함, "~것으로 보입니다" 같은 모호한 표현 금지
길이: 250~300자 이내
```

### 4-3. 예상 생성 결과 (참고)

```markdown
## 2024년 3월 사용자 리포트 요약

**헤드라인**: 신규 가입 +12%로 성장 모멘텀 유지, 이탈률 악화와 전환율 미달이 우선 과제.

**긍정 신호**
- 신규 가입 31,240명, 전월 대비 +12%. 유기 유입(42%) 비중이 지불 채널을 압도.
- 30일 리텐션 61.3%, 전월 +2.6%p 개선이며 업계 평균(58%) 상회.
- Enterprise 신규 가입 7% 유지로 고가치 세그먼트 안정.

**우려 신호**
- 이탈률 8.3%, 전월 대비 +1.2%p 악화. 이탈의 44%가 가입 30일 이내 발생.
- basic→pro 전환율 3.2%, 목표(4.0%) 대비 0.8%p 미달.
- 이탈 사용자의 71%가 basic 플랜으로, 초기 온보딩 품질 문제로 보임.

**권고 액션**
- 가입 7~14일 차 사용자 대상 인앱 온보딩 체크포인트 도입 (이탈 44% 집중 기간).
- pro 업그레이드 CTA를 basic 사용자의 고사용 기능 화면에 노출 강화.
- 이탈 7일 전 고객센터 미접촉 사용자 자동 아웃리치 파이럿 검토.
```

### 4-4. 생성 결과 검토 가이드

Copilot이 생성한 인사이트를 보내기 전에 반드시 확인:

- [ ] 모든 수치가 실제 분析 결과와 일치하는가
- [ ] "것으로 보입니다", "추정됩니다" 같은 모호한 표현이 없는가
- [ ] 권고 액션이 분析 결과에서 논리적으로 도출되는가
- [ ] 경쟁사/외부 데이터 출처 없이 사실을 주장하는 내용이 없는가

---

## Day 1 회고

### 내가 만든 것

- [ ] 데이터 오디팅 SQL (4개 테이블)
- [ ] 신규 가입 분析 SQL (4개 집계)
- [ ] 리텐션 30일 SQL
- [ ] 이탈 분析 SQL (3개 집계)
- [ ] 임원 리포트 인사이트 초안

### 시간 비교

| 작업 | Copilot 없이 | Copilot과 함께 |
|------|------------|--------------|
| 오디팅 SQL 4개 | 40분 | 8분 |
| 신규 가입 집계 SQL | 25분 | 6분 |
| 리텐션 + 이탈 SQL | 45분 | 12분 |
| 인사이트 초안 | 20분 | 4분 |
| **합계** | **130분** | **30분** |

### Day 2 예고

내일은 SQL 결과를 pandas로 후처리하고, 시각화 코드를 생성해서 대시보드용 차트 6종을 만들고, 대시보드 스펙 문서를 완성합니다.

---

**Day 2 시작**: [day2/05-pandas-basics.md](../day2/05-pandas-basics.md)
