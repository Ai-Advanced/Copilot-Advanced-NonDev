# 데이터 분析가용 Copilot 프롬프트 치트시트

**Azure 확장:** [직군별 웹 변환 프롬프트](../09-azure-capstone/roles.md) · [계획·배포·재배포 프롬프트](../09-azure-capstone/README.md).

> 복사해서 바로 쓸 수 있는 프롬프트 60개+.
> `[대괄호]` 부분만 상황에 맞게 교체하세요.
> 분析 단계별로 구성: 탐색 → 정제 → 집계 → 시각화 → 스토리텔링

---

## 1단계. 데이터 탐색 (Exploration)

### P01. 테이블 스키마 파악 + 기초 통계

```
다음 테이블 [테이블명]의 데이터 품질을 파악하는 SQL을 PostgreSQL로 작성해줘.
포함 항목:
- 전체 행 수
- 각 컬럼별 NULL 개수와 NULL 비율 (%)
- 숫자형 컬럼의 MIN / MAX / AVG / STDDEV
- 날짜형 컬럼의 최솟값 / 최댓값 / 기간(일수)

테이블 스키마:
[컬럼명: 타입 목록 붙여넣기]
```

### P02. 중복 행 탐지

```
[테이블명] 테이블에서 중복 행을 탐지하는 SQL 작성 (PostgreSQL).
중복 기준 컬럼: [user_id, event_date 등]
결과: 중복 키 값, 중복 횟수, 전체 중복 건수 요약
```

### P03. 날짜 범위와 데이터 갭 확인

```
[events 테이블]의 event_date 기준으로
2024-01-01부터 오늘까지 날짜별 행 수를 보여주는 SQL 작성 (PostgreSQL).
데이터가 0인 날짜도 포함 (generate_series 활용).
목적: 데이터 수집 누락 날짜 탐지
```

### P04. 카디널리티 파악

```
[테이블명]의 각 VARCHAR/TEXT 컬럼에 대해
고유값 개수(cardinality)와 상위 10개 값 + 각 빈도를 보여주는 SQL 작성.
컬럼 목록: [컬럼1, 컬럼2, 컬럼3]
```

### P05. 신규 vs 기존 사용자 비율 시계열

```
PostgreSQL.
[events] 테이블 기준 월별로:
- 해당 월에 처음 등장한 user_id (신규 사용자)
- 이전 달에도 있던 user_id (기존 사용자)
의 비율을 구하는 SQL.
MIN(event_date) per user_id 활용.
```

### P06. 퍼널 전환 탐색

```
사용자가 다음 퍼널 단계를 거치는지 탐색하는 SQL (PostgreSQL).

[events] 테이블, event_name 컬럼 기준.
퍼널 단계:
1. [page_view]
2. [signup_start]
3. [signup_complete]
4. [first_purchase]

각 단계 도달 user_id 수와 이전 단계 대비 전환율(%) 출력.
```

### P07. 이상치 빠른 탐지

```
[payments] 테이블의 amount 컬럼에서 이상치를 탐지하는 SQL (PostgreSQL).
IQR 방식 사용: Q1 - 1.5*IQR 미만 또는 Q3 + 1.5*IQR 초과.
이상치 행 수, 이상치 비율(%), 이상치 샘플 5개 출력.
```

### P08. 사용자 세그먼트 분포

```
[users] 테이블에서 다음 기준 교차 분포를 구하는 SQL (PostgreSQL):
- plan (basic / pro / enterprise)
- country (상위 5개국 + 기타)
- channel (유입 채널)

각 조합의 사용자 수, 전체 대비 비율(%) 출력.
```

---

## 2단계. 데이터 정제 (Cleaning)

### P09. 결측치 채우기 (SQL)

```
[테이블명]에서 [컬럼명]이 NULL인 경우를 처리하는 SQL (PostgreSQL).
처리 방식:
- 숫자형: 해당 [그룹 컬럼] 기준 중앙값으로 채우기
- 문자형: 'unknown'으로 채우기
- 날짜형: 앞 행의 날짜로 채우기 (LAG 활용)

UPDATE 쿼리 또는 SELECT COALESCE 쿼리 모두 작성.
```

### P10. 문자열 정제 (SQL)

```
[users] 테이블의 [email] 컬럼을 정제하는 SQL (PostgreSQL):
1. 앞뒤 공백 제거 (TRIM)
2. 소문자 통일 (LOWER)
3. '@' 없는 잘못된 이메일 탐지
4. 도메인만 추출 (SPLIT_PART 활용)

SELECT 쿼리로 정제 결과 미리보기 형태로.
```

### P11. 중복 제거 (SQL)

```
[subscriptions] 테이블에서 동일 [user_id + event_date + event_type] 조합의
중복 행을 제거하는 SQL (PostgreSQL).
보존 기준: subscription_id가 가장 큰 행 (최신 행) 유지.
CTE + ROW_NUMBER() OVER(PARTITION BY ... ORDER BY ...) 방식 사용.
```

### P12. 타입 변환 및 날짜 파싱 (SQL)

```
[raw_events] 테이블의 [event_timestamp] 컬럼이 VARCHAR '2024-03-15 14:30:00' 형식이야.
PostgreSQL에서:
1. TIMESTAMP로 변환
2. 날짜/시간/요일/주차 각각 추출하는 SELECT 쿼리
3. 변환 실패(잘못된 형식) 행을 탐지하는 쿼리
```

### P13. 데이터 정제 (pandas)

```python
# 아래 CSV 파일을 pandas로 정제하는 Python 코드 작성.
# 파일: [raw_data.csv]
# 컬럼: [user_id, email, signup_date, plan, amount]
#
# 정제 항목:
# 1. 헤더 소문자 통일 + 공백을 언더스코어로
# 2. signup_date를 datetime 타입으로 변환 (형식: YYYY-MM-DD)
# 3. amount의 쉼표·원화기호 제거 후 float 변환
# 4. 결측치 행 수 출력 (컬럼별)
# 5. 중복 user_id 제거 (최신 signup_date 기준 유지)
# 6. 정제 완료 데이터를 clean_data.csv로 저장
#
# pandas, SettingWithCopyWarning 회피 (.copy() 사용)
```

### P14. 이상치 처리 (pandas)

```python
# [df] DataFrame의 [amount] 컬럼 이상치를 처리하는 pandas 코드.
# 방법: IQR 방식
# 이상치 행을 제거하지 말고 플래그(is_outlier 컬럼 True/False)로 표시.
# 이상치 통계(개수, 비율, 최솟값, 최댓값) 출력.
# SettingWithCopyWarning 없이 작성.
```

### P15. 스키마 유효성 검증 (pandas)

```python
# [df] DataFrame의 스키마를 검증하는 함수 validate_schema(df) 작성.
# 검증 항목:
# - 필수 컬럼 존재 여부: [user_id, signup_date, plan, amount]
# - 각 컬럼 타입 확인 (예: user_id는 int64, signup_date는 datetime64)
# - plan 컬럼 허용값: ['basic', 'pro', 'enterprise']
# - amount는 0 이상
# 검증 실패 시 어떤 항목이 왜 실패했는지 상세 메시지 출력.
```

---

## 3단계. 집계 및 분析 (Aggregation & Analysis)

### P16. 월별 지표 집계

```
PostgreSQL. [subscriptions] 테이블 기준 월별 집계 SQL.
결과 컬럼:
- year_month (YYYY-MM 형식)
- new_subscribers (신규 구독)
- churned (해지)
- upgraded (업그레이드)
- downgraded (다운그레이드)
- net_new (신규 - 해지)
- ending_mrr (해당 월 마지막 날 기준 MRR 합계)
정렬: year_month ASC
```

### P17. 코호트 리텐션 분析

```
PostgreSQL. 월별 코호트 리텐션 분析 SQL.

테이블: [subscriptions(user_id, event_type, event_date)]
코호트 정의: 사용자의 첫 'subscribe' 이벤트가 있는 월
리텐션 정의: 코호트 월 이후 N개월째에도 'subscribe' 이벤트(취소 아닌)가 있는지

결과 형태:
cohort_month | month_0 | month_1 | month_2 | month_3 | ...
(각 셀: 해당 코호트에서 살아있는 비율 %)

WITH 절 + DATE_TRUNC 활용.
```

### P18. 퍼널 전환율 分析

```
PostgreSQL. 사용자 퍼널 전환율 분析 SQL.
테이블: [events(user_id, event_name, event_date)]

퍼널 단계 (순서대로 모두 거쳐야 전환으로 간주):
1. 'landing_view'
2. 'signup_start'
3. 'signup_complete'
4. 'trial_start'
5. 'subscription_start'

기간: [2024-01-01] ~ [2024-03-31]
결과: 각 단계 도달 수, 직전 단계 대비 전환율, 1단계 대비 누적 전환율
```

### P19. RFM 세그먼테이션

```
PostgreSQL. 구독 서비스 RFM 분析 SQL.
테이블: [payments(user_id, amount, paid_at)]
기준일: CURRENT_DATE

- R (Recency): 마지막 결제일로부터 현재까지 일수
- F (Frequency): 총 결제 횟수
- M (Monetary): 총 결제 금액

각 지표를 NTILE(5)로 1~5점 스코어링.
RFM 합산 점수로 세그먼트 분류:
- Champions (13~15점)
- Loyal (10~12점)
- At Risk (6~9점)
- Lost (3~5점)

세그먼트별 사용자 수, 평균 금액, 평균 빈도 출력.
```

### P20. 세션 붙이기 (LAG/LEAD)

```
PostgreSQL. [events] 테이블로 세션을 정의하는 SQL.
세션 기준: 동일 user_id 기준으로 이전 이벤트와 30분 이상 간격이 있으면 새 세션.

LAG() OVER(PARTITION BY user_id ORDER BY event_date) 활용.
결과: 각 이벤트에 session_number 부여 (유저별 1, 2, 3...).
추가: 세션별 이벤트 수, 세션 시작 시각, 세션 지속 시간(분) 집계.
```

### P21. LTV (생애 가치) 계산

```
PostgreSQL. 사용자 LTV를 계산하는 SQL.
테이블: [payments(user_id, amount, paid_at)], [users(user_id, signup_date, plan)]

LTV = 사용자별 총 결제 금액
ARPU = LTV / 사용자 수
plan별 평균 LTV, 중앙값 LTV, 상위 10% 사용자의 LTV 기여 비율 출력.
추가: 가입 후 3개월 / 6개월 / 12개월 누적 LTV 코호트도.
```

### P22. A/B 테스트 결과 집계

```
PostgreSQL. A/B 테스트 결과 집계 SQL.
테이블: [ab_assignments(user_id, variant, assigned_at)], [events(user_id, event_name, event_date)]

목표 지표: event_name = 'subscription_start' 전환율
기간: 테스트 시작일로부터 14일

결과:
- variant별 노출 수, 전환 수, 전환율
- 전환율 차이(%)
- 각 variant의 95% 신뢰구간 (Wilson score interval 공식 사용)
```

### P23. 이탈 예측 신호 分析

```
PostgreSQL. 이탈 전 행동 패턴을 분析하는 SQL.
테이블: [subscriptions], [events]

이탈 정의: event_type = 'cancel'
이탈 30일 전 사용자의 이벤트 패턴 vs 유지 사용자 패턴 비교:
- 평균 로그인 횟수
- 주요 기능 사용 이벤트 빈도 (event_name별)
- 마지막 로그인으로부터의 평균 경과 일수

이탈 그룹 vs 유지 그룹 각각 집계 후 나란히 비교.
```

### P24. MRR 분해 (MRR Breakdown)

```
PostgreSQL. 월별 MRR 변동을 분해하는 SQL (MRR Waterfall).
테이블: [subscriptions(user_id, event_type, plan, event_date, mrr)]

event_type별 MRR 기여:
- New MRR (신규 subscribe)
- Expansion MRR (upgrade)
- Contraction MRR (downgrade)
- Churn MRR (cancel)
- Net New MRR = New + Expansion - Contraction - Churn

월별 각 구성요소 집계 + 전월 대비 변화율(%).
```

### P25. 사용자별 첫 행동까지의 시간 (TTA)

```
PostgreSQL. 가입 후 첫 핵심 행동까지 걸린 시간(Time to Action) 분析.
테이블: [users(user_id, signup_date)], [events(user_id, event_name, event_date)]

핵심 행동: event_name = '[first_feature_use]'
측정: 가입일로부터 첫 핵심 행동까지의 일수

결과:
- 중앙값, 평균, 25/75 퍼센타일
- 1일/3일/7일/14일/30일 내 달성 비율
- plan별, channel별 분해
```

### P26. 워크데이 vs 주말 패턴

```
PostgreSQL. 사용 이벤트의 요일별 / 시간대별 패턴 분析 SQL.
테이블: [events(user_id, event_name, event_date_time TIMESTAMP)]

결과:
- 요일별(0=일요일~6=토요일) 이벤트 수
- 시간대별(0~23시) 이벤트 수
- 워크데이 vs 주말 이벤트 비율

EXTRACT(DOW FROM ...), EXTRACT(HOUR FROM ...) 활용.
```

---

## 4단계. 시각화 (Visualization)

### P27. 리텐션 히트맵

```python
# 코호트 리텐션 히트맵을 그리는 Python 코드.
# 입력: retention_df (행=코호트 월, 열=Month 0/1/2/..., 값=리텐션 비율 0~1)
#
# seaborn.heatmap 사용.
# - 색상: 초록색 계열 (높을수록 진하게)
# - 셀 안에 퍼센트 값 표시 (fmt='.0%')
# - 타이틀: "월별 코호트 리텐션 히트맵"
# - 그림 크기: (14, 8)
# - x축: "가입 후 N개월", y축: "가입 코호트"
```

### P28. 퍼널 차트

```python
# 퍼널 전환율 막대 차트를 그리는 Python 코드.
# 입력: funnel_df (컬럼: stage, users, conversion_rate)
#
# plotly.graph_objects 사용 (인터랙티브).
# - 수평 막대 차트 (각 단계별 사용자 수)
# - 각 막대 옆에 전환율(%) 레이블 표시
# - 색상: 단계마다 점점 연해지는 파란색
# - 타이틀: "가입 퍼널 분析"
```

### P29. MRR 트렌드 (스택 에어리어)

```python
# MRR 분해를 스택 에어리어 차트로 그리는 Python 코드.
# 입력: mrr_df (컬럼: year_month, new_mrr, expansion_mrr, contraction_mrr, churn_mrr)
#
# plotly.express 사용.
# - 양수(new, expansion)는 위로, 음수(contraction, churn)는 아래로
# - 색상: green=new, blue=expansion, orange=contraction, red=churn
# - 범례, 호버 툴팁 포함
```

### P30. 분포 비교 (바이올린 + 박스플롯)

```python
# 두 그룹(A/B variant)의 [amount] 분포를 비교하는 시각화.
# 입력: df (컬럼: variant, amount)
#
# seaborn.violinplot + boxplot 오버레이.
# - inner='box' 옵션으로 박스플롯 안에 표시
# - 각 그룹의 중앙값을 점선으로 표시
# - 타이틀: "A/B 테스트 결제 금액 분포 비교"
```

### P31. 상관 행렬 히트맵

```python
# 수치형 컬럼들의 상관관계를 히트맵으로 시각화.
# 입력: df (여러 수치형 컬럼)
#
# seaborn.heatmap 사용.
# - 상관계수 값을 셀 안에 표시 (소수점 2자리)
# - 대각선 마스킹 (mask=np.triu 또는 np.tril)
# - 색상: RdBu_r (빨강=양의 상관, 파랑=음의 상관)
# - annot=True, fmt='.2f'
```

### P32. 시계열 이상치 탐지 시각화

```python
# 시계열 데이터에서 이상치를 시각화하는 코드.
# 입력: ts_df (컬럼: date, value)
#
# matplotlib 사용.
# - 메인 라인 차트
# - 7일 이동 평균선 오버레이 (rolling(7).mean())
# - 이상치(mean ± 2*std 초과) 점을 빨간 점으로 강조
# - 이상치 날짜에 수직선 + 값 레이블
```

### P33. RFM 산점도

```python
# RFM 세그먼트를 3D 또는 2D 산점도로 시각화.
# 입력: rfm_df (컬럼: user_id, recency, frequency, monetary, segment)
#
# plotly.express.scatter 사용.
# - x=recency, y=monetary, size=frequency, color=segment
# - 호버: user_id, 각 RFM 점수
# - 세그먼트별 색상: Champions=금, Loyal=초록, At Risk=주황, Lost=빨강
```

### P34. KPI 요약 카드 (텍스트 차트)

```python
# KPI 요약을 시각적으로 표현하는 matplotlib 코드.
# 표시할 KPI:
# - 이번 달 신규 가입자 수 (vs 전월 +/- %)
# - MRR (vs 전월)
# - 30일 리텐션율 (vs 전월)
# - 이탈률 (vs 전월)
#
# 2x2 서브플롯. 각 칸에 큰 숫자 + 작은 변화율.
# 전월 대비 상승은 초록, 하락은 빨강 (이탈률은 반대).
```

---

## 5단계. 스토리텔링 (Storytelling)

### P35. 인사이트 문장 자동화

```
다음 데이터 분析 결과를 바탕으로 임원 보고용 인사이트 3문장을 한국어로 작성해줘.

분析 결과:
- 3월 신규 가입자: 31,240명 (전월 대비 +12%)
- 3월 이탈률: 8.3% (전월 7.1%에서 악화)
- Pro 플랜 전환율: 23.4% (목표 25% 미달)
- 30일 리텐션: 62% (업계 평균 58%)

형식:
1. 가장 긍정적인 신호 1문장
2. 가장 주의가 필요한 신호 1문장
3. 추천 액션 1문장

톤: 사실 기반, 애매한 표현 금지, 수치 반드시 포함
```

### P36. 대시보드 인사이트 요약

```
다음 대시보드 수치를 보고 주간 분析 요약 슬랙 메시지(3~5문장)를 작성해줘.

기간: 2024년 3월 4주차 (3/25~3/31)

주요 지표:
[수치 목록 붙여넣기]

형식:
- 첫 문장: 이번 주 가장 주목할 숫자 1개
- 중간: 원인 가설 1~2개 (단, "것으로 보입니다" 같은 모호한 표현 금지)
- 마지막 문장: 다음 주 모니터링 포인트

채널: 슬랙, 길이: 300자 이내
```

### P37. 지표 정의서 작성

```
다음 지표의 공식 정의서를 작성해줘.

지표명: [30일 리텐션율]

포함 항목:
1. 지표 정의 (한 문장)
2. 계산 공식 (분자 / 분모 명확히)
3. 측정 단위
4. 측정 기준일/기간
5. 데이터 소스 (테이블명, 컬럼명)
6. 경계 조건 (예외 처리)
7. 관련 지표
8. 목표값 (있는 경우)

형식: Markdown 표 또는 구조화된 글머리
```

### P38. A/B 테스트 결과 보고서

```
다음 A/B 테스트 결과를 이해관계자용 보고서로 요약해줘.

테스트명: [신규 가입 온보딩 플로우 개선]
기간: 14일, 표본 크기: A그룹 12,340명 / B그룹 12,289명

결과:
- A그룹 전환율: 18.3%
- B그룹 전환율: 21.7%
- p-value: 0.023
- 신뢰구간 95%: [+1.8%, +5.6%]

작성 지침:
- 통계적 유의성을 비전문가도 이해할 수 있게 설명
- 비즈니스 임팩트(예상 MRR 증가)도 포함
- 다음 단계(rollout 또는 추가 테스트) 권고
- 길이: 5~7문장
```

### P39. 이탈 분析 경영진 브리핑

```
다음 이탈 분析 결과를 경영진 브리핑용 요약으로 작성해줘.

분析 기간: 2024년 Q1
이탈 데이터:
- 전체 이탈률: 9.2% (전 분기 대비 +1.4%p)
- 이탈 집중 세그먼트: basic 플랜 가입 후 30일 이내 (전체 이탈의 43%)
- 이탈 전 공통 행동: 마지막 30일간 로그인 2회 미만
- 이탈 유저 중 65%가 이탈 7일 전 고객센터 문의 없음

형식: 경영진 브리핑 (원인 / 임팩트 / 권고 액션 3가지)
```

### P40. 리포트 섹션 구조 생성

```
"[2024년 3월 월간 사용자 리포트]" 문서 구조를 Markdown으로 작성해줘.

독자: 제품팀 리드, COO
분析 내용: 신규 가입, 리텐션, 이탈, MRR, 퍼널

각 섹션에 포함 요소:
- 핵심 수치 (표)
- 전월 대비 변화 (화살표 표기)
- 인사이트 1~2문장
- 액션 포인트

총 길이: A4 3~4페이지 분량 목차
```

---

## 6단계. SQL 최적화 및 디버깅

### P41. 느린 쿼리 개선

```
다음 SQL 쿼리가 느립니다. PostgreSQL 기준으로 최적화 방안을 제안해줘.

[느린 쿼리 붙여넣기]

테이블 크기: [orders 5억 행, users 200만 행]
현재 실행 시간: [약 45초]

분析 관점:
1. 서브쿼리를 CTE 또는 JOIN으로 개선 가능한지
2. GROUP BY / ORDER BY 최적화
3. 인덱스 추가 권고 (어떤 컬럼에, 왜)
4. EXPLAIN 결과를 어떻게 읽어야 하는지 설명
```

### P42. CTE 리팩토링

```
다음 중첩 서브쿼리를 CTE(WITH 절)로 리팩토링해줘.
가독성과 유지보수성 중심. 각 CTE에 한국어 주석으로 역할 설명 추가.

[원본 쿼리 붙여넣기]
```

### P43. BigQuery / Snowflake 방언 변환

```
다음 PostgreSQL 쿼리를 [BigQuery / Snowflake] 문법으로 변환해줘.

주요 변환 포인트:
- DATE_TRUNC 함수 차이
- GENERATE_SERIES 대체 (BigQuery: UNNEST(GENERATE_DATE_ARRAY))
- ILIKE 대체 (Snowflake는 지원, BigQuery는 LOWER() 사용)
- LIMIT vs TOP

[원본 PostgreSQL 쿼리]
```

### P44. SQL 설명 요청

```
다음 SQL 쿼리를 비개발자도 이해할 수 있게 한국어로 설명해줘.

설명 방식:
1. 이 쿼리가 "무엇을 구하는지" 한 문장으로
2. 각 절(WITH, SELECT, FROM, WHERE, GROUP BY, HAVING, ORDER BY)이 하는 역할
3. 결과가 어떤 형태(행/열 구조)인지

[쿼리 붙여넣기]
```

### P45. Window Function 설명 + 변형

```
다음 쿼리의 Window Function 부분을 설명하고, 3가지 변형 버전을 만들어줘.

원본:
ROW_NUMBER() OVER(PARTITION BY user_id ORDER BY event_date DESC)

변형 요청:
1. 첫 번째 이벤트만 남기기 (ROW_NUMBER 대신 FIRST_VALUE)
2. 이전 이벤트 날짜와의 간격(일수) 계산 (LAG 활용)
3. 각 유저 내 이벤트를 날짜 순으로 백분위(PERCENT_RANK) 부여
```

---

## 7단계. pandas / Python 분析

### P46. groupby 집계

```python
# [df] DataFrame을 [plan, country] 두 컬럼으로 groupby 후
# amount의 합계, 평균, 중앙값, 건수를 집계하는 pandas 코드.
# 결과를 MultiIndex 펼쳐서 평탄화(reset_index).
# 컬럼명: plan, country, amount_sum, amount_mean, amount_median, count
```

### P47. 피벗 테이블 + 결측치 처리

```python
# [df] DataFrame으로 피벗 테이블 생성:
# - 행: year_month
# - 열: plan
# - 값: user_id 고유 수 (nunique)
# - 결측치는 0으로 채우기
# - 각 행의 합계 열(Total) 추가
# pandas.pivot_table 활용.
```

### P48. 시계열 리샘플링

```python
# [df] DataFrame (컬럼: date, value, user_id)을
# 주별(W) / 월별(M) 리샘플링 후 집계하는 pandas 코드.
# 날짜를 index로 설정 후 resample 사용.
# 결과: 주별 합계, 월별 이동 평균(4주)
# 빈 기간은 0으로 채우기 (fillna(0))
```

### P49. 두 DataFrame merge

```python
# [users_df]와 [payments_df]를 user_id 기준으로 LEFT JOIN.
# payments_df에 없는 user는 결제 관련 컬럼을 0으로 채우기.
# 조인 후 중복 컬럼(_x, _y)를 정리하는 코드 포함.
# 조인 전후 행 수를 출력해서 데이터 손실 여부 확인.
```

### P50. apply + 사용자 정의 함수

```python
# [df]의 [plan] 컬럼 값에 따라 monthly_price를 반환하는 함수 get_price(plan) 작성.
# basic=9.99, pro=19.99, enterprise=49.99, 그 외는 NaN.
# df['monthly_price'] = df['plan'].apply(get_price) 형태로 적용.
# SettingWithCopyWarning 없이 작성.
```

### P51. 결측치 패턴 분析

```python
# [df] DataFrame의 결측치 패턴을 분析하는 코드.
# 1. 컬럼별 결측치 수, 비율(%) 출력
# 2. 결측치가 2개 이상인 행 수 출력
# 3. 결측치 패턴 시각화 (missingno 라이브러리 또는 seaborn heatmap으로 대체)
# missingno 없으면 seaborn으로 대체 방법도 제시.
```

### P52. 빠른 EDA 리포트

```python
# [df] DataFrame의 빠른 EDA 리포트를 출력하는 함수 quick_eda(df) 작성.
# 출력:
# 1. shape (행, 열)
# 2. dtypes 요약
# 3. 수치형 컬럼 describe()
# 4. 범주형 컬럼별 top5 값
# 5. 결측치 요약
# 6. 중복 행 수
# 라이브러리: pandas만 사용 (ydata-profiling 없이)
```

---

## 8단계. 대시보드 스펙 & 자동화

### P53. Tableau/Looker 대시보드 스펙 작성

```
다음 대시보드의 스펙 문서를 Markdown으로 작성해줘.

대시보드명: [구독 서비스 운영 현황 대시보드]
사용 도구: [Tableau / Looker / Metabase 중 택1]
주요 사용자: [제품팀, 경영진]

포함할 차트 (각각 아래 항목 포함):
1. KPI 카드 4개 (신규 가입, MRR, 리텐션, 이탈률)
2. MRR 트렌드 (12개월)
3. 코호트 리텐션 히트맵

각 차트 항목:
- 차트 유형
- 데이터 소스 (테이블명, 필요 컬럼)
- 집계 방식
- 필터 조건
- 업데이트 주기
```

### P54. 지표 정의서 일괄 작성

```
다음 6개 지표에 대한 공식 정의서를 테이블 형식으로 한 번에 작성해줘.

지표: MRR, ARR, 이탈률(Churn Rate), NRR(Net Revenue Retention), LTV, CAC

각 지표별 컬럼:
| 지표명 | 정의 | 계산 공식 | 단위 | 측정 주기 | 데이터 소스 |
```

### P55. 반복 실행 스크립트

```python
# 매일 아침 자동 실행되는 분析 스크립트 작성.
# 기능:
# 1. [data/] 폴더에서 가장 최신 CSV 파일 자동 로드
# 2. 전날 데이터 기준 KPI 4개 계산
# 3. 결과를 [reports/YYYYMMDD_daily_kpi.csv]로 저장
# 4. 이상값(전일 대비 ±30% 초과) 발생 시 콘솔 경고 출력
# 실행 방법 주석 포함. 외부 라이브러리: pandas, datetime만 사용.
```

### P56. Jupyter Notebook 셀 구조

```python
# 월간 사용자 리포트용 Jupyter Notebook 구조를 만들어줘.
#
# 셀 구조:
# 1. [마크다운] 리포트 제목 + 작성일 + 분析 기간
# 2. [코드] import + 설정
# 3. [코드] 데이터 로드 + 기초 검증
# 4. [마크다운] ## 1. 신규 가입 분析
# 5. [코드] 신규 가입 집계 + 차트
# 6. [마크다운] ## 2. 리텐션 분析
# 7. [코드] 리텐션 계산 + 히트맵
# (이하 패턴 반복)
#
# 각 셀의 첫 줄에 # %%[셀 목적] 주석 추가.
```

---

## 9단계. 통계 분析

### P57. t-테스트 (A/B 비교)

```python
# A/B 테스트의 전환율 차이가 통계적으로 유의한지 검정하는 코드.
# 입력:
# - control: 대조군 전환 여부 (0/1 배열 또는 Series)
# - treatment: 실험군 전환 여부 (0/1 배열 또는 Series)
#
# scipy.stats.ttest_ind (또는 proportions_ztest) 사용.
# 출력:
# - 각 그룹 전환율
# - t-통계량, p-value
# - 95% 신뢰구간 (차이의 구간)
# - 결론: 유의 여부 (p < 0.05 기준) + 한국어 해석
```

### P58. 카이제곱 검정

```python
# 두 범주형 변수 간 독립성을 검정하는 카이제곱 검정 코드.
# 예: plan 종류 × 이탈 여부 간 관계
#
# 입력: df (컬럼: plan, churned)
# scipy.stats.chi2_contingency 사용.
# 출력:
# - 교차표 (pd.crosstab, normalize='index'로 비율도)
# - 카이제곱 통계량, p-value, 자유도
# - 기대 빈도 행렬
# - 결론 (한국어 해석)
```

### P59. 신뢰구간 계산

```python
# 비율(전환율, 리텐션율 등)의 95% 신뢰구간을 계산하는 함수 작성.
# Wilson score interval 방식 (소표본에서도 안정적).
# 입력: successes (성공 수), n (전체 수), confidence=0.95
# 출력: (lower, upper, point_estimate) 튜플
# 사용 예: 전환율 21.7%, n=12,289일 때 95% CI 계산
```

### P60. 상관 분析 + 유의성

```python
# [df]의 수치형 컬럼들 간 상관계수와 p-value를 한 번에 계산하는 코드.
# scipy.stats.pearsonr 또는 pingouin 라이브러리 활용.
# 결과: 상관계수 행렬 + p-value 행렬
# 유의하지 않은 상관(p > 0.05)은 NaN으로 마스킹한 히트맵 시각화.
```

---

## 빠른 참조: 프롬프트 유형별 키워드

| 상황 | 핵심 키워드 |
|------|-----------|
| SQL 기초 집계 | `GROUP BY`, `집계`, `월별`, `TOP N`, `PostgreSQL` |
| Window Function | `ROW_NUMBER`, `LAG`, `LEAD`, `RANK`, `PARTITION BY` |
| 코호트 分析 | `코호트`, `리텐션`, `DATE_TRUNC`, `첫 이벤트 월` |
| 퍼널 | `퍼널`, `전환율`, `단계별`, `도달 사용자 수` |
| 데이터 클리닝 | `결측치`, `중복 제거`, `타입 변환`, `SettingWithCopyWarning` |
| 시각화 | `seaborn`, `plotly`, `히트맵`, `차트 타이틀`, `그림 크기` |
| 인사이트 문장 | `수치 반드시 포함`, `애매한 표현 금지`, `임원 보고용` |
| 통계 | `p-value`, `신뢰구간`, `t-test`, `카이제곱` |

---

## Copilot이 자주 틀리는 유형 (검증 포인트)

| 유형 | Copilot 실수 | 확인 방법 |
|------|------------|---------|
| **JOIN 방향** | LEFT JOIN 대신 INNER JOIN으로 행이 누락됨 | 조인 전후 행 수 비교 |
| **GROUP BY 누락** | SELECT에 집계하지 않는 컬럼이 있는데 GROUP BY에 빠짐 | 실행 오류 또는 DISTINCT 확인 |
| **날짜 타입 혼용** | VARCHAR 날짜 컬럼을 그대로 비교 (문자열 정렬) | CAST/TO_DATE 추가 |
| **코호트 기준** | 코호트 월을 이벤트 월이 아닌 현재 월로 잘못 정의 | MIN(event_date) 기준인지 확인 |
| **SettingWithCopyWarning** | df 슬라이싱 후 직접 대입 | `.copy()` 추가 여부 확인 |
| **pandas 집계 컬럼명** | groupby 후 컬럼명이 MultiIndex로 남음 | `reset_index()` + 컬럼명 재정의 |
| **NULL 처리** | COUNT(*)와 COUNT(컬럼)의 NULL 포함 여부 차이 | NULL 포함 여부 명시 요청 |
| **방언 차이** | PostgreSQL 쿼리를 BigQuery에서 오류 | 방언 명시 후 재생성 요청 |
