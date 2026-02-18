include .env
export

STACK_NAME  = bondoro
REGION      = ap-northeast-1
ALERT_EMAIL ?= nwebcraft@gmail.com

.PHONY: build deploy test

build:
	sam build

deploy: build
	sam deploy \
	  --stack-name $(STACK_NAME) \
	  --region $(REGION) \
	  --capabilities CAPABILITY_IAM \
	  --resolve-s3 \
	  --no-confirm-changeset \
	  --parameter-overrides \
	    LineChannelSecret='$(LINE_CHANNEL_SECRET)' \
	    LineChannelAccessToken='$(LINE_CHANNEL_ACCESS_TOKEN)' \
	    RakutenAppId='$(RAKUTEN_APP_ID)' \
	    RakutenAccessKey='$(RAKUTEN_ACCESS_KEY)' \
	    YahooAppId='$(YAHOO_APP_ID)' \
	    AlertEmail='$(ALERT_EMAIL)'

test:
	bundle exec rspec
