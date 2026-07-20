# 08. 캡스톤 프로젝트 — "구독 서비스 Zeta 데이터 딥다이브"

## 프로젝트 개요

2일 과정에서 배운 모든 것을 하나의 흐름으로 연결합니다.
실제 분析가가 "이번 분기 이탈이 왜 늘었나"라는 질문을 받았을 때 처음부터 끝까지 수행하는 작업 흐름입니다.

**시나리오**: COO로부터 요청이 왔습니다.
> "Q1(2024년 1~3월) 이탈률이 전 분기 대비 1.5%p 상승했습니다. 원인을 파악하고 대응 방안을 담은 딥다이브 리포트를 이번 주 금요일까지 주세요."

**완성 결과물**:
1. 지표 정의서 (이탈률 포함 6개 지표)
2. 원인 분析 SQL 파이프라인 (5개 쿼리)
3. pandas 후처리 스크립트
4. 대시보드용 시각화 6개
5. 대시보드 스펙 문서 1페이지
6. 임원 리포트 인사이트 (400자 이내)
7. 반복 실행 스크립트

**예상 소요**: 60분

---

## Step 1. 지표 정의 (10분)

딥다이브를 시작하기 전에 "이탈률"을 명확하게 정의합니다.
팀마다 다르게 쓰는 지표가 리포트를 혼란스럽게 만드는 원인입니다.

### Copilot 프롬프트

```
구독 서비스 "Zeta" 딥다이브 리포트에 사용할 지표 정의서를 Markdown 표로 작성해줘.

지표 목록: 이탈률, MRR, 30일 리텐션, NRR, LTV, basic→pro 전환율

각 지표 컬럼:
| 지표명 | 영문명 | 계산 공식 | 단위 | 분모/분자 명확히 | 경계 조건 | 데이터 소스 |

이탈률 경계 조건 예시:
- 비자발적 해지(결제 실패 후 30일 미납)는 포함/제외?
- 무료 체험 종료 후 미전환은 포함/제외?
- 같은 달 가입+해지는 포함/제외?

이 프로젝트에서는 "자발적 cancel 이벤트 발생한 사용자"만 이탈로 정의.
```

### 이탈률 공식 확정

이 프로젝트에서 사용하는 이탈률 정의:

```
월 이탈률(%) = 해당 월에 cancel 이벤트가 발생한 고유 user_id 수
               ÷ 해당 월 1일 기준 활성 구독 사용자 수
               × 100

포함: 자발적 cancel 이벤트
제외: 결제 실패로 인한 비자발적 해지, 테스트 계정(user_id < 100)
```

---

## Step 2. 원인 분析 SQL 파이프라인 (20분)

이탈률 증가의 원인을 5개 차원에서 분解합니다.

### SQL 1. 월별 이탈률 시계열 + Q1 집중 분析

**Copilot 프롬프트**:
```
PostgreSQL. subscriptions(user_id, event_type, plan, event_date, mrr) 기준.

월별 이탈률 시계열 SQL (2023-10 ~ 2024-03, 6개월).

이탈률 = 해당 월 cancel 사용자 수 / 해당 월 초 활성 구독 사용자 수 × 100
(활성 구독 = 해당 월 1일 기준 가장 최근 event_type이 'subscribe' or 'upgrade' or 'downgrade'인 사용자)

결과: year_month, active_start, churned, churn_rate, 전월 대비 변화(%p)
```

### SQL 2. 이탈 세그먼트 분解 (plan × 구독 기간)

**프롬프트**:
```
PostgreSQL. Q1(2024-01-01 ~ 2024-03-31) 이탈 사용자 분析.
테이블: subscriptions, users

분解 1: plan별 이탈 사용자 수, 비율(%), plan별 이탈률
분解 2: 구독 기간 구간별 이탈 분포
  - 0~30일: '초기 이탈'
  - 31~90일: '초반 이탈'
  - 91~180일: '중기 이탈'
  - 181일+: '장기 이탈'
  구독 기간 = cancel 날짜 - 해당 사용자의 첫 subscribe 날짜

결과: 각 분解별 사용자 수, 전체 이탈 대비 비율, Q4 대비 변화
```

### SQL 3. 이탈 전 행동 패턴 분析 (LAG 활용)

**프롬프트**:
```
PostgreSQL. 이탈 사용자(cancel 발생)의 이탈 30일 전 행동 vs 동기간 유지 사용자 비교.
테이블: events(user_id, event_name, event_date), subscriptions

이탈 그룹: Q1에 cancel 이벤트가 있는 user_id
유지 그룹: Q1에 cancel 없는 활성 구독 사용자 (랜덤 샘플 같은 크기)

비교 지표 (이탈 전/같은 기간 30일):
- 로그인 이벤트 평균 횟수
- 핵심 기능 사용 이벤트 평균 횟수 (event_name LIKE '%feature%')
- 마지막 이벤트로부터 이탈일까지 평균 경과 일수 (이탈 그룹만)
- 고객 지원 이벤트 발생 여부 (event_name = 'support_contact')

이탈 그룹 vs 유지 그룹 나란히 비교 + 차이(delta) 컬럼.
```

### SQL 4. 채널별 이탈률 비교 (이탈 품질 분析)

**프롬프트**:
```
PostgreSQL. 유입 채널별 이탈률 비교 (Q1 기준).
테이블: users(user_id, channel, signup_date), subscriptions

채널별:
- 해당 채널 통해 가입한 사용자 중 Q1 이탈자 수
- Q1 이탈률(%)
- 가입 후 평균 구독 기간 (이탈자 기준)

목적: 어떤 채널이 이탈률 높은 사용자를 데려오는지 파악
정렬: 이탈률 내림차순
```

### SQL 5. 이탈 직전 plan 변경 이력 (downgrade → cancel 패턴)

**프롬프트**:
```
PostgreSQL. Q1 이탈 사용자 중 이탈 전 60일 이내 downgrade가 있었던 사용자 비율.
테이블: subscriptions(user_id, event_type, plan, event_date)

이탈 경로 분류:
A. 직접 이탈 (구독 → cancel, downgrade 없음)
B. 다운그레이드 후 이탈 (구독 → downgrade → cancel, 60일 이내)
C. 장기 downgrade 후 이탈 (60일 초과 후 cancel)

각 경로의 사용자 수, 비율(%), 평균 구독 기간
→ 이 데이터로 "다운그레이드가 이탈 선행 신호인가" 판단
```

---

## Step 3. pandas 후처리 스크립트 (10분)

SQL 5개 결과를 pandas로 이어받아 통합 분析 DataFrame을 만듭니다.

**Copilot 프롬프트**:
```python
# SQL 결과 5개를 pandas로 통합 분析하는 스크립트.
# 각 결과는 CSV로 저장되어 있다고 가정.
# 파일: churn_trend.csv, churn_segment.csv, churn_behavior.csv, churn_channel.csv, churn_path.csv
#
# 처리:
# 1. 5개 파일 로드 + 기초 검증 (행 수, 컬럼 확인)
# 2. churn_trend에서 Q1(1~3월) vs Q4(10~12월) 이탈률 비교 DataFrame 생성
# 3. churn_segment에서 가장 이탈률 높은 세그먼트 Top 3 추출
# 4. churn_behavior에서 이탈 그룹과 유지 그룹의 로그인 횟수 차이 계산
# 5. churn_channel에서 이탈률 상위 3개 채널 추출
# 6. 모든 결과를 하나의 요약 dict로 묶어서 churn_summary.json으로 저장
#
# SettingWithCopyWarning 없이. 각 단계 print로 진행상황 출력.
```

**완성 코드 구조**:

```python
import pandas as pd
import json
from pathlib import Path

DATA_DIR = Path('data/capstone')

# 1. 파일 로드
print("=== 데이터 로드 ===")
try:
    churn_trend    = pd.read_csv(DATA_DIR / 'churn_trend.csv')
    churn_segment  = pd.read_csv(DATA_DIR / 'churn_segment.csv')
    churn_behavior = pd.read_csv(DATA_DIR / 'churn_behavior.csv')
    churn_channel  = pd.read_csv(DATA_DIR / 'churn_channel.csv')
    churn_path     = pd.read_csv(DATA_DIR / 'churn_path.csv')
    print(f"churn_trend: {len(churn_trend)}행")
    print(f"churn_segment: {len(churn_segment)}행")
    print(f"churn_behavior: {len(churn_behavior)}행")
    print(f"churn_channel: {len(churn_channel)}행")
    print(f"churn_path: {len(churn_path)}행")
except FileNotFoundError as e:
    print(f"파일 없음: {e}. 가상 데이터로 대체합니다.")
    # 가상 데이터로 대체 (실습용)
    import numpy as np
    np.random.seed(42)
    months = ['2023-10', '2023-11', '2023-12', '2024-01', '2024-02', '2024-03']
    churn_trend = pd.DataFrame({
        'year_month': months,
        'active_start': [42000, 44000, 47000, 49000, 51000, 53000],
        'churned': [2940, 3080, 3290, 3920, 4080, 4400],
        'churn_rate': [7.0, 7.0, 7.0, 8.0, 8.0, 8.3]
    })

# 2. Q1 vs Q4 비교
q1_months = ['2024-01', '2024-02', '2024-03']
q4_months = ['2023-10', '2023-11', '2023-12']

q1_avg = churn_trend[churn_trend['year_month'].isin(q1_months)]['churn_rate'].mean()
q4_avg = churn_trend[churn_trend['year_month'].isin(q4_months)]['churn_rate'].mean()

print(f"\n=== Q4 vs Q1 이탈률 비교 ===")
print(f"Q4(2023) 평균 이탈률: {q4_avg:.1f}%")
print(f"Q1(2024) 평균 이탈률: {q1_avg:.1f}%")
print(f"변화: {q1_avg - q4_avg:+.1f}%p")

# 6. 요약 저장
summary = {
    'q4_avg_churn': round(q4_avg, 2),
    'q1_avg_churn': round(q1_avg, 2),
    'churn_delta_pp': round(q1_avg - q4_avg, 2),
}

with open('churn_summary.json', 'w', encoding='utf-8') as f:
    json.dump(summary, f, ensure_ascii=False, indent=2)

print("\n=== 요약 저장 완료: churn_summary.json ===")
```

---

## Step 4. 시각화 6개 (10분)

앞서 만든 데이터로 대시보드용 차트 6개를 생성합니다.

**한 번에 6개 생성하는 Copilot 프롬프트**:
```python
# 이탈 분析 딥다이브용 시각화 6개를 하나의 Python 파일에.
# 각 차트는 별도 함수로, 마지막에 모두 실행.
# 가상 데이터는 각 함수 안에서 생성.
#
# 차트 1: plot_churn_trend() — 월별 이탈률 시계열 (라인, plotly)
# 차트 2: plot_churn_by_segment() — plan × 구독기간 구간별 이탈 분포 (누적 바, matplotlib)
# 차트 3: plot_behavior_comparison() — 이탈/유지 그룹 로그인 횟수 분포 (바이올린, seaborn)
# 차트 4: plot_channel_churn() — 채널별 이탈률 (수평 바, plotly)
# 차트 5: plot_churn_path() — 이탈 경로 분류 (도넛 차트, plotly)
# 차트 6: plot_churn_heatmap() — plan × 월별 이탈률 히트맵 (seaborn)
#
# 각 차트 요구사항:
# - 한글 폰트 (Malgun Gothic, Windows 기준)
# - 타이틀에 Q1 2024 맥락 포함
# - 저장: churn_charts/ 폴더에 png 또는 html
```

### 차트별 핵심 코드 패턴

**차트 1. 월별 이탈률 트렌드 (plotly)**:

```python
import plotly.graph_objects as go
import pandas as pd

def plot_churn_trend():
    months = ['2023-10', '2023-11', '2023-12', '2024-01', '2024-02', '2024-03']
    rates  = [7.0, 7.0, 7.0, 8.0, 8.0, 8.3]

    fig = go.Figure()
    fig.add_trace(go.Scatter(
        x=months, y=rates,
        mode='lines+markers',
        line=dict(color='#DC3545', width=2.5),
        marker=dict(size=8),
        hovertemplate='%{x}: %{y:.1f}%<extra></extra>'
    ))
    fig.add_hline(y=7.0, line_dash='dash', line_color='gray',
                  annotation_text='Q4 평균 7.0%')
    fig.update_layout(
        title='월별 이탈률 추이 (Q4 2023 ~ Q1 2024)',
        yaxis_title='이탈률 (%)', yaxis_ticksuffix='%',
        plot_bgcolor='white', height=350
    )
    fig.write_html('churn_charts/01_churn_trend.html')
    print("차트 1 저장 완료")
```

**차트 6. plan × 월별 이탈률 히트맵 (seaborn)**:

```python
import seaborn as sns
import matplotlib.pyplot as plt
import matplotlib as mpl
import numpy as np

mpl.rcParams['font.family'] = 'Malgun Gothic'
mpl.rcParams['axes.unicode_minus'] = False

def plot_churn_heatmap():
    plans  = ['basic', 'pro', 'enterprise']
    months = ['2024-01', '2024-02', '2024-03']
    data = np.array([
        [9.8, 10.1, 11.2],  # basic
        [6.2,  6.5,  7.1],  # pro
        [3.1,  3.0,  3.5],  # enterprise
    ])
    df_heat = pd.DataFrame(data, index=plans, columns=months)

    fig, ax = plt.subplots(figsize=(8, 4))
    sns.heatmap(df_heat, ax=ax, annot=True, fmt='.1f',
                cmap='RdYlGn_r', vmin=0, vmax=15,
                linewidths=0.5, linecolor='white',
                cbar_kws={'label': '이탈률 (%)'})
    ax.set_title('plan × 월별 이탈률 히트맵 (Q1 2024)', fontsize=13, fontweight='bold')
    ax.set_xlabel('월')
    ax.set_ylabel('플랜')
    plt.tight_layout()
    plt.savefig('churn_charts/06_churn_heatmap.png', dpi=150, bbox_inches='tight')
    print("차트 6 저장 완료")
```

---

## Step 5. 대시보드 스펙 문서 (5분)

**Copilot 프롬프트**:
```
"Zeta Q1 이탈 딥다이브 대시보드" 스펙 문서를 한 페이지 Markdown으로 작성해줘.

메타:
- 목적: Q1 이탈 원인 파악 및 대응 우선순위 설정
- 사용자: COO, PM, CS 팀장
- BI 도구: Metabase (SQL 기반)
- 업데이트: 주 1회 (금요일)

포함 차트 6개 (위에서 만든 것):
1. 이탈률 시계열
2. 세그먼트별 이탈 분포
3. 행동 패턴 비교
4. 채널별 이탈률
5. 이탈 경로 분류
6. plan × 월별 히트맵

각 차트: 목적(1줄), 데이터 소스, 핵심 필터 조건만.
전체 길이: A4 1페이지 분량.
```

---

## Step 6. 임원 리포트 인사이트 (5분)

5개 SQL 분析 결과(가상 수치)를 바탕으로 COO에게 보내는 리포트 인사이트를 생성합니다.

### 가상 분析 결과 요약

```
Q1 2024 이탈 분析 결과:

1. 이탈률: Q4 7.0% → Q1 8.3% (+1.3%p)
   - 1월 +1.0%p, 2월 +1.0%p, 3월 +1.3%p (3월 가속화)

2. 이탈 세그먼트:
   - basic 플랜 이탈 71%, 그 중 가입 30일 이내 이탈 44%
   - 초기 이탈(0~30일) 비율: Q4 38% → Q1 44% (+6%p)

3. 행동 패턴:
   - 이탈 그룹 30일 전 로그인: 평균 2.3회 (유지 그룹 11.8회)
   - 이탈 그룹의 63%가 이탈 전 7일 이내 로그인 없음

4. 채널:
   - paid_social 채널 이탈률 12.4% (전체 평균 대비 +4.1%p)
   - organic 채널 이탈률 6.1% (가장 낮음)

5. 이탈 경로:
   - downgrade → cancel (60일 이내): 전체 이탈의 28%
   - downgrade가 있는 이탈 사용자의 평균 구독 기간: 127일 (직접 이탈 91일)
```

### Copilot 프롬프트

```
위 분析 결과를 바탕으로 COO에게 보내는 딥다이브 리포트 인사이트 섹션 작성.

구조:
1. 헤드라인 (한 문장 — 가장 중요한 발견)
2. 핵심 원인 3가지 (각 수치 포함, 우선순위 순)
3. 즉시 실행 가능한 권고 액션 3가지 (각 예상 임팩트 포함)

톤: COO 대상, 데이터 기반, 수치 반드시 포함
길이: 400자 이내
모호한 표현 ("것으로 보입니다", "다소", "어느 정도") 절대 금지
```

### 예상 생성 결과 (참고)

```markdown
## Q1 이탈 딥다이브 — 핵심 발견

**헤드라인**: Q1 이탈 악화(+1.3%p)의 44%는 가입 30일 이내 basic 플랜 사용자에서 발생.
온보딩 품질이 직접 원인입니다.

**핵심 원인**

1. **온보딩 실패**: basic 플랜 초기 이탈(30일 이내)이 Q4 38%에서 Q1 44%로 상승.
   이탈 사용자의 63%가 이탈 7일 전 이미 로그인 없음.

2. **paid_social 채널 품질 저하**: 해당 채널 이탈률 12.4%, 전체 평균 대비 +4.1%p.
   Q1 paid_social 예산 증가와 시간적으로 일치.

3. **다운그레이드 → 이탈 경로**: 이탈의 28%가 downgrade 후 60일 이내 cancel.
   다운그레이드가 이탈 선행 신호로 작동.

**권고 액션**

1. 가입 7~14일 차 비활성 사용자 대상 인앱 체크포인트 도입.
   (예상: 초기 이탈 10~15% 감소, 월 약 400~600명 이탈 방지)

2. paid_social 캠페인 타겟팅 재검토 + Q2 예산 일부 organic 전환.
   (paid_social 이탈률 12.4% → organic 수준 6.1%로 개선 시 월 ~800명 이탈 감소)

3. downgrade 후 30일 이내 사용자 전담 CS 아웃리치 파이럿 (50명, 4주).
   (다운그레이드 이탈 28%의 절반 전환 시 월 MRR $12,000+ 회복)
```

---

## Step 7. 반복 실행 스크립트 (10분)

이 딥다이브를 매주 자동으로 업데이트하는 스크립트를 만듭니다.

**Copilot 프롬프트**:
```python
# 매주 금요일 자동 실행되는 이탈 분析 스크립트.
# 기능:
# 1. data/ 폴더에서 최신 CSV 파일 5개 자동 로드 (날짜 기준 최신 파일)
# 2. 이전 주 결과와 비교 (churn_rate 변화)
# 3. 이탈률이 전주 대비 +0.5%p 이상 상승하면 경고 메시지 출력
# 4. 결과를 reports/YYYYMMDD_churn_weekly.csv로 저장
# 5. 실행 로그를 logs/churn_run.log에 추가 (append)
#
# 실행 방법:
# python weekly_churn_report.py
# 또는 cron: 0 9 * * 5 python /path/to/weekly_churn_report.py
#
# 외부 라이브러리: pandas, pathlib, logging만 사용.
# 각 함수에 docstring + 에러 처리.
```

**완성 코드 구조**:

```python
#!/usr/bin/env python3
"""
weekly_churn_report.py
매주 금요일 자동 실행되는 이탈 분析 스크립트.

실행: python weekly_churn_report.py
Cron: 0 9 * * 5 python /path/to/weekly_churn_report.py
"""

import pandas as pd
import logging
import json
from pathlib import Path
from datetime import datetime

# 설정
DATA_DIR    = Path('data')
REPORTS_DIR = Path('reports')
LOGS_DIR    = Path('logs')
THRESHOLD   = 0.5  # 이탈률 경고 임계값 (%p)

# 폴더 생성
for d in [REPORTS_DIR, LOGS_DIR]:
    d.mkdir(exist_ok=True)

# 로깅 설정
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s %(levelname)s %(message)s',
    handlers=[
        logging.FileHandler(LOGS_DIR / 'churn_run.log', encoding='utf-8'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)


def load_latest_csv(pattern: str) -> pd.DataFrame:
    """패턴에 맞는 가장 최신 CSV 파일 로드."""
    files = sorted(DATA_DIR.glob(pattern))
    if not files:
        raise FileNotFoundError(f"파일 없음: {DATA_DIR / pattern}")
    latest = files[-1]
    logger.info(f"로드: {latest.name}")
    return pd.read_csv(latest)


def calculate_weekly_churn(df: pd.DataFrame) -> dict:
    """주간 이탈률 계산 및 요약 반환."""
    latest_month = df['year_month'].max()
    latest_rate  = df.loc[df['year_month'] == latest_month, 'churn_rate'].values[0]
    prev_rate    = df.loc[df['year_month'] != latest_month, 'churn_rate'].iloc[-1] if len(df) > 1 else latest_rate

    return {
        'run_date':    datetime.now().strftime('%Y-%m-%d'),
        'latest_month': latest_month,
        'churn_rate':  round(latest_rate, 2),
        'prev_rate':   round(prev_rate, 2),
        'delta_pp':    round(latest_rate - prev_rate, 2)
    }


def check_alert(summary: dict) -> None:
    """이탈률 급등 시 경고 출력."""
    if summary['delta_pp'] >= THRESHOLD:
        msg = (
            f"[경고] 이탈률 급등: {summary['prev_rate']}% → {summary['churn_rate']}% "
            f"(+{summary['delta_pp']:.1f}%p). 즉시 확인 필요."
        )
        logger.warning(msg)
    else:
        logger.info(f"이탈률 정상 범위: {summary['churn_rate']}% (전주 대비 {summary['delta_pp']:+.1f}%p)")


def save_report(summary: dict) -> None:
    """결과를 CSV로 저장."""
    run_date = summary['run_date'].replace('-', '')
    output_path = REPORTS_DIR / f"{run_date}_churn_weekly.json"
    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(summary, f, ensure_ascii=False, indent=2)
    logger.info(f"저장 완료: {output_path}")


def main():
    logger.info("=== 주간 이탈 분析 시작 ===")
    try:
        df_trend = load_latest_csv('churn_trend*.csv')
        summary  = calculate_weekly_churn(df_trend)
        check_alert(summary)
        save_report(summary)
        logger.info("=== 완료 ===")
    except FileNotFoundError as e:
        logger.error(f"데이터 파일 없음: {e}")
    except Exception as e:
        logger.error(f"예상치 못한 오류: {e}", exc_info=True)


if __name__ == '__main__':
    main()
```

---

## 캡스톤 완료 체크리스트

| 결과물 | 완료 | 파일 위치 |
|--------|------|---------|
| 지표 정의서 (6개 지표) | [ ] | 메모 또는 별도 .md |
| SQL 5개 (원인 분析) | [ ] | capstone_queries.sql |
| pandas 통합 스크립트 | [ ] | capstone_analysis.py |
| 시각화 6개 | [ ] | churn_charts/ |
| 대시보드 스펙 문서 | [ ] | capstone_dashboard_spec.md |
| 임원 리포트 인사이트 | [ ] | capstone_report.md |
| 반복 실행 스크립트 | [ ] | weekly_churn_report.py |

---

## 2일 과정 최종 회고

### 만든 것들

**Day 1 (SQL + 클리닝)**:
- 코호트 리텐션 SQL (CTE + Window Function)
- 세션 분析 SQL (LAG)
- 퍼널 분析 SQL
- RFM SQL (NTILE)
- MRR 분解 SQL
- 데이터 오디팅 + 클리닝 파이프라인

**Day 2 (pandas + 시각화 + 스토리)**:
- pandas 후처리 코드 5개
- 시각화 6종 (matplotlib/seaborn/plotly)
- 대시보드 스펙 문서
- 인사이트 리포트 템플릿
- 반복 실행 스크립트

### 앞으로의 활용

1. `resources/templates/sql-patterns.sql`을 내 DB 방언에 맞게 수정해서 스니펫으로 저장
2. `resources/examples/pandas-recipes.py`를 팀 내 공유해서 동일한 코드 품질 유지
3. `resources/templates/dashboard-spec-template.md`를 BI 요청 표준 양식으로 사용
4. `weekly_churn_report.py` 패턴을 내 정기 리포트에 적용

---

**과정 완료.** 첫 번째 Copilot 활용 분析 → 다음 실제 업무에서 써보세요.
