package contract

// 合约ABI定义
const dailyLotteryContractABI = `[
    {
        "type": "function",
        "name": "lotteryNumber",
        "inputs": [

        ],
        "outputs": [
            {
                "name": "",
                "type": "uint64",
                "internalType": "uint64"
            }
        ],
        "stateMutability": "view"
    },
    {
        "type": "function",
        "name": "getDrawState",
        "inputs": [
            {
                "name": "_lotteryNumber",
                "type": "uint64",
                "internalType": "uint64"
            }
        ],
        "outputs": [
            {
                "name": "",
                "type": "uint8",
                "internalType": "enum LotteryDrawState"
            }
        ],
        "stateMutability": "view"
    },
    {
        "type": "function",
        "name": "drawLottery",
        "inputs": [
			{
                "name": "_lotteryNumber",
                "type": "uint64",
                "internalType": "uint64"
            }
        ],
        "outputs": [

        ],
        "stateMutability": "nonpayable"
    }
]`

const dailyLotteryErrorABI = `
	[
		{
			"inputs": [
	
			],
			"name": "DrawingInProgress",
			"type": "error"
		},
		{
			"type": "error",
			"name": "MinDrawIntervalNotMet",
			"inputs": [
				{
					"name": "startTime",
					"type": "uint256",
					"internalType": "uint256"
				},
				{
					"name": "currentTime",
					"type": "uint256",
					"internalType": "uint256"
				}
			]
		}
	]
`
