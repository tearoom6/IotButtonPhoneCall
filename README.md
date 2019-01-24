# IotButtonPhoneCall

## Features

Use AWS IoT Enterprise Button to make a programmable phone call.

- Single click -> make a phone call
- Double click -> stop the phone call
- Long press   -> toggle mute mode


## Setup

Gem `twilio-ruby` uses `nokogiri` which includes binary library.
So if you install them in macOS env, you cannot run the app in AWS Lambda runtime (which is based on Amazon Linux).

To avoid this problem, we need to install gems in Amazon Linux Docker container.

```sh
$ IMAGE_NAME="amazon-linux-ruby-2_5_3"
$ docker build -t $IMAGE_NAME .
$ docker run -it -v `pwd`:/src -w /src $IMAGE_NAME bundle install --deployment
```

Claim IoT Button device by following [Claiming Devices - AWS IoT 1-Click](https://docs.aws.amazon.com/iot-1-click/latest/developerguide/1click-claiming.html).

Then, setup resouces using CloudFormation:

```sh
S3_BUCKET="<BUCKET>"
FUNCTION_NAME="IotButtonPhoneCall"
STACK_NAME="IotButtonPhoneCall"
DSN="<IOT_BUTTON_DSN>"
TWILIO_ACCOUNT="<ACCOUNT_SID>"
TWILIO_TOKEN="<SECRET_TOKEN>"
TWILIO_TEL="<PURCHACED_PHONE>" # E.164 format
TARGET_TEL="<YOUR_PHONE>"      # E.164 format

# Package Lambda binary and upload it to S3 bucket.
aws cloudformation package \
  --template-file cloudformation-template.yml \
  --s3-bucket $S3_BUCKET \
  --s3-prefix "Lambda/$FUNCTION_NAME" \
  --output-template-file packaged-template.yml

# Deploy all resources in AWS. (Also create CloudFormation stack)
aws cloudformation deploy \
  --template-file packaged-template.yml \
  --stack-name $STACK_NAME \
  --capabilities CAPABILITY_IAM \
  --parameter-overrides "DeviceDsn=$DSN" "FunctionName=$FUNCTION_NAME" "TwilioAccount=$TWILIO_ACCOUNT" "TwilioToken=$TWILIO_TOKEN" "TwilioTel=$TWILIO_TEL" "TargetTel=$TARGET_TEL"

# Destroy all resources in AWS. (Also delete CloudFormation stack)
aws cloudformation delete-stack --stack-name $STACK_NAME
```

> References

- [How I Potty Trained My Kid Using Twilio and an AWS IoT Button - Twilio](https://www.twilio.com/blog/2018/03/iot-poop-button-python-twilio-aws.html)
- [Announcing Ruby Support for AWS Lambda | AWS Compute Blog](https://aws.amazon.com/blogs/compute/announcing-ruby-support-for-aws-lambda/)
- [AWS Lambda RubyでC拡張が入ったgemを使う - Qiita](https://qiita.com/masarakki/items/3e07ba53024b7100b179)

