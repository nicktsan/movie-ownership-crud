import { EventBridgeEvent, APIGatewayProxyEventV2 /*, Context, Callback*/ } from "aws-lambda";
import Stripe from "stripe";
import { DynamoDBClient, ConditionalCheckFailedException } from "@aws-sdk/client-dynamodb";
import { PutCommand, QueryCommand, QueryCommandOutput, DynamoDBDocumentClient } from "@aws-sdk/lib-dynamodb";

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
    }
    return stripe;
};

const getClient = async (client: DynamoDBClient | null): Promise<DynamoDBClient | null> => {
    //if no DynamoDBClient instance, instantiate a new DynamoDBClient instance. Otherwise, return the existing 
    //DynamoDBClient instance without instantiating a new one.
    if (!client) {
        client = new DynamoDBClient({});
        console.log("Instantiated a new DynamoDBClient object.")
    }
    return client;
};

const getDocClient = async (client: DynamoDBClient | null, docClient: DynamoDBDocumentClient | null): Promise<DynamoDBDocumentClient | null> => {
    //if no DynamoDBDocumentClient instance, instantiate a new DynamoDBDocumentClient instance. Otherwise, return the existing DynamoDBDocumentClient instance without
    //instantiating a new one.
    if (!docClient) {
        docClient = DynamoDBDocumentClient.from(client!);
        console.log("Instantiated a new DynamoDBDocumentClient object.")
    }
    return docClient;
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
    } catch (err) {
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
// Time and date of rental expiry.
async function fulfillOrder(lineItemdata: Stripe.LineItem, event: EventBridgeEvent<any, any>, docClient: DynamoDBDocumentClient | null): Promise<Record<string, any> | null> {
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
    const purchaseDateEpochSeconds = eventDetailData.data.object.created
    console.log("purchase date (unix epoch): ", purchaseDateEpochSeconds)
    //Determine if purchase type is rental
    let rentalExpiryDateEpochSeconds: any = 0
    if (purchaseType?.toLowerCase().includes("rental")) {
        //Calculate rental expiry date
        rentalExpiryDateEpochSeconds = purchaseDateEpochSeconds + 60 * 60 * 24 * 3
        console.log("rentalExpiryDateEpochSeconds: ", rentalExpiryDateEpochSeconds)
    }

    const ownershipDetails: Record<string, any> = {
        customer: email,
        title: title,
        purchaseType: purchaseType,
        purchaseDateEpochSeconds: purchaseDateEpochSeconds,
        rentalExpiryDateEpochSeconds: rentalExpiryDateEpochSeconds
    }

    const command = new PutCommand({
        TableName: process.env.DYNAMODB_NAME,
        // Item: {
        //     customer: email,
        //     title: title,
        //     purchaseType: purchaseType,
        //     purchaseDateEpochSeconds: purchaseDateEpochSeconds,
        //     rentalExpiryDateEpochSeconds: rentalExpiryDateEpochSeconds
        // },
        Item: ownershipDetails,
        ConditionExpression: 'attribute_not_exists(customer) AND attribute_not_exists(title)'
    });
    try {
        const response = await docClient?.send(command);
        console.log(response);
    } catch (err) {
        if (err instanceof ConditionalCheckFailedException) {
            console.warn(`Entry containing customer and title already found. PUT operation stopped.`)
            console.warn(err.message)
            return null
        } else {
            throw err
        }
    }
    if (purchaseType?.toLowerCase().includes("rental")) {
        return ownershipDetails
    }
    return null
}

//Get all items owned by the customer. Customer information provided in the event body.
async function queryAllItems(docClient: DynamoDBDocumentClient | null, event: APIGatewayProxyEventV2): Promise<QueryCommandOutput | undefined> {
    if (event.body) {
        const body = JSON.parse(event.body)
        const command = new QueryCommand({
            TableName: process.env.DYNAMODB_NAME,
            KeyConditionExpression:
                "customer = :Customer",
            ExpressionAttributeValues: {
                ":Customer": body.customer,
            },
            ConsistentRead: true,
        });

        const response = await docClient?.send(command);
        console.log("response?.Items: ", response?.Items);
        return response;
    }
    return undefined;
}

export { TEventVerification, getStripe, getClient, getDocClient, verifyEventAsync, fulfillOrder, queryAllItems }