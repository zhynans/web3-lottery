import { GraphQLClient, gql } from "graphql-request";

const graphApiUrl = process.env.NEXT_PUBLIC_GRAPH_API_URL as string;

export const getMyNumbers = async (
  address: string,
  lotteryNumber: BigInt
): Promise<Array<Number>> => {
  const client = new GraphQLClient(graphApiUrl);
  const query = gql`
    query GetMyNumbers($user: String!, $lotteryNumber: String!) {
      takeNumbers(where: { user: $user, lotteryNumber: $lotteryNumber }) {
        number
        blockTimestamp
      }
    }
  `;
  const variables = { user: address, lotteryNumber: lotteryNumber.toString() };
  const data = (await client.request(query, variables)) as {
    takeNumbers: Array<{ number: number; blockTimestamp: number }>;
  };
  // console.log("data", data);
  return data.takeNumbers
    .sort((a, b) => b.blockTimestamp - a.blockTimestamp)
    .map((item) => item.number);
};
