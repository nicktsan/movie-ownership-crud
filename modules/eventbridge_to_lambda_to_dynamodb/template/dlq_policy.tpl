{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sqs:SendMessage",
            "Effect": "Allow",
            "Resource": "${dlqArn}",
            "Principal": {
                "Service": "events.amazonaws.com"
            },
            "Condition": {
                "ArnEquals": {
                "aws:SourceArn": "${eventRuleArn}"
                }
            }
        }
    ]
}