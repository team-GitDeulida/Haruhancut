.DEFAULT_GOAL := all

# Privates 파일 다운로드
Private_Repository=team-GitDeulida/Haruhancut-Private/main
BASE_URL=https://raw.githubusercontent.com/$(Private_Repository)
    
define download_file
	mkdir -p $(1)
	curl -H "Authorization: token $(2)" -o $(1)/$(3) $(BASE_URL)/$(1)/$(3)
endef

download-privates:

	# Get GitHub Access Token
	@if [ ! -f .env ]; then \
		read -p "Enter your GitHub access token: " token; \
		echo "GITHUB_ACCESS_TOKEN=$$token" > .env; \
	else \
		/bin/bash -c "source .env; make _download-privates"; \
		exit 0; \
	fi
	
	make _download-privates

_download-privates:

	# .env 파일에서 GITHUB_ACCESS_TOKEN 읽기
	$(eval export $(shell cat .env))

	# fastlane/.env 파일 다운로드
	$(call download_file,fastlane,$$GITHUB_ACCESS_TOKEN,.env)

	# 최상위 디렉토리에 test.txt 다운로드
	$(call download_file,.,$$GITHUB_ACCESS_TOKEN,test.txt)

# -------------------------
# Homebrew 설치 확인 및 설치
# -------------------------

install_homebrew:
	@if ! command -v brew >/dev/null 2>&1; then \
		echo "Homebrew가 설치되어 있지 않습니다. 설치를 진행합니다..."; \
		/bin/bash -c "$$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; \
	else \
		echo "Homebrew가 이미 설치되어 있습니다."; \
	fi

# -------------------------
# fastlane 및 인증서 관련 작업
# -------------------------

# Automatically manage signing 체크 해제해야함!!
# Homebrew로 fastlane 설치 (설치되어 있으면 업데이트)
install_fastlane: install_homebrew
	@echo "Updating Homebrew..."
	@brew update
	@echo "Installing fastlane via Homebrew..."
	@brew install fastlane || true
	@echo "✅ fastlane 설치 완료 (Homebrew 사용)"

# 최초 한번은 직접 실행
# fastlane match appstore --app_identifier "com.indextrown.Haruhancut.WidgetExtension"
# fastlane match development --app_identifier "com.indextrown.Haruhancut.WidgetExtension"

# 만약 기능 추가시
# fastlane match development --force
# fastlane match appstore --force   

# 인증서 다운로드 (readonly 모드)
# @fastlane match development --readonly false
# @fastlane match appstore --readonly false
fetch_certs: install_fastlane
	@echo "Fetching development certificates..."
	@fastlane match development --readonly 
	@fastlane match development --app_identifier "com.indextrown.Haruhancut.WidgetExtension" --readonly
	@echo "Fetching appstore certificates..."
	@fastlane match appstore --readonly 
	@fastlane match appstore --app_identifier "com.indextrown.Haruhancut.WidgetExtension" --readonly
	@echo "✅ 인증서 가져오기 완료"

# -------------------------
# 통합 기본 타겟: 필요한 경우 Private 파일과 인증서 모두 다운로드
# -------------------------
all: download-privates fetch_certs
	@echo "✅ 모든 작업 완료"



# -------------------------
# 에러 발생시 아래 코드 실행(권한 포함해 새로 생성·갱신하는 명령)
# rovisioning profile "match AppStore com.indextrown.Haruhancut.WidgetExtension" doesn't support the group.com.indextrown.Haruhancut.WidgetExtension App Group.
# -------------------------

# bundle exec fastlane match development \
#   --app_identifier "com.indextrown.Haruhancut.WidgetExtension" \
#   --force_for_new_certificates \
#   --include_all_certificates

# bundle exec fastlane match appstore \
#   --app_identifier "com.indextrown.Haruhancut.WidgetExtension" \
#   --force_for_new_certificates \
#   --include_all_certificates

