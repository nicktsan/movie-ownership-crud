import { EventBridgeEvent /*, Context, Callback*/ } from "aws-lambda";
import Stripe from "stripe";

//An interface for the purposes of returning both a boolean and a Stripe.Event for verifyMessageAsync
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

//Ensures the message is a genuine stripe message
async function verifyMessageAsync(message: EventBridgeEvent<any, any>, stripe: Stripe | null): Promise<TEventVerification> {
    const payload = message.detail.data;
    const sig = message.detail.stripeSignature
    console.log('stripe signature ', sig);
    console.log(`Processed message ${payload}`);
    //Initialize a new TEventVerification with default values
    const eventVerification: TEventVerification = {
        isVerified: false,
        constructedEvent: undefined
    };
    try {
        //Use Stripe's constructEvent method to verify the message
        eventVerification.constructedEvent = stripe?.webhooks.constructEvent(payload, sig!, process.env.STRIPE_SIGNING_SECRET!);
        eventVerification.isVerified = true;
    } catch (err: unknown) {
        if (err instanceof Error) {
            console.error(`Webhook Error: ${err.message}`);
        }
    }
    return eventVerification
}

export { TEventVerification, getStripe, verifyMessageAsync }