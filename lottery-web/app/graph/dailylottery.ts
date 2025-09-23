import { GraphQLClient, gql } from "graphql-request";

const graphApiUrl = process.env.NEXT_PUBLIC_GRAPH_API_URL as string;

export interface LotteryDrawn {
  lotteryNumber: number;
  winner: string;
  winnerNumber: number;
  prize: number;
  drawTime: number;
}

export const getMyNumbers = async (
  address: string,
  lotteryNumber: bigint
): Promise<Array<number>> => {
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

export const getLotteryDrawns = async (
  current: number,
  pageSize: number
): Promise<Array<LotteryDrawn>> => {
  const client = new GraphQLClient(graphApiUrl);
  const query = gql`
    query GetLotteryDrawns($first: Int!, $skip: Int!) {
      lotteryDrawns(
        first: $first
        skip: $skip
        orderBy: lotteryNumber
        orderDirection: desc
      ) {
        lotteryNumber
        winner
        winnerNumber
        prize
        drawTime
      }
    }
  `;
  const variables = { first: pageSize, skip: (current - 1) * pageSize };
  const data = (await client.request(query, variables)) as {
    lotteryDrawns: Array<LotteryDrawn>;
  };

  return data.lotteryDrawns;
};
