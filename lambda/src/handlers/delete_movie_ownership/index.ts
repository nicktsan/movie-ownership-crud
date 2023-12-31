import { Handler } from 'aws-lambda';

// Lambda for deleting ownership records. Should be activated from event scheduler
export const handler: Handler = async (event, context) => {
    console.log('Event from Scheduler: \n' + JSON.stringify(event, null, 2));

};

// Implement aws_sqs_queue_redrive_policy so the scheduler can send failed events to a DLQ.
// (The redrive policy specifies the source queue, the dead-letter queue, and the conditions under
// which Amazon SQS moves messages from the former to the latter if the consumer of the source queue
// fails to process a message a specified number of times)