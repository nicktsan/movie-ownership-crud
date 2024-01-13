import { APIGatewayProxyEventV2, APIGatewayProxyResultV2 } from 'aws-lambda';
import Stripe from "stripe";
import { getStripe, getClient, getDocClient, queryAllItems, getStripeProduct, attachImageToResponse } from "/opt/nodejs/utils";
import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { DynamoDBDocumentClient } from "@aws-sdk/lib-dynamodb";

let stripe: Stripe | null;
let client: DynamoDBClient | null;
let docClient: DynamoDBDocumentClient | null;
export const handler = async (event: APIGatewayProxyEventV2): Promise<APIGatewayProxyResultV2> => {
    console.log("event: ", event)
    if (event.routeKey !== process.env.ROUTE_KEY) {
        throw new Error(`${process.env.ROUTE_KEY} method only accepts ${process.env.ROUTE_KEY} method, you tried: ${event.routeKey}`);
    }
    stripe = await getStripe(stripe);
    client = await getClient(client);
    docClient = await getDocClient(client, docClient)
    try {
        //Query all items owned by the customer
        const res = await queryAllItems(docClient, event);
        let resItems = res?.Items;
        let products: Stripe.Product[] | undefined;
        let edittedResItems: Record<string, any> | undefined
        if (resItems!.length > 0) {
            //get product information of movies owned by customer
            products = await getStripeProduct(resItems, stripe);
            //attach image information to response body
            edittedResItems = await attachImageToResponse(resItems, products)
        }
        let returnMessage;
        if (resItems == undefined) {
            returnMessage = "Received request without a payload."
        }
        else {
            returnMessage = edittedResItems
        }
        return {
            statusCode: 200,
            body: JSON.stringify({
                message: returnMessage
            }),
        };
    } catch (err) {
        let errMessage = "An error occured."
        if (err instanceof Error) {
            errMessage = err.message
        }
        console.warn(err);
        return {
            statusCode: 500,
            body: JSON.stringify({
                message: errMessage,
            }),
        };
    }
};