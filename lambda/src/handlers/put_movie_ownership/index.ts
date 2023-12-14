import { EventBridgeEvent, EventBridgeHandler/*, Context, Callback*/ } from "aws-lambda";
import Stripe from "stripe";
import { getStripe, verifyMessageAsync } from "/opt/nodejs/utils";

let stripe: Stripe | null;
const handler: EventBridgeHandler<any, any, any> = async (event: EventBridgeEvent<any, any>): Promise<void> => {
    stripe = await getStripe(stripe);
    console.log("EventbridgeEvent:")
    console.log(event)
    const verified = await verifyMessageAsync(event, stripe);
    if (!verified) {
        console.log("Failed eventbridge event verified")
    } else {
        console.log("Successful eventbridge event verified")
    }
}

export { handler }