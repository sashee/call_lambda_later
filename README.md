# Call a Lambda function with a delay

## Requirements

* Terraform
* AWS account
* AWS CLI configured

## Install

* ```terraform init```
* ```terraform apply```

## Use

### Call the relative scheduler

```aws stepfunctions start-execution --state-machine-arn $(terraform output -raw delayer_arn) --input '{"delay_seconds": 5, "test":"value"}'```

![image](https://user-images.githubusercontent.com/82075/148751152-d6fbf5c8-8f87-4353-beb4-cef73231c07d.png)

![image](https://user-images.githubusercontent.com/82075/148751320-875be5b1-d3a9-4605-a118-6f11a27a0d94.png)

The lambda is called with the arguments:

![image](https://user-images.githubusercontent.com/82075/148751227-6b583cc4-0738-4421-bc92-d020a0a993d7.png)

### Call the absolute scheduler

```aws stepfunctions start-execution --state-machine-arn $(terraform output -raw scheduler_arn) --input "{\"at\": \"$(TZ='UTC' date --date="10 seconds" +"%Y-%m-%dT%H:%M:%SZ")\", \"test\":\"value\"}"```

![image](https://user-images.githubusercontent.com/82075/148751403-f0aaebfd-1aff-425d-a9e7-e0939b0f099b.png)

![image](https://user-images.githubusercontent.com/82075/148751441-5bbd0006-7623-4601-85bf-deb5ec3e9cb2.png)

## Cleanup

* ```terraform destroy```
