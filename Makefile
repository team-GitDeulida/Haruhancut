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