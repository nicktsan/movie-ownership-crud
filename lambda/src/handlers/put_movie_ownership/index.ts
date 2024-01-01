import { EventBridgeEvent, EventBridgeHandler } from "aws-lambda";
import Stripe from "stripe";
import { getStripe, getClient, getDocClient, verifyEventAsync, fulfillOrder } from "/opt/nodejs/utils";
import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { DynamoDBDocumentClient } from "@aws-sdk/lib-dynamodb";


let stripe: Stripe | null;
let client: DynamoDBClient | null;
let docClient: DynamoDBDocumentClient | null;

const handler: EventBridgeHandler<any, any, any> = async (event: EventBridgeEvent<any, any>): Promise<void> => {
    //initialize a new Stripe instance if there is none.
    stripe = await getStripe(stripe);
    client = await getClient(client);
    docClient = await getDocClient(client, docClient)
    console.log("EventbridgeEvent:")
    console.log(event)
    const eventVerification = await verifyEventAsync(event, stripe);
    if (!stripe) {
        console.info("stripe is null. Nothing processed.")
    } else if (!eventVerification.isVerified) {
        console.log("Failed eventbridge event verified")
    } else {
        console.log("Successful eventbridge event verified")
        // Handle the checkout.session.completed event

        // Retrieve the session. If you require line items in the response, you may include them by expanding line_items.
        const myConstructedEventObject: any = eventVerification.constructedEvent?.data.object
        const myConstructedEventObjectId = myConstructedEventObject.id

        console.log("myConstructedEventObjectId", myConstructedEventObjectId)
        const sessionWithLineItems = await stripe?.checkout.sessions.retrieve(
            myConstructedEventObjectId,
            {
                expand
                    : ['line_items'],
            }
        );
        const lineItems = sessionWithLineItems.line_items;
        // console.log("lineItems?.data[0].price", lineItems?.data[0].price)
        // lineItems?.data.forEach(lineItemdata => {
        // Fulfill the purchase...
        const ownershipDetails = await fulfillOrder(lineItems!.data[0]/*, stripe*/, event, docClient);

        // });

    }
}

export { handler }