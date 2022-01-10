# Call a Lambda function with a delay

## Requirements

* Terraform
* AWS account
* AWS CLI configured

## Install

* ```terraform init```
* ```terraform apply```

## Use

* Use the relative scheduler: ```aws stepfunctions start-execution --state-machine-arn $(terraform output -raw delayer_arn) --input '{"delay_seconds": 5, "test":"value"}'```

* Use the absolute scheduler: ```aws stepfunctions start-execution --state-machine-arn $(terraform output -raw scheduler_arn) --input "{\"at\": \"$(TZ='UTC' date --date="10 seconds" +"%Y-%m-%dT%H:%M:%SZ")\", \"test\":\"value\"}"```

## Cleanup

* ```terraform destroy```
