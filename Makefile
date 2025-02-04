### Scripts to set up the AWS infrastructure

################################################################################

### configurables
# anything in this section can be overridden with environment variables

# AWS configuration
AWS_REGION?=us-east-1
AWS_PROFILE?=default

# app configuration
# "ch" for convex-hull
APP_PREFIX?=ch

# build directory for all intermediate files
BUILDDIR?=target

# creating bucket for hosting website (note: has to be universally unique)
HOST_BUCKET_NAME?=$(APP_PREFIX)hostbucket
WEBSITE_SRCDIR?=src/$(APP_PREFIX)frontend
WEBSITE_DISTDIR?=src/$(APP_PREFIX)frontend/dist
WEBSITE_BUILD=npm run --prefix $(WEBSITE_SRCDIR) build

# creating upload bucket (note: has to be universally unique)
UPLOAD_BUCKET_NAME?=$(APP_PREFIX)uploadsbucket

# deploying lambdas

# lambda for presigning requests to S3
PRESIGN_LAMBDA_NAME?=$(APP_PREFIX)_presign
PRESIGN_LAMBDA_DESC?=Presigns GET/PUT requests
PRESIGN_LAMBDA_ROLE?=$(APP_PREFIX)_presign_role

CH_LAMBDA_NAME?=$(APP_PREFIX)_ch
CH_LAMBDA_DESC?=Computes convex hull

# compiling and packaging lambda
PRESIGN_GO_PACKAGE?=$(APP_PREFIX)presign
PRESIGN_GO_BINARY?=$(APP_PREFIX)presign

CH_GO_PACKAGE?=$(APP_PREFIX)hull
CH_GO_BINARY?=$(APP_PREFIX)hull

GO_SOURCES?=$(shell find src -name *.go)
GO_ENVVAR?=GOOS=linux GOARCH=amd64 CGO_ENABLED=0
GO_LDFLAGS?=-ldflags="-X main.awsRegion=$(AWS_REGION)\
	-X main.uploadBucketName=$(UPLOAD_BUCKET_NAME)"

# api gateway
API_NAME?=$(APP_PREFIX)_api
API_STAGE?=dev

# cognito user pool
USERPOOL_NAME?=$(APP_PREFIX)_userpool

################################################################################

### non-configurables
# everything past here is predetermined by the configurables; do not modify
AWS:=aws --region $(AWS_REGION) --profile $(AWS_PROFILE)
AWS_ID:=$(shell $(AWS) sts get-caller-identity|jq -r '.Account')

# ARN-generating macros
define ARN
arn:aws:$(1):$(AWS_REGION):$(AWS_ID):$(2)
endef
define S3ARN
arn:aws:s3:::$(1)
endef
define IAMARN
arn:aws:iam::$(AWS_ID):$(1)
endef

# macro to print command and save result in Makefile (cannot do natively afaik)
define ECHO_SAVE
@echo $(1)
$(eval JSON:=$(shell $(1)))
@echo '$(JSON)'|jq .
$(eval $(2):=$(shell echo '$(JSON)'|jq $(3)))
endef

################################################################################

### Main build targets
# see the component makefiles for additional targets and implementation details

.PHONY:
all: upload-bucket-create\
	upload-bucket-policy-create\
	lambda-iam-create\
	loggroup-create\
	lambda-create\
	api-create\
	build-website\
	host-bucket-create\
	host-bucket-sync

.PHONY:
clean: target-clean\
	api-delete\
	lambda-delete\
	loggroup-delete\
	lambda-iam-delete\
	upload-bucket-policy-delete\
	upload-bucket-delete\
	host-bucket-delete

-include scripts/host_bucket.mk
-include scripts/upload_bucket.mk
-include scripts/go_compile.mk
-include scripts/upload_bucket_policy.mk
-include scripts/lambda_iam.mk
-include scripts/lambda_deploy.mk
-include scripts/cloudwatch_loggroups.mk
-include scripts/apigateway.mk
-include scripts/cognito.mk