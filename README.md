[去中心化彩票系统（web3个人实践项目）](http://web3-lottery.ioceans.net/) <br/>
ps：项目还有不少可优化空间，仅供学习使用。

主要提供两个彩票功能：
- 天天有奖（定时开奖）：点击页面的“抽奖”按钮（抽一张、抽多张），抽取彩票号码。系统每天零时开奖一次，抽取中奖用户，中奖用户可获取本期奖池所有奖金。如果本期没有参与者，则轮空。
- 刮刮乐（实时开奖）：点击“刮奖”按钮（刮一张），根据概率判断当前用户是否中奖，以及中奖类型（中奖概率及奖金是随意配置）。
  - 大奖：中奖概率：0.01%，可获取当前奖池的50%奖金。
  - 小奖：中奖概率：1%，可获取当前奖池的5%奖金。
  - 幸运奖：中奖概率：5%，可获取当前奖池的1%奖金。 

用户中奖后，平台从奖金中抽佣5%作为手续费，其余部分才是实际到账金额。

注意事项：
- 刮刮乐操作，因为实时开奖，需要等待chainlink的VRF合约回调，因此等待时间较长。
- 如果操作后，刷新中奖名单/抽奖记录列表，没有及时显示当前操作结果，是因为测试部署The Graph区域同步延迟导致。

### lottery-contract
基于UUPS代理模式的Solidity可升级合约项目，通过 Foundry 进行合约测试与部署，使用 The Graph 实现链上数据索引。

#### 天天有奖
- DailyLotteryV1：逻辑合约：业务入口，组装业务逻辑调用
- IDailyLotteryToken： 天天有奖中奖Token合约
- IDailyLotteryNumberLogic：获取抽奖号码，及选择中奖号码
- IDailyLotteryRandProvider：随机数提供者，基于chainlink的VRF实现

#### 刮刮乐
- ScratchCardV1：逻辑合约：业务入口，组装业务逻辑调用
- IScratchCardToken：刮刮乐中奖Token合约
- IScratchCardResult：封装中奖算法逻辑，提供中奖结果
- IScratchCardRandProvider：随机数提供者，基于chainlink的VRF实现

### lottery-web
web 页面，基于React框架，使用框架：Rainbow、wagmi、viem等

### lottery-go
用于天天有奖零时触发开奖逻辑。