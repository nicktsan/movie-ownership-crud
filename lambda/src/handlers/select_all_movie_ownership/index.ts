import { APIGatewayProxyEventV2, APIGatewayProxyResultV2 } from 'aws-lambda';
import { getClient, getDocClient, queryAllItems } from "/opt/nodejs/utils";
import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { DynamoDBDocumentClient } from "@aws-sdk/lib-dynamodb";
import { unmarshall } from '@aws-sdk/util-dynamodb';

let client: DynamoDBClient | null;
let docClient: DynamoDBDocumentClient | null;
export const handler = async (event: APIGatewayProxyEventV2): Promise<APIGatewayProxyResultV2> => {
    console.log("event: ", event)
    if (event.routeKey !== process.env.ROUTE_KEY) {
        throw new Error(`${process.env.ROUTE_KEY} method only accepts ${process.env.ROUTE_KEY} method, you tried: ${event.routeKey}`);
    }
    client = await getClient(client);
    docClient = await getDocClient(client, docClient)
    try {
        // fetch is available with Node.js 18
        const res = await queryAllItems(docClient, event);
        const resItems = res?.Items;
        //If a response contains multiple objects, you must unmarshall each record separately before putting them back together.
        //.map() solves this issue
        // const resItemsMapped = resItems?.map((i) => unmarshall(i));
        let returnMessage;
        if (resItems == undefined) {
            returnMessage = "Received request without a payload."
        }
        else {
            returnMessage = resItems//JSON.stringify(resItems);
        }
        return {
            statusCode: 200,
            body: JSON.stringify({
                // message: await resItemsMapped?.text(),
                message: returnMessage
            }),
        };
    } catch (err) {
        let errMessage = "An error occured."
        if (err instanceof Error) {
            errMessage = err.message
            // console.error(`Webhook Error: ${err.message}`);
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