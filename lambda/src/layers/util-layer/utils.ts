import { EventBridgeEvent /*, Context, Callback*/ } from "aws-lambda";
import Stripe from "stripe";

//An interface for the purposes of returning both a boolean and a Stripe.Event for verifyEventAsync
interface TEventVerification {
    isVerified: boolean,
    constructedEvent: Stripe.Event | undefined
}

const getStripe = async (stripe: Stripe | null): Promise<Stripe | null> => {
    //if no stripe instance, instantiate a new stripe instance. Otherwise, return the existing stripe instance without
    //instantiating a new one.
    if (!stripe) {
        stripe = new Stripe(process.env.STRIPE_SECRET!, {
            apiVersion: '2023-10-16',
        });
        // console.log("Instantiated a new Stripe object.")
    } else {
        // console.log("Found an existing Stripe object instance.")
    }
    return stripe;
};

//Ensures the event is a genuine stripe event
async function verifyEventAsync(event: EventBridgeEvent<any, any>, stripe: Stripe | null): Promise<TEventVerification> {
    const payload = event.detail.data;
    const sig = event.detail.stripeSignature
    console.log('stripe signature ', sig);
    console.log(`Processed event ${payload}`);
    //Initialize a new TEventVerification with default values
    const eventVerification: TEventVerification = {
        isVerified: false,
        constructedEvent: undefined
    };
    try {
        //Use Stripe's constructEvent method to verify the event
        eventVerification.constructedEvent = stripe?.webhooks.constructEvent(payload, sig!, process.env.STRIPE_SIGNING_SECRET!);
        eventVerification.isVerified = true;
    } catch (err: unknown) {
        if (err instanceof Error) {
            console.error(`Webhook Error: ${err.message}`);
        }
    }
    return eventVerification
}

//To insert a record into the ownership table, we need the following information:
// Customer email <- unique key. Retrievable via event.detail.data, where event is an EventBridgeEvent<any, any> object
// Movie Title <- unique key. Retreivable via lineItemdata.price.metadata or through lineItemdata.price.product lookup.
// Type of purchase (rent or buy) and rent duration if it is a rented movie. Retrievable via lineItemdata.price.nickname
// Time and date of purchase retrievable via event.detail.data.data.object.created. 
function fulfillOrder(lineItemdata: Stripe.LineItem/*, stripe: Stripe | null*/, event: EventBridgeEvent<any, any>): void {
    console.log("lineItemdata.price: ", lineItemdata.price)
    //Get customer email <- unique key
    const eventDetailData = JSON.parse(event.detail.data)
    console.log("event.detail.data: ", eventDetailData)
    const email = eventDetailData.data.object.customer_details.email
    console.log("customer email: ", email)
    //Get movie title
    const title = lineItemdata.price?.metadata.name
    console.log("Movie title: ", title)
    //Get purchase type
    const purchaseType = lineItemdata.price?.nickname
    console.log("purchase type: ", purchaseType)
    //Get time and date of purchase
    const purchaseDateEpoch = eventDetailData.data.object.created
    console.log("purchase date (unix epoch): ", purchaseDateEpoch)
    return
}


export { TEventVerification, getStripe, verifyEventAsync, fulfillOrder }