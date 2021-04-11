### creating iam role for lambda execution
# ref: https://docs.aws.amazon.com/lambda/latest/dg/lambda-intro-execution-role.html
LAMBDA_POLICY:=$(shell cat aws_res/lambda_policy.json|\
	sed 's|ARN|$(UPLOAD_BUCKET_ARN)|'|tr -d '\t')
LAMBDA_CLOUDWATCH_POLICY_ARN:=arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole
LAMBDA_ROLE_ARN:=arn:aws:iam::$(AWS_ID):role/$(LAMBDA_ROLE)

.PHONY:
lambda-iam-create:
	-$(AWS) iam create-role \
		--role-name $(LAMBDA_ROLE) \
		--assume-role-policy-document '$(LAMBDA_POLICY)'|jq .

	@# allow lambda access upload bucket
	-$(AWS) iam attach-role-policy \
		--role-name $(LAMBDA_ROLE) \
		--policy-arn $(UPLOAD_BUCKET_POLICY_ARN)|jq .

	@# enable logging to cloudwatch
	-$(AWS) iam attach-role-policy \
		--role-name $(LAMBDA_ROLE) \
		--policy-arn $(LAMBDA_CLOUDWATCH_POLICY_ARN)|jq .

.PHONY:
lambda-iam-delete:
	-$(AWS) iam detach-role-policy \
		--role-name $(LAMBDA_ROLE) \
		--policy-arn $(UPLOAD_BUCKET_POLICY_ARN)
	-$(AWS) iam detach-role-policy \
		--role-name $(LAMBDA_ROLE) \
		--policy-arn $(LAMBDA_CLOUDWATCH_POLICY_ARN)
	-$(AWS) iam delete-role \
		--role $(LAMBDA_ROLE)
