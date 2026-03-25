# 삼성 반도체 관련 웹 크롤링 Daily Reporting 시스템

## 1. 프로젝트 개요

삼성 반도체와 관련된 정보를 다수의 웹사이트에서 자동 크롤링하고, LLM을 활용하여 유의미한 정보를 판별한 뒤, 일일 리포트를 이메일로 발송하는 자동화 시스템.

### 1.1 핵심 수집 카테고리

| 카테고리 | 설명 | 예시 키워드 |
|---------|------|------------|
| 삼성 반도체 기술 이슈 | 삼성 반도체 관련 기술 동향, 신제품, 공정 이슈, 수율 문제 등 | Samsung semiconductor, 삼성 파운드리, GAA, HBM, NAND, DRAM |
| 경쟁사 채용 동향 | TSMC, Intel, SK하이닉스, Micron 등 경쟁사의 채용 공고 및 인력 이동 | hiring, recruit, 채용, talent acquisition |
| 경쟁사/업계 트렌드 | 반도체 산업 전반의 트렌드, 경쟁사 전략, 시장 변화 | AI chip, advanced packaging, chiplet, 반도체 보조금 |

### 1.2 경쟁사 목록

- TSMC
- Intel (Intel Foundry Services)
- SK하이닉스
- Micron Technology
- GlobalFoundries
- NVIDIA (팹리스 / AI 반도체)
- AMD
- Qualcomm
- Broadcom

---

## 2. 크롤링 대상 사이트 관리

### 2.1 사이트 리스트 파일 관리

크롤링 대상 사이트 목록은 **별도 리스트 파일(`config/crawl_sites.yaml`)**로 관리하여 관리자가 손쉽게 조회·수정할 수 있도록 한다.

**관리 원칙:**
- 크롤링 대상 사이트 목록은 `config/crawl_sites.yaml` 파일 단일 소스로 관리
- 관리자가 YAML 파일을 직접 편집하거나, 관리 CLI/웹 UI를 통해 수정 가능
- 파일 변경 시 자동 감지(watchdog) → 크롤러 매니저에 즉시 반영 (서비스 재시작 불필요)
- 변경 이력은 Git 버전 관리 또는 별도 changelog 로그로 추적
- 사이트 추가/삭제/수정 시 관리자에게 변경 확인 알림 발송

**사이트 리스트 파일 구조 (`config/crawl_sites.yaml`):**
```yaml
# 크롤링 대상 사이트 마스터 리스트
# 최종 수정: 2026-03-25
# 수정자: admin@company.com

metadata:
  version: "1.2"
  last_updated: "2026-03-25"
  updated_by: "admin@company.com"
  total_sites: 25

sites:
  global_news:
    - name: "Reuters Tech"
      url: "https://www.reuters.com/technology/"
      crawler_type: "rss"
      rss_url: "https://www.reuters.com/technology/rss"
      category: "글로벌 뉴스"
      enabled: true
      added_date: "2026-03-01"
      notes: "반도체 관련 기사 필터링"

    - name: "Bloomberg Tech"
      url: "https://www.bloomberg.com/technology"
      crawler_type: "html"
      category: "글로벌 뉴스"
      enabled: true
      added_date: "2026-03-01"
      notes: "유료 구독 필요 여부 확인"

    # ... (이하 사이트 동일 형식으로 관리)

  semiconductor_media:
    - name: "SemiAnalysis"
      url: "https://www.semianalysis.com/"
      crawler_type: "rss"
      category: "반도체 전문"
      enabled: true
      added_date: "2026-03-01"

  korean_media:
    - name: "전자신문 (ET News)"
      url: "https://www.etnews.com/"
      crawler_type: "html"
      category: "한국 미디어"
      enabled: true
      added_date: "2026-03-01"

  job_platforms:
    - name: "LinkedIn Jobs"
      url: "https://www.linkedin.com/jobs/"
      crawler_type: "api"
      category: "채용 플랫폼"
      enabled: true
      added_date: "2026-03-01"

  communities:
    - name: "Reddit (r/semiconductors)"
      url: "https://www.reddit.com/r/semiconductors/"
      crawler_type: "api"
      category: "커뮤니티"
      enabled: true
      added_date: "2026-03-01"
```

**관리자 사이트 관리 CLI:**
```bash
# 사이트 목록 조회
python manage.py sites list
python manage.py sites list --category="반도체 전문"
python manage.py sites list --enabled-only

# 사이트 추가
python manage.py sites add --name="새 사이트" --url="https://..." --type="rss"

# 사이트 비활성화/삭제
python manage.py sites disable --name="Bloomberg Tech"
python manage.py sites remove --name="Bloomberg Tech"

# 사이트 목록 내보내기 (CSV/JSON)
python manage.py sites export --format=csv --output=sites_backup.csv
```

### 2.2 초기 크롤링 대상 사이트 목록

#### 글로벌 뉴스/기술 미디어

| 사이트 | URL | 수집 방식 | 비고 |
|--------|-----|----------|------|
| Reuters (Tech) | https://www.reuters.com/technology/ | RSS / HTML 파싱 | 반도체 관련 기사 필터링 |
| Bloomberg (Tech) | https://www.bloomberg.com/technology | HTML 파싱 | 유료 구독 필요 여부 확인 |
| TechCrunch | https://techcrunch.com/ | RSS | 반도체/AI 칩 관련 |
| The Verge | https://www.theverge.com/ | RSS | 주요 기술 뉴스 |
| Ars Technica | https://arstechnica.com/ | RSS | 기술 심층 분석 |
| Tom's Hardware | https://www.tomshardware.com/ | RSS / HTML 파싱 | 반도체 하드웨어 전문 |
| AnandTech / TechInsights | https://www.techinsights.com/ | HTML 파싱 | 반도체 분석 전문 |

#### 반도체 전문 미디어

| 사이트 | URL | 수집 방식 | 비고 |
|--------|-----|----------|------|
| SemiAnalysis | https://www.semianalysis.com/ | RSS / HTML 파싱 | 반도체 산업 심층 분석 |
| Semiconductor Engineering | https://semiengineering.com/ | RSS | 공정/기술 전문 |
| EE Times | https://www.eetimes.com/ | RSS | 전자/반도체 뉴스 |
| DigiTimes | https://www.digitimes.com/ | HTML 파싱 | 아시아 반도체 공급망 |
| SEMI.org | https://www.semi.org/ | HTML 파싱 | 반도체 장비/소재 업계 |
| IC Insights | - | HTML 파싱 | 시장 분석 데이터 |

#### 한국 미디어

| 사이트 | URL | 수집 방식 | 비고 |
|--------|-----|----------|------|
| 전자신문 (ET News) | https://www.etnews.com/ | HTML 파싱 | 국내 IT/반도체 전문 |
| 더일렉 (TheElec) | https://www.thelec.kr/ | HTML 파싱 | 반도체/디스플레이 전문 |
| ZDNet Korea | https://zdnet.co.kr/ | RSS / HTML 파싱 | IT 전문 |
| 한경 산업 | https://www.hankyung.com/ | HTML 파싱 | 산업/경제 뉴스 |
| IT조선 | https://it.chosun.com/ | HTML 파싱 | IT 뉴스 |

#### 채용 플랫폼

| 사이트 | URL | 수집 방식 | 비고 |
|--------|-----|----------|------|
| LinkedIn Jobs | https://www.linkedin.com/jobs/ | API / 스크래핑 | 경쟁사 반도체 관련 채용 |
| Indeed | https://www.indeed.com/ | HTML 파싱 | 경쟁사 채용 공고 |
| Glassdoor | https://www.glassdoor.com/ | HTML 파싱 | 채용 + 기업 리뷰 |
| 경쟁사 공식 채용 페이지 | 각사 careers 페이지 | HTML 파싱 | TSMC, Intel 등 |

#### 커뮤니티 / 포럼

| 사이트 | URL | 수집 방식 | 비고 |
|--------|-----|----------|------|
| Reddit (r/semiconductors 등) | https://www.reddit.com/ | Reddit API | 업계 여론/트렌드 |
| Hacker News | https://news.ycombinator.com/ | API | 기술 커뮤니티 반응 |
| X (Twitter) | https://x.com/ | API | 업계 인사 및 전문가 트윗 |

### 2.3 신규 크롤링 사이트 자동 추천 (주간 센싱)

**역할:** 1주일 단위로 웹에서 반도체 관련 새로운 정보 소스를 탐색하고, 관리자에게 추천

**동작 방식:**
1. **웹 탐색:** 기존 크롤링 기사에서 자주 인용되는 외부 소스 URL 추출
2. **검색엔진 활용:** Google/Bing 검색 API로 반도체 관련 신규 미디어/블로그/리포트 사이트 탐색
3. **품질 평가:** 발견된 사이트의 콘텐츠 품질을 LLM으로 자동 평가
   - 반도체 관련 기사 비율
   - 업데이트 빈도
   - 콘텐츠 품질 (깊이, 정확도)
   - 크롤링 가능 여부 (robots.txt, 접근성)
4. **추천 리포트:** 평가 결과를 바탕으로 주간 사이트 추천 리포트 생성 → 관리자 이메일 발송

**주간 사이트 추천 리포트 형식:**
```
===================================
크롤링 사이트 추천 리포트
기간: 2026-03-18 ~ 2026-03-25
===================================

[신규 추천 사이트]
1. SemiWiki (https://semiwiki.com/)
   - 추천 사유: 반도체 공정/설계 전문 커뮤니티, 주 3-4회 기술 심층 기사 게시
   - 반도체 관련도: 95%
   - 크롤링 가능 여부: 가능 (RSS 지원)
   - 추천 등급: ★★★★★

2. ...

[기존 사이트 상태 점검]
- 비활성/접근 불가 사이트: Bloomberg Tech (403 차단 3일 연속)
- 콘텐츠 품질 저하 사이트: 없음
- 중복 콘텐츠 비율 높은 사이트: IT조선 (타 매체 재인용 비율 70%)

[관리자 액션 필요]
- Bloomberg Tech: 크롤링 방식 변경 또는 비활성화 검토
- SemiWiki: 추가 여부 결정 필요
```

**관리자 승인 워크플로:**
1. 추천 리포트 수신 → 관리자가 추가할 사이트 선택
2. 관리자가 CLI 또는 웹 UI로 승인 → `config/crawl_sites.yaml`에 자동 추가
3. 크롤러 매니저가 변경 감지 → 즉시 크롤링 대상에 반영

---

## 3. 시스템 아키텍처

```
[Scheduler (Cron/APScheduler)]
        |
        v
[Site List Manager] ──> config/crawl_sites.yaml (파일 변경 감지)
        |
        v
[Crawler Manager] ──> [Site Crawler 1] ──> HTML/RSS 파싱
        |              [Site Crawler 2] ──> API 호출
        |              [Site Crawler N] ──> ...
        v
[Raw Data Storage] (DB / File)
        |
        v
[Preprocessor] ──> 중복 제거, 본문 추출, 언어 감지
        |
        v
[LLM Router] ──> Provider 선택 (OpenAI / Anthropic / Google / Custom)
        |
        v
[LLM Analyzer] ──> CoT + Few-Shot 기반 분석 (관련성 + 카테고리 + 요약 + 중요도)
        |
        v
[Report Generator] ──> 일일 리포트 생성 (HTML 형식)
        |
        v
[Email Sender] ──> SMTP를 통한 메일 발송

[Weekly Site Recommender] ──> 신규 사이트 탐색 + 품질 평가 → 관리자 추천 리포트
```

---

## 4. 상세 모듈 설계

### 4.1 Crawler Manager (크롤러 관리 모듈)

**역할:** 크롤링 대상 사이트 관리, 크롤링 스케줄 조율, 크롤러 실행 관리

**요구사항:**
- `config/crawl_sites.yaml` 파일에서 크롤링 대상 사이트 목록 로드
- **파일 변경 감지(watchdog):** 관리자가 사이트 리스트 파일을 수정하면 실시간 반영 (서비스 재시작 불필요)
- 사이트별 크롤링 주기 설정 (기본: 1일 1회, 속보성 사이트는 수시간 간격)
- 사이트별 크롤러 타입 매핑 (RSS, HTML 파싱, API)
- 크롤링 실패 시 재시도 로직 (최대 3회, 지수 백오프)
- 크롤링 상태 로깅 (성공/실패/부분 성공)
- Rate limiting 준수 (사이트별 요청 간격 설정)
- robots.txt 준수 여부 확인

**크롤링 스케줄 설정 파일 구조 (`config/sites.yaml`):**
```yaml
sites:
  - name: "Reuters Tech"
    url: "https://www.reuters.com/technology/"
    crawler_type: "rss"
    rss_url: "https://www.reuters.com/technology/rss"
    schedule: "0 6 * * *"  # 매일 오전 6시
    rate_limit: 2  # 초당 최대 요청 수
    retry_count: 3
    enabled: true
    keywords:
      - "Samsung"
      - "semiconductor"
      - "TSMC"
      - "HBM"
```

### 4.2 Site Crawlers (사이트별 크롤러)

**공통 인터페이스:**
```python
class BaseCrawler:
    def crawl(self, config: SiteConfig) -> List[RawArticle]
    def parse(self, response) -> List[RawArticle]
    def validate(self, article: RawArticle) -> bool
```

**크롤러 타입:**

| 타입 | 라이브러리 | 용도 |
|------|-----------|------|
| RSS Crawler | `feedparser` | RSS/Atom 피드 지원 사이트 |
| HTML Crawler | `requests` + `BeautifulSoup` / `Playwright` | 일반 웹페이지 파싱 |
| API Crawler | `requests` / 전용 SDK | Reddit API, Twitter API 등 |
| Dynamic Crawler | `Playwright` / `Selenium` | JavaScript 렌더링 필요 사이트 |

**수집 데이터 구조:**
```python
@dataclass
class RawArticle:
    source: str           # 출처 사이트명
    url: str              # 원문 URL
    title: str            # 제목
    content: str          # 본문 (전체 또는 요약)
    published_at: datetime # 게시 일시
    author: str           # 작성자
    language: str         # 언어 (ko/en)
    crawled_at: datetime  # 크롤링 시각
    raw_html: str         # 원본 HTML (디버깅용, 선택)
```

### 4.3 Preprocessor (전처리 모듈)

**역할:** 크롤링된 원시 데이터를 LLM 분석 전에 정제

**처리 단계:**
1. **중복 제거** - URL 기반 + 제목 유사도(코사인 유사도 > 0.9) 기반 중복 탐지
2. **본문 추출** - HTML 태그 제거, 광고/네비게이션 영역 제거 (`trafilatura` 또는 `newspaper3k` 활용)
3. **언어 감지** - `langdetect` 활용, 한국어/영어 분류
4. **키워드 1차 필터링** - 사전 정의 키워드 매칭으로 명백히 무관한 기사 제거 (LLM 비용 절감)
5. **텍스트 정규화** - 특수문자 정리, 인코딩 통일 (UTF-8)

### 4.4 LLM Analyzer (LLM 분석 모듈)

**역할:** 전처리된 기사를 LLM으로 분석하여 관련성, 카테고리, 중요도 판단

**사용 모델:** 멀티 LLM 지원 (선택 가능)

| LLM Provider | 모델 예시 | 비고 |
|-------------|----------|------|
| OpenAI | GPT-4o, GPT-4o-mini | 범용 분석 |
| Anthropic | Claude Sonnet, Claude Haiku | 긴 문맥 분석에 강점 |
| Google | Gemini Pro, Gemini Flash | 다국어 지원 우수 |
| 사내 Custom API | 사내 LLM 엔드포인트 | 보안/비용 측면 유리 |

**LLM 선택 및 설정:**
- 관리자가 설정 파일(`config/llm.yaml`)에서 사용할 LLM Provider와 모델을 선택
- 분석 단계별로 서로 다른 모델 지정 가능 (예: 관련성 판단은 저비용 모델, 요약은 고성능 모델)
- Fallback 체인 설정: 1차 모델 장애 시 자동으로 대체 모델로 전환
- Provider별 API 키는 `.env`에서 관리

**LLM 설정 파일 구조 (`config/llm.yaml`):**
```yaml
llm:
  # 기본 Provider 설정
  default_provider: "openai"  # openai / anthropic / google / custom

  providers:
    openai:
      api_key_env: "OPENAI_API_KEY"
      default_model: "gpt-4o"
      models:
        relevance: "gpt-4o-mini"      # 관련성 판단 (저비용)
        categorization: "gpt-4o-mini"  # 카테고리 분류 (저비용)
        importance: "gpt-4o"           # 중요도 평가 (고성능)
        summary: "gpt-4o"             # 요약 생성 (고성능)
      max_tokens_per_day: 500000

    anthropic:
      api_key_env: "ANTHROPIC_API_KEY"
      default_model: "claude-sonnet-4-6"
      models:
        relevance: "claude-haiku-4-5-20251001"
        categorization: "claude-haiku-4-5-20251001"
        importance: "claude-sonnet-4-6"
        summary: "claude-sonnet-4-6"
      max_tokens_per_day: 500000

    google:
      api_key_env: "GOOGLE_API_KEY"
      default_model: "gemini-2.0-flash"
      models:
        relevance: "gemini-2.0-flash"
        categorization: "gemini-2.0-flash"
        importance: "gemini-2.0-pro"
        summary: "gemini-2.0-pro"
      max_tokens_per_day: 500000

    custom:
      api_base_url_env: "CUSTOM_LLM_BASE_URL"
      api_key_env: "CUSTOM_LLM_API_KEY"
      default_model: "internal-model-v2"
      request_format: "openai_compatible"  # openai_compatible / custom
      max_tokens_per_day: 1000000

  # Fallback 체인 (1차 장애 시 순서대로 시도)
  fallback_chain:
    - "openai"
    - "anthropic"
    - "google"
    - "custom"
```

**분석 프로세스 (고정확도 프롬프트 엔지니어링):**

> **프롬프트 설계 원칙:**
> 모든 분석 프롬프트는 다음 기법을 조합하여 정확도를 극대화한다.
> - **Chain-of-Thought (CoT):** 단계별 추론 과정을 명시적으로 출력하도록 유도
> - **Few-Shot Examples:** 각 분석 단계마다 2-3개의 정답 예시를 포함
> - **Role Prompting:** LLM에 "반도체 산업 전문 애널리스트" 역할 부여
> - **Self-Consistency:** 중요 판단은 동일 프롬프트로 3회 호출 후 다수결 (CRITICAL 이슈에 적용)
> - **Structured Output:** JSON 스키마로 출력 형식을 강제하여 파싱 안정성 확보
> - **Guardrails:** 판단 근거 필수 기재, 불확실한 경우 "UNCERTAIN" 레이블 사용

#### Step 1: 관련성 판단 (CoT + Few-Shot)
```
시스템 프롬프트:
"당신은 삼성전자 반도체 사업부 소속 산업 분석 전문가입니다.
 반도체 산업에 대한 깊은 이해를 바탕으로 기사의 관련성을 정확히 판단합니다."

프롬프트:
"다음 기사가 삼성 반도체, 반도체 경쟁사(TSMC, Intel, SK하이닉스 등),
 또는 반도체 산업 트렌드와 관련이 있는지 판단하세요.

 **단계별로 사고하세요 (Chain-of-Thought):**
 1. 기사의 핵심 주제를 파악하세요.
 2. 반도체 산업과의 직접적/간접적 관련성을 분석하세요.
 3. 삼성 반도체에 대한 영향도를 평가하세요.
 4. 최종 관련성 등급을 결정하세요.

 **예시 1 (HIGH):**
 기사: 'TSMC, 2nm 공정 양산 시기를 2025년에서 2026년으로 연기'
 사고 과정: 이 기사는 TSMC의 첨단 공정 양산 일정에 관한 것이다. TSMC는 삼성 파운드리의
 직접 경쟁사이며, 2nm 공정 지연은 삼성에게 경쟁 기회를 제공할 수 있다.
 관련성: HIGH
 판단 근거: 삼성 파운드리 직접 경쟁사의 핵심 기술 일정 변경

 **예시 2 (NONE):**
 기사: '테슬라, 신형 전기차 모델 공개 예정'
 사고 과정: 이 기사는 전기차 산업 소식이다. 반도체와 간접적 연관은 있으나,
 반도체 산업 자체를 다루지 않으며 삼성 반도체에 직접적 영향이 없다.
 관련성: NONE
 판단 근거: 반도체 산업과 직접적 관련 없는 완성차 소식

 **출력 형식 (JSON):**
 {
   \"reasoning\": \"단계별 사고 과정\",
   \"relevance\": \"HIGH | MEDIUM | LOW | NONE\",
   \"rationale\": \"판단 근거 1-2문장\",
   \"confidence\": 0.0-1.0
 }"
```

#### Step 2: 카테고리 분류 (Few-Shot + Structured Output)
```
프롬프트:
"다음 기사를 아래 카테고리 중 하나 이상으로 분류하세요.
 반드시 분류 근거를 함께 제시하세요.

 카테고리 정의 및 예시:
 - SAMSUNG_TECH: 삼성 반도체 기술 이슈
   예시: '삼성전자, GAA 3nm 2세대 공정 수율 90% 돌파'
 - COMPETITOR_HIRING: 경쟁사 채용 동향
   예시: 'TSMC, 미국 애리조나 공장에 엔지니어 500명 추가 채용 공고'
 - INDUSTRY_TREND: 반도체 업계 트렌드
   예시: 'AI 반도체 시장, 2026년 전년 대비 45% 성장 전망'
 - COMPETITOR_STRATEGY: 경쟁사 전략/사업
   예시: 'Intel, 파운드리 사업부 분사 검토 보도'
 - SUPPLY_CHAIN: 공급망 이슈
   예시: 'ASML, 고NA EUV 장비 납기 6개월 지연'
 - REGULATION: 규제/정책 변화
   예시: '미 상무부, 대중국 반도체 장비 수출 규제 강화 발표'
 - MARKET: 시장/재무 동향
   예시: '글로벌 DRAM 가격, 3분기 연속 하락세'

 **출력 형식 (JSON):**
 {
   \"categories\": [\"CATEGORY_1\", \"CATEGORY_2\"],
   \"primary_category\": \"CATEGORY_1\",
   \"reasoning\": \"분류 근거\"
 }"
```

#### Step 3: 중요도 평가 (CoT + Self-Consistency)
```
프롬프트:
"다음 기사의 중요도를 삼성 반도체 관점에서 평가하세요.

 **단계별로 사고하세요:**
 1. 삼성 반도체 사업에 미치는 영향 범위 (전사/사업부/팀 수준)
 2. 시간적 긴급성 (즉시 대응 필요 / 중기 전략 참고 / 장기 참고)
 3. 정보의 신뢰도 (공식 발표 / 언론 보도 / 루머)
 4. 경쟁 전략 측면에서의 의미

 중요도 기준:
 - CRITICAL: 삼성에 즉각적 영향, 경영진 보고 필요
   예시: '삼성 파운드리, NVIDIA 차세대 GPU 수주 실패 보도'
 - HIGH: 주요 전략적 시사점, 팀 리더 보고 필요
   예시: 'TSMC, CoWoS 생산능력 2배 확대 계획 발표'
 - MEDIUM: 참고할 만한 정보
   예시: 'SEMI, 올해 반도체 장비 시장 5% 성장 전망'
 - LOW: 일반적인 업계 소식
   예시: '삼성전자, CES 2026 반도체 부스 참가 확정'

 **출력 형식 (JSON):**
 {
   \"reasoning\": \"단계별 평가 과정\",
   \"importance\": \"CRITICAL | HIGH | MEDIUM | LOW\",
   \"impact_scope\": \"전사 | 사업부 | 팀\",
   \"urgency\": \"즉시 | 중기 | 장기\",
   \"confidence\": 0.0-1.0
 }"

 ※ CRITICAL 판정 시: 동일 프롬프트로 3회 독립 호출 후 다수결로 최종 확정
   (Self-Consistency 적용, 오탐 방지)
```

#### Step 4: 한국어 요약 생성 (Role Prompting + Structured Output)
```
시스템 프롬프트:
"당신은 삼성전자 전략기획실 소속 반도체 산업 애널리스트입니다.
 경영진에게 보고할 수 있는 수준의 정확하고 간결한 요약을 작성합니다."

프롬프트:
"다음 기사를 분석하여 아래 형식으로 요약하세요.
 원문의 사실 관계를 정확히 반영하고, 추측은 명시적으로 표기하세요.

 **출력 형식 (JSON):**
 {
   \"summary\": [\"핵심 내용 1\", \"핵심 내용 2\", \"핵심 내용 3\"],
   \"implication\": \"삼성 관점에서의 시사점 1-2문장\",
   \"keywords\": [\"키워드1\", \"키워드2\", ...],
   \"action_needed\": true | false,
   \"suggested_action\": \"필요 시 권장 액션\"
 }"
```

#### Step 5: 분석 품질 검증 (Guardrails)
```
분석 결과에 대해 다음 검증을 자동 수행:
1. confidence < 0.6인 경우: "UNCERTAIN" 레이블 추가, 리포트에 별도 표기
2. 카테고리-중요도 불일치 검증 (예: COMPETITOR_HIRING인데 CRITICAL → 재검증)
3. 동일 사건 다중 기사 감지 시: 대표 기사 1건만 상세 분석, 나머지는 참조 링크로 처리
4. 한국어 요약의 환각(hallucination) 방지: 원문에 없는 수치/고유명사가 요약에 포함된 경우 플래그
```

**LLM 호출 최적화:**
- 배치 처리: 관련 기사를 묶어서 한 번에 분석 (토큰 효율화)
- 캐싱: 동일 기사 재분석 방지
- 비용 관리: Provider별 일일 토큰 사용량 모니터링 및 상한 설정
- 1차 필터(키워드 매칭)로 명백히 무관한 기사는 LLM 호출 없이 제외
- **모델 라우팅:** 기사 길이/복잡도에 따라 경량 모델 ↔ 고성능 모델 자동 선택
- **프롬프트 버전 관리:** 프롬프트 템플릿을 파일로 관리하고 버전별 정확도 추적

### 4.5 Report Generator (리포트 생성 모듈)

**역할:** LLM 분석 결과를 일일 리포트 형태로 가공

**리포트 구조:**

```
===================================
삼성 반도체 Daily Intelligence Report
날짜: 2026-03-25
===================================

[Executive Summary]
- 금일 총 수집 기사: 150건
- 유의미 기사: 23건 (CRITICAL: 2, HIGH: 5, MEDIUM: 16)
- 주요 이슈 한줄 요약 3개

---

[1. CRITICAL 이슈]
  1-1. [기사 제목]
       출처: Reuters | 게시일: 2026-03-25
       요약: ...
       시사점: ...
       원문 링크: ...

---

[2. 삼성 반도체 기술 이슈] (HIGH 이상)
  2-1. ...
  2-2. ...

[3. 경쟁사 채용 동향]
  3-1. TSMC - 미국 애리조나 공장 엔지니어 200명 추가 채용
  3-2. Intel - ...

[4. 반도체 업계 트렌드]
  4-1. ...

[5. 기타 참고 사항] (MEDIUM)
  5-1. ...

---
[통계]
- 사이트별 수집 현황
- 카테고리별 분포
- 크롤링 오류 사이트 목록
```

**출력 형식:** HTML 이메일 템플릿 (Jinja2 활용)

### 4.6 Email Sender (메일 발송 모듈)

**역할:** 생성된 리포트를 이메일로 발송

**요구사항:**
- SMTP 기반 메일 발송 (`smtplib` + `email.mime`)
- 수신자 목록 관리 (설정 파일에서 관리)
- HTML 형식 메일 본문
- 발송 실패 시 재시도 (최대 3회)
- 발송 이력 로깅

**설정:**
```yaml
email:
  smtp_host: "smtp.company.com"
  smtp_port: 587
  use_tls: true
  sender: "semiconductor-report@company.com"
  sender_name: "반도체 Daily Report"
  recipients:
    - "team-lead@company.com"
    - "analyst@company.com"
  cc:
    - "manager@company.com"
  send_time: "08:00"  # 매일 오전 8시 발송
  subject_template: "[반도체 Daily] {date} - {critical_count}건 긴급, {high_count}건 주요"
```

---

## 5. 데이터 저장소

### 5.1 Database 스키마 (SQLite / PostgreSQL)

```sql
-- 크롤링된 기사 원본
CREATE TABLE articles (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    source          VARCHAR(100) NOT NULL,
    url             VARCHAR(500) UNIQUE NOT NULL,
    title           VARCHAR(500) NOT NULL,
    content         TEXT,
    author          VARCHAR(200),
    language        VARCHAR(10),
    published_at    TIMESTAMP,
    crawled_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- LLM 분석 결과
CREATE TABLE analysis_results (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    article_id      INTEGER REFERENCES articles(id),
    relevance       VARCHAR(10),     -- HIGH/MEDIUM/LOW/NONE
    category        VARCHAR(50),     -- 카테고리
    importance      VARCHAR(10),     -- CRITICAL/HIGH/MEDIUM/LOW
    summary_ko      TEXT,            -- 한국어 요약
    implication     TEXT,            -- 삼성 관점 시사점
    keywords        TEXT,            -- JSON array
    analyzed_at     TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    model_used      VARCHAR(50),     -- 사용된 LLM 모델명
    token_used      INTEGER          -- 사용 토큰 수
);

-- 리포트 발송 이력
CREATE TABLE report_logs (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    report_date     DATE NOT NULL,
    total_articles  INTEGER,
    relevant_articles INTEGER,
    report_html     TEXT,
    sent_at         TIMESTAMP,
    send_status     VARCHAR(20),     -- SUCCESS/FAILED
    error_message   TEXT
);

-- 크롤링 실행 로그
CREATE TABLE crawl_logs (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    site_name       VARCHAR(100),
    started_at      TIMESTAMP,
    finished_at     TIMESTAMP,
    status          VARCHAR(20),     -- SUCCESS/FAILED/PARTIAL
    articles_found  INTEGER,
    error_message   TEXT
);

-- 크롤링 사이트 변경 이력
CREATE TABLE site_change_logs (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    action          VARCHAR(20),     -- ADD/REMOVE/UPDATE/DISABLE/ENABLE
    site_name       VARCHAR(100),
    site_url        VARCHAR(500),
    changed_by      VARCHAR(100),
    changed_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    details         TEXT             -- 변경 상세 내용 (JSON)
);

-- 주간 사이트 추천 이력
CREATE TABLE site_recommendations (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    recommended_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    site_name       VARCHAR(100),
    site_url        VARCHAR(500),
    relevance_score FLOAT,           -- 반도체 관련도 (0.0-1.0)
    quality_score   FLOAT,           -- 콘텐츠 품질 점수
    crawlable       BOOLEAN,         -- 크롤링 가능 여부
    recommendation  TEXT,            -- 추천 사유
    admin_action    VARCHAR(20),     -- APPROVED/REJECTED/PENDING
    actioned_at     TIMESTAMP
);

-- LLM 사용량 추적 (Provider별)
CREATE TABLE llm_usage_logs (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    provider        VARCHAR(50),     -- openai/anthropic/google/custom
    model           VARCHAR(100),
    analysis_step   VARCHAR(50),     -- relevance/categorization/importance/summary
    input_tokens    INTEGER,
    output_tokens   INTEGER,
    cost_usd        FLOAT,
    used_at         TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 프롬프트 정확도 추적
CREATE TABLE prompt_accuracy_logs (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    prompt_version  VARCHAR(20),
    analysis_step   VARCHAR(50),
    total_analyzed  INTEGER,
    correct_count   INTEGER,         -- 관리자 검증 기준
    accuracy_rate   FLOAT,
    evaluated_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    notes           TEXT
);
```

---

## 6. 기술 스택

| 구분 | 기술 | 비고 |
|------|------|------|
| 언어 | Python 3.11+ | |
| 웹 크롤링 | `requests`, `BeautifulSoup4`, `Playwright` | 정적/동적 페이지 대응 |
| RSS 파싱 | `feedparser` | RSS/Atom 피드 |
| 본문 추출 | `trafilatura`, `newspaper3k` | HTML → 순수 텍스트 |
| LLM | OpenAI / Anthropic / Google / 사내 Custom API (선택 가능) | 멀티 Provider 지원 |
| DB | SQLite (초기) → PostgreSQL (확장 시) | |
| ORM | SQLAlchemy | DB 추상화 |
| 스케줄러 | APScheduler / Linux Cron | 크롤링 및 리포트 스케줄 |
| 메일 발송 | `smtplib` + Jinja2 | HTML 템플릿 메일 |
| 설정 관리 | PyYAML | YAML 기반 설정 |
| 로깅 | Python `logging` + `loguru` | 구조화 로깅 |
| 테스트 | `pytest` | 단위/통합 테스트 |

---

## 7. 프로젝트 디렉토리 구조

```
project/
├── config/
│   ├── crawl_sites.yaml        # 크롤링 대상 사이트 마스터 리스트 (관리자 편집)
│   ├── sites.yaml              # 크롤링 스케줄/세부 설정
│   ├── keywords.yaml           # 검색 키워드 설정
│   ├── email.yaml              # 메일 발송 설정
│   └── llm.yaml                # LLM Provider 및 모델 설정 (멀티 LLM)
├── prompts/                    # 프롬프트 템플릿 (버전 관리)
│   ├── v1/
│   │   ├── relevance.txt       # 관련성 판단 프롬프트
│   │   ├── categorization.txt  # 카테고리 분류 프롬프트
│   │   ├── importance.txt      # 중요도 평가 프롬프트
│   │   └── summary.txt         # 요약 생성 프롬프트
│   └── prompt_config.yaml      # 활성 프롬프트 버전 설정
├── src/
│   ├── __init__.py
│   ├── main.py                 # 엔트리포인트
│   ├── manage.py               # 관리 CLI (사이트 관리, 상태 확인 등)
│   ├── crawler/
│   │   ├── __init__.py
│   │   ├── manager.py          # CrawlerManager
│   │   ├── site_list_manager.py # 사이트 리스트 파일 관리 + 변경 감지
│   │   ├── base.py             # BaseCrawler
│   │   ├── rss_crawler.py      # RSS 크롤러
│   │   ├── html_crawler.py     # HTML 파싱 크롤러
│   │   ├── api_crawler.py      # API 기반 크롤러
│   │   └── dynamic_crawler.py  # JS 렌더링 크롤러
│   ├── preprocessor/
│   │   ├── __init__.py
│   │   ├── dedup.py            # 중복 제거
│   │   ├── extractor.py        # 본문 추출
│   │   └── filter.py           # 키워드 필터링
│   ├── analyzer/
│   │   ├── __init__.py
│   │   ├── llm_router.py       # LLM Provider 라우터 (멀티 LLM 지원)
│   │   ├── llm_client.py       # LLM API 클라이언트 (Provider별 어댑터)
│   │   ├── prompts.py          # 프롬프트 로더 (파일 기반, 버전 관리)
│   │   ├── analyzer.py         # 분석 로직 (CoT, Few-Shot 적용)
│   │   └── quality_checker.py  # 분석 결과 품질 검증 (Guardrails)
│   ├── recommender/
│   │   ├── __init__.py
│   │   ├── site_discoverer.py  # 신규 사이트 탐색 (주간)
│   │   ├── site_evaluator.py   # 사이트 품질 평가
│   │   └── recommendation.py   # 추천 리포트 생성
│   ├── reporter/
│   │   ├── __init__.py
│   │   ├── generator.py        # 리포트 생성
│   │   └── templates/
│   │       ├── daily_report.html      # 일일 리포트 메일 템플릿
│   │       └── site_recommendation.html # 주간 사이트 추천 메일 템플릿
│   ├── notifier/
│   │   ├── __init__.py
│   │   └── email_sender.py     # 메일 발송
│   ├── storage/
│   │   ├── __init__.py
│   │   ├── models.py           # SQLAlchemy 모델
│   │   └── database.py         # DB 연결/세션 관리
│   └── utils/
│       ├── __init__.py
│       ├── logger.py           # 로깅 설정
│       └── health_check.py     # 시스템 헬스체크
├── tests/
│   ├── test_crawler/
│   ├── test_preprocessor/
│   ├── test_analyzer/
│   ├── test_recommender/
│   └── test_reporter/
├── requirements.txt
├── .env                        # API 키 등 시크릿 (git 미포함)
├── .gitignore
└── README.md
```

---

## 8. 실행 흐름 (Daily Pipeline)

```
06:00  [1단계] 크롤링 시작
         ├── 각 사이트별 크롤러 병렬 실행 (asyncio / ThreadPool)
         ├── 수집된 기사 DB 저장
         └── 크롤링 로그 기록

06:30  [2단계] 전처리
         ├── 중복 제거
         ├── 본문 추출 및 정제
         └── 키워드 1차 필터링

07:00  [3단계] LLM 분석
         ├── 필터링 통과 기사 배치 분석
         ├── 관련성/카테고리/중요도 판단
         ├── 한국어 요약 생성
         └── 분석 결과 DB 저장

07:30  [4단계] 리포트 생성
         ├── 분석 결과 집계
         ├── HTML 리포트 렌더링
         └── 리포트 DB 저장

08:00  [5단계] 메일 발송
         ├── 수신자 목록 조회
         ├── 이메일 발송
         └── 발송 결과 로깅

===== 주간 파이프라인 (매주 월요일) =====

09:00  [주간 1단계] 신규 사이트 탐색
         ├── 기존 기사에서 외부 인용 소스 URL 추출
         ├── 검색엔진 API로 반도체 관련 신규 미디어/블로그 탐색
         └── 후보 사이트 목록 생성

10:00  [주간 2단계] 사이트 품질 평가
         ├── 후보 사이트 콘텐츠 샘플링 + LLM 품질 평가
         ├── 기존 사이트 상태 점검 (접근성, 콘텐츠 품질)
         └── 평가 결과 DB 저장

11:00  [주간 3단계] 추천 리포트 발송
         ├── 신규 추천 사이트 + 기존 사이트 상태 리포트 생성
         ├── 관리자에게 이메일 발송
         └── 관리자 승인 대기
```

---

## 9. 예외 처리 및 안정성

| 상황 | 처리 방안 |
|------|----------|
| 크롤링 대상 사이트 접속 불가 | 재시도 3회 → 실패 로그 기록, 해당 사이트 건너뛰고 나머지 진행 |
| 크롤링 차단 (403/429) | User-Agent 로테이션, 요청 간격 증가, 프록시 사용 고려 |
| LLM API 장애 | 재시도 3회 → Fallback 체인에 따라 대체 Provider로 자동 전환 → 전체 실패 시 미분석 기사로 표시 |
| LLM 비용 초과 | Provider별 일일 토큰 상한 도달 시 저비용 모델로 자동 전환, 전체 상한 시 미분석 기사 목록만 리포트에 포함 |
| 사이트 리스트 파일 오류 | YAML 파싱 실패 시 이전 유효 버전으로 롤백, 관리자에게 오류 알림 |
| 메일 발송 실패 | 재시도 3회 → 실패 시 리포트를 로컬 파일로 저장, 관리자에게 알림 |
| DB 장애 | 크롤링 결과를 임시 JSON 파일로 저장, DB 복구 후 적재 |

---

## 10. 모니터링 및 운영

### 10.1 일상 모니터링
- **일일 크롤링 성공률** 모니터링 (사이트별)
- **LLM Provider별 토큰 사용량** 일별 추적 및 비용 대시보드
- **메일 발송 성공 여부** 확인
- **로그 보관**: 최근 30일 상세 로그, 이후 요약 로그만 보관

### 10.2 품질 관리
- **크롤링 품질 검증**: 주 1회 수동으로 누락/오분류 기사 샘플링 검토
- **프롬프트 정확도 추적**: 프롬프트 버전별 분석 정확도(관련성 판단, 카테고리 분류) 기록
- **LLM 분석 결과 피드백 루프**: 관리자가 오분류 기사를 표시 → Few-Shot 예시로 축적 → 프롬프트 개선
- **Self-Consistency 통계**: CRITICAL 판정 시 3회 호출 일치율 추적

### 10.3 운영 자동화
- **헬스체크 엔드포인트**: 크롤러/DB/LLM API 상태를 주기적으로 확인
- **자동 알림**: 크롤링 실패율 > 30% 또는 LLM API 장애 시 관리자에게 즉시 알림 (Slack/이메일)
- **사이트 리스트 변경 감지**: `config/crawl_sites.yaml` 파일 변경 시 자동 반영 + 관리자 확인 알림
- **주간 사이트 추천 자동 실행**: 매주 월요일 새로운 크롤링 대상 사이트 탐색 및 추천 리포트 발송
- **LLM Fallback 자동 전환**: 1차 Provider 장애 시 설정된 fallback 체인에 따라 자동 전환 + 관리자 알림

### 10.4 비용 관리
- **Provider별 비용 추적**: 각 LLM Provider의 일별/월별 사용량 및 예상 비용 집계
- **비용 최적화 리포트**: 월 1회 모델별 비용 대비 정확도 분석 → 최적 모델 조합 추천
- **예산 상한 알림**: 월 예산의 80% 도달 시 관리자에게 알림, 100% 도달 시 저비용 모델로 자동 전환

---

## 11. 구현 단계 (Phase)

### Phase 1: MVP (1-2주)
- [ ] 프로젝트 구조 셋업 및 설정 파일 구성
- [ ] 크롤링 사이트 리스트 파일(`config/crawl_sites.yaml`) 설계 및 초기 데이터 구성
- [ ] RSS 크롤러 구현 (3-5개 주요 사이트)
- [ ] 기본 전처리 (중복 제거, 본문 추출)
- [ ] LLM 멀티 Provider 라우터 구현 (OpenAI + Anthropic 우선 지원)
- [ ] CoT + Few-Shot 기반 프롬프트 v1 작성 (관련성 판단 + 요약)
- [ ] 텍스트 기반 리포트 생성
- [ ] 이메일 발송 기본 기능
- [ ] SQLite DB 연동

### Phase 2: 확장 (2-3주)
- [ ] HTML 파싱 크롤러 추가 (한국 미디어 등)
- [ ] 채용 플랫폼 크롤러 추가
- [ ] Google Gemini / 사내 Custom API Provider 추가
- [ ] LLM 분석 고도화 (카테고리 세분화, 중요도 평가, Self-Consistency)
- [ ] 분석 품질 검증 모듈 (Guardrails) 구현
- [ ] 사이트 리스트 관리 CLI 구현 (추가/삭제/조회/내보내기)
- [ ] 사이트 리스트 파일 변경 감지 및 자동 반영
- [ ] HTML 이메일 템플릿 적용
- [ ] 크롤링 병렬 처리 (asyncio)
- [ ] 크롤링/분석 로그 대시보드

### Phase 3: 고도화 (3-4주)
- [ ] Dynamic Crawler 추가 (Playwright)
- [ ] Reddit/Twitter API 연동
- [ ] 주간 신규 크롤링 사이트 자동 추천 기능 구현
- [ ] 프롬프트 버전 관리 및 정확도 추적 시스템
- [ ] 관리자 피드백 → Few-Shot 예시 축적 파이프라인
- [ ] 주간/월간 트렌드 분석 리포트
- [ ] 키워드 알림 (CRITICAL 이슈 즉시 알림)
- [ ] LLM 비용 최적화 대시보드 (Provider별 비용/정확도 분석)
- [ ] PostgreSQL 마이그레이션
- [ ] 웹 대시보드 (Flask/FastAPI + 간단한 UI)
- [ ] 헬스체크 및 자동 장애 알림 시스템

---

## 12. 보안 및 법적 고려사항

- **API 키 관리**: `.env` 파일에 저장, 절대 코드에 하드코딩 금지
- **크롤링 윤리**: `robots.txt` 준수, 과도한 요청 지양
- **저작권**: 크롤링된 원문 전체 저장 시 저작권 이슈 → 요약본만 리포트에 포함, 원문은 링크 제공
- **개인정보**: 채용 공고 크롤링 시 개인정보 수집 최소화
- **사내 보안**: 사내 메일 시스템 연동 시 보안 정책 확인 필요
