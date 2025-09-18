import { GraphQLClient, gql } from "graphql-request";

const graphApiUrl = process.env.NEXT_PUBLIC_GRAPH_API_URL as string;

export interface LotteryResult {
  user: string;
  timestamp: number;
  prize: number;
  amount: number;
}

export const getLotteryResultList = async (
  current: number,
  pageSize: number
): Promise<Array<LotteryResult>> => {
  const client = new GraphQLClient(graphApiUrl);
  const query = gql`
    query getLotteryResultList($first: Int!, $skip: Int!) {
      lotteryResults(
        first: $first
        skip: $skip
        orderBy: timestamp
        orderDirection: desc
      ) {
        user
        timestamp
        prize
        amount
      }
    }
  `;
  const variables = { first: pageSize, skip: (current - 1) * pageSize };
  const data = (await client.request(query, variables)) as {
    lotteryResults: Array<LotteryResult>;
  };
  // console.log("data", data);
  return data.lotteryResults;
};
