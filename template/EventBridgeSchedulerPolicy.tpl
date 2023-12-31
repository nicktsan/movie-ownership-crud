{
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "EventbridgeSchedulerPutEvents",
        "Action" : [
          "events:putEvents",
          "sqs:SendMessage"
        ],
        "Effect" : "Allow",
        "Resource" : "*"
      }
    ]
  }