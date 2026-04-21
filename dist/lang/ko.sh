# shellcheck shell=bash
# Quickstart-PC Language Pack: ko (Korean)

HELP_TITLE="Quickstart-PC - 원클릭 PC 설정"
HELP_USAGE="사용법: quickstart.sh [옵션]"
HELP_OPTIONS=""
read -r -d '' HELP_OPTIONS << 'OPTIONS_EOF'
옵션:
  --lang LANG        언어 설정 (en, zh, zh-Hant, ja, ko, de, fr, ar, pt, it)
  --local-lang PATH  로컬 언어 스크립트 폴더 사용
  --cfg-path PATH    로컬 profiles.json 사용
  --cfg-url URL      원격 profiles.json URL 사용
  --dev              개발 모드: 선택한 소프트웨어 표시但不설치
  --dry-run          미리보기 모드: 설치 과정 표시하지만 실제 설치하지 않음
  --doctor QC Doctor 환경 진단 실행
  --yes, -y          모든 프롬프트에 자동 동의
  --verbose, -v     詳細な 디버그 정보 표시
  --log-file FILE    로그를 파일에 쓰기
  --export-plan FILE 설치 계획 내보내기
  --custom           사용자 정의 소프트웨어 선택 모드
  --retry-failed     이전에 실패한 패키지 재시도
  --list-software    사용 가능한 모든 소프트웨어 나열
  --show-software ID 지정한 소프트웨어 상세 정보 표시
  --search KEYWORD   소프트웨어 검색
  --validate         구성 파일 검증
  --report-json FILE JSON 형식으로 설치 보고서 내보내기
  --report-txt FILE  TXT 형식으로 설치 보고서 내보내기
  --list-profiles     사용 가능한 모든 프로필 나열
  --show-profile KEY 지정한 프로필 상세 정보 표시
  --skip SW          지정한 소프트웨어 건너뛰기 (반복 가능)
  --only SW          지정한 소프트웨어만 설치 (반복 가능)
  --fail-fast        첫 번째 오류에서 중지
  --profile NAME     프로필 직접 선택 (메뉴 건너뛰기)
  --non-interactive  비대화형 모드 (TUI/프롬프트 모두 비활성화)
  --help             이 도움말 표시
OPTIONS_EOF

LANG_BANNER_TITLE="Quickstart-PC v__VERSION__"
LANG_BANNER_DESC="새 PC 소프트웨어 환경을 빠르게 설정"
LANG_DETECTING_SYSTEM="시스템 환경 감지 중..."
LANG_SYSTEM_INFO="시스템"
LANG_PACKAGE_MANAGER="패키지 관리자"
LANG_UNSUPPORTED_OS="지원되지 않는 OS"
LANG_USING_REMOTE_CONFIG="원격 구성 사용"
LANG_USING_CUSTOM_CONFIG="로컬 구성 사용"
LANG_USING_DEFAULT_CONFIG="기본 구성 사용"
LANG_CONFIG_NOT_FOUND="구성 파일을 찾을 수 없습니다"
LANG_CONFIG_INVALID="구성 파일 형식이 유효하지 않습니다"
LANG_SELECT_PROFILES="설치 프로필 선택"
LANG_SELECT_SOFTWARE="설치할 소프트웨어 선택"
LANG_NAVIGATE="↑↓ 이동 | Enter 확인"
LANG_NAVIGATE_MULTI="↑↓ 이동 | 스페이스 선택 | Enter 확인"
LANG_SELECTED="[✓] "
LANG_NOT_SELECTED="[  ] "
LANG_SELECT_ALL="모두 선택"
LANG_BACK_TO_PROFILES="프로필 선택으로 돌아가기"
LANG_NO_PROFILE_SELECTED="프로필이 선택되지 않았습니다"
LANG_NO_SOFTWARE_SELECTED="소프트웨어가 선택되지 않았습니다"
LANG_CONFIRM_INSTALL="설치를 확인하시겠습니까? [Y/n]"
LANG_CANCELLED="취소됨"
LANG_START_INSTALLING="소프트웨어 설치 시작"
LANG_INSTALLING="설치 중"
LANG_INSTALL_SUCCESS="설치 완료"
LANG_INSTALL_FAILED="설치 실패"
LANG_PLATFORM_NOT_SUPPORTED="지원되지 않는 플랫폼"
LANG_INSTALLATION_COMPLETE="설치 완료"
LANG_TOTAL_INSTALLED="총 설치"
LANG_DEV_MODE="개발 모드: 선택한 소프트웨어 표시但不설치"
LANG_DRY_RUN_MODE="미리보기 모드: 설치 과정 표시하지만 실제 설치하지 않음"
LANG_DRY_RUN_INSTALLING="설치 시뮬레이션"
LANG_JQ_DETECTED="jq 감지됨, jq 사용"
LANG_JQ_NOT_FOUND="jq를 찾을 수 없습니다, 설치 중..."
LANG_JQ_INSTALLED="jq 설치 성공"
LANG_JQ_INSTALL_FAILED="jq 설치 실패, 대안 파서 시도..."
LANG_USING_PYTHON3="python3을 대안 파서로 사용"
LANG_NO_JSON_PARSER="사용 가능한 JSON 파서가 없습니다 (jq/python3)"
LANG_CHECKING_INSTALLATION="설치 상태 확인 중..."
LANG_SKIPPING_INSTALLED="이미 설치됨, 건너뛰기"
LANG_ALL_INSTALLED="모든 소프트웨어가 이미 설치됨, 작업 없음"
LANG_ASK_CONTINUE="설치 완료. 다른 프로필을 계속 설치하시겠습니까?"
LANG_CONTINUE="계속"
LANG_EXIT="종료"
LANG_TITLE_SELECT_PROFILE="프로필 선택"
LANG_TITLE_SELECT_SOFTWARE="소프트웨어 선택"
LANG_TITLE_INSTALLING="설치 중"
LANG_TITLE_ASK_CONTINUE="설치를 계속하시겠습니까?"
LANG_LANG_PROMPT="언어를 선택해 주세요"
LANG_LANG_MENU_ENTER="확인"
LANG_LANG_MENU_SPACE="선택"
LANG_NONINTERACTIVE_ERROR="비대화형 모드에서는 --profile 매개변수가 필요합니다"
LANG_PROFILE_NOT_FOUND="프로필 '$PROFILE_KEY'을(를) 찾을 수 없습니다"
LANG_NPM_NOT_FOUND="npm을 찾을 수 없습니다, 설치 중..."
LANG_WINGET_NOT_FOUND="winget을 찾을 수 없습니다, npm을 자동 설치할 수 없습니다"
LANG_NPM_AUTO="npm"
LANG_INSTALL_FAILED_LIST="다음 소프트웨어 설치 실패"
LANG_PROGRESS_INSTALLED="설치됨"
LANG_PROGRESS_TO_INSTALL="설치 예정"
LANG_TIME_SECONDS="초"
LANG_TIME_TOTAL="총 소요 시간"
