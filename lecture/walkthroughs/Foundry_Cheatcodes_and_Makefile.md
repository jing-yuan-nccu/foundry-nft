# Foundry Cheatcodes & Makefile 附錄

## 這篇要看什麼

`Exercise5` 與 `Exercise6` 的 walkthrough 都會用到 `forge`、`anvil`、`cast` 指令，以及測試裡常見的 `vm.xxx` cheatcode。這份文件把**兩個 Exercise 共用的工具知識**集中整理，避免在兩篇 walkthrough 重複。

當你在 walkthrough 裡看到 `vm.prank`、`vm.expectRevert`、`make deploy` 等出現，回來這裡查就好。

---

## 一、`forge` 指令速查

### `forge build`

編譯 `src/`、`script/`、`test/` 下所有 Solidity 檔案。輸出到 `out/`。

- 第一次執行會自動下載對應版本的 `solc`，慢一點是正常
- compile error 會在這裡先抓到，所以**寫完一段就跑一次**比較好

### `forge test`

跑所有 test。常用 flag：

| Flag | 用途 |
| --- | --- |
| `-vv` | 印出每個 test 的 console.log |
| `-vvv` | 加印 stack trace（fail 時） |
| `-vvvv` | 加印每筆 storage 讀寫（除錯神器） |
| `--match-contract BasicNftTest` | 只跑這個 contract 的 test |
| `--match-test testFlipTokenToSad` | 只跑這個 test 函式 |
| `--gas-report` | 印出每個 function 的 gas 報告 |
| `-vvv --debug testXxx` | 進入互動式 debugger |

**常用組合**

```bash
# 寫一個新 test 時，只跑這個 test 並看完整 trace
forge test --match-test testFlipTokenToSad -vvvv

# 全綠回顧
forge test -vv
```

### `forge script`

跑 `script/` 下的部署 / 互動腳本。

```bash
forge script script/DeployBasicNft.s.sol:DeployBasicNft \
  --rpc-url http://127.0.0.1:8545 \
  --private-key 0xac0974... \
  --broadcast
```

| Flag | 用途 |
| --- | --- |
| `--rpc-url <url>` | 對哪條鏈執行 |
| `--private-key <hex>` | 簽名用的私鑰（給 `vm.startBroadcast`） |
| `--broadcast` | 真的把交易送出去；**不加就只是 dry-run**（很常忘，導致以為部署成功實際沒上鏈） |
| `--verify` | 部署後自動上 etherscan 驗證 |
| `--etherscan-api-key <key>` | 配合 `--verify` 用 |
| `-vvvv` | 印出超詳細 log |

**`script.sol:ContractName` 的冒號語法**

`script/DeployBasicNft.s.sol:DeployBasicNft` —— 同一個檔可能有多個 contract（例如 `Interactions.s.sol` 有 4 個），冒號後面指定要跑哪一個。

### `forge install` / `forge update`

```bash
forge install cyfrin/foundry-devops@0.2.2
forge install foundry-rs/forge-std@v1.8.2
forge install openzeppelin/openzeppelin-contracts@v5.0.2
```

`forge install` 把 GitHub repo 加為 git submodule 放在 `lib/`。專案首次 clone 後跑 `git submodule update --init --recursive` 會把這些拉下來。

---

## 二、`anvil` 本地鏈

```bash
anvil
# 或 Makefile 內：
anvil -m 'test test test test test test test test test test test junk' --steps-tracing --block-time 1
```

| Flag | 用途 |
| --- | --- |
| `-m '<mnemonic>'` | 用指定的助記詞產生帳號（可重現的測試環境） |
| `--block-time 1` | 每秒出 1 個 block（不加是「有 tx 就出 block」） |
| `--steps-tracing` | 開啟 EVM 步驟 trace（讓除錯工具讀） |
| `--port 8545` | 改 port（預設 8545） |
| `--chain-id 31337` | 改 chainId（預設 31337） |

**預設帳號**

`anvil` 啟動後會印 10 個帳號，每個有 10000 ETH。第一個帳號的私鑰 `0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80` 在 `Makefile` 裡叫 `DEFAULT_ANVIL_KEY`。

**⚠️ 誤區**

- anvil 視窗關掉，鏈上 state 全部消失
- 換一個視窗開新 anvil，所有部署紀錄會跑掉
- `DevOpsTools.get_most_recent_deployment` 會找不到合約

---

## 三、`cast` 與鏈互動

### `cast call` —— 唯讀查詢（不花 gas）

```bash
cast call <地址> "<函式 signature>(<回傳型別>)" <參數> --rpc-url <url>

# 範例
cast call $CONTRACT_ADDRESS "name()(string)" --rpc-url http://127.0.0.1:8545
cast call $CONTRACT_ADDRESS "ownerOf(uint256)(address)" 0 --rpc-url http://127.0.0.1:8545
cast call $CONTRACT_ADDRESS "tokenURI(uint256)(string)" 0 --rpc-url http://127.0.0.1:8545
```

**`(string)` 是什麼？**

是 **return decode hint**——告訴 cast 把回傳的 ABI-encoded bytes 解碼成 string。**不寫的話會回傳 hex**（`0x000000...0006Charizard...` 之類）。

**⚠️ 誤區**

- 多參數函式：signature 中參數型別**不要加變數名**：✅ `"transfer(address,uint256)"`，❌ `"transfer(address to, uint256 amount)"`
- 多回傳值：`"foo()(uint256,address)"`
- 字串型別在 signature 裡用 `string`，不要寫成 `string memory`

### `cast send` —— 寫入交易（花 gas）

```bash
cast send <地址> "<函式 signature>" <參數> \
  --rpc-url <url> \
  --private-key <hex>

# 範例：直接 mint 一顆 BasicNft
cast send $CONTRACT_ADDRESS "mintNft()" \
  --rpc-url http://127.0.0.1:8545 \
  --private-key 0xac0974...
```

**call vs send 怎麼選？**

| 動作 | 用 |
| --- | --- |
| 讀資料（`view` / `pure`） | `cast call` |
| 改 state（`mintNft`、`flipMood`、`setBaseTokenUri`） | `cast send` |

對 `view` 函式用 `cast send` 也會成功，但會白白花 gas。

### 其他常用 cast

| 指令 | 用途 |
| --- | --- |
| `cast wallet new` | 產生一組私鑰 |
| `cast balance <addr>` | 查 ETH 餘額 |
| `cast storage <addr> <slot>` | 讀任意 storage slot（**包括 private 變數**） |
| `cast --to-base 100 16` | 進制轉換 |
| `cast keccak "Transfer(address,address,uint256)"` | 算事件 signature hash |

---

## 四、常用 Foundry cheatcodes（`vm.xxx`）

寫在測試或 script 裡的 `vm.xxx` 都是 cheatcode——**只在 forge 環境有效**，部署到正式鏈會被忽略。

### 身份偽造

| Cheatcode | 用途 | 影響範圍 |
| --- | --- | --- |
| `vm.prank(addr)` | 把下一筆呼叫的 `msg.sender` 換成 `addr` | **只影響下一筆** |
| `vm.startPrank(addr)` | 同上 | 從這裡到 `vm.stopPrank()` 之間所有呼叫 |
| `vm.stopPrank()` | 結束 startPrank | — |
| `vm.deal(addr, amount)` | 給 `addr` 設 ETH 餘額 | 永久 |

```solidity
// 單筆
vm.prank(USER);
contract.foo();

// 多筆
vm.startPrank(USER);
contract.foo();
contract.bar();
vm.stopPrank();
```

### 期望結果

| Cheatcode | 用途 |
| --- | --- |
| `vm.expectRevert()` | 期望下一筆 revert（不檢查內容） |
| `vm.expectRevert("string")` | 期望下一筆 revert 並噴指定字串（OZ v4） |
| `vm.expectRevert(abi.encodeWithSelector(Error.selector, args))` | 期望下一筆 revert 並噴指定 custom error（OZ v5） |
| `vm.expectEmit(bool, bool, bool, bool)` | 期望下一筆 emit 事件，4 個 bool 對應 (topic1, topic2, topic3, data) 是否要嚴格比對 |

```solidity
// custom error（OZ v5 標準寫法）
vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, USER));
contract.adminOnlyFunction();

// expectEmit 的順序：先告知 → 寫範本 → 真的呼叫
vm.expectEmit(true, true, true, true);
emit IERC4906.BatchMetadataUpdate(0, type(uint256).max);
contract.setBaseTokenUri("ipfs://...");
```

### 事件 Log

```solidity
vm.recordLogs();          // 開始記錄
contract.someAction();
Vm.Log[] memory logs = vm.getRecordedLogs();
bytes32 firstTopic = logs[0].topics[0];   // event signature hash
bytes32 indexedArg1 = logs[0].topics[1];  // 第 1 個 indexed 參數
bytes memory data = logs[0].data;         // non-indexed 參數打包
```

| 規則 | 細節 |
| --- | --- |
| `topics[0]` | event signature 的 keccak256 hash |
| `topics[1..3]` | indexed 參數（最多 3 個） |
| `data` | non-indexed 參數，要 `abi.decode` 才能讀 |

### 環境變數

| Cheatcode | 行為 |
| --- | --- |
| `vm.envString("KEY")` | 沒設會 **revert** |
| `vm.envUint("KEY")` | 沒設會 **revert**；非數字也 revert |
| `vm.envAddress("KEY")` | 沒設會 **revert** |
| `vm.envOr("KEY", default)` | 沒設用 default，**不 revert** |

選擇規則：「**沒值是不是該停下**？」——是就用 `envXxx`，不是就用 `envOr`。

### 讀檔

```solidity
string memory svg = vm.readFile("./img/sad.svg");
```

受 `foundry.toml` 的 `fs_permissions` 限制：

```toml
fs_permissions = [
    { access = "read", path = "./img/" }
]
```

只有列出的路徑能讀。

### 部署 broadcast

```solidity
vm.startBroadcast();              // 用 --private-key 指定的 key 簽名
new MyContract(arg1, arg2);
contract.someStateChange();
vm.stopBroadcast();
```

`vm.startBroadcast/stopBroadcast` **之間**的 state-changing 呼叫會被打包成真實交易送上鏈。**之外**的呼叫只在本地 EVM 執行（讀檔、計算字串、組裝參數都該放在 `startBroadcast` 之前，省 gas）。

也可以指定簽名者：

```solidity
vm.startBroadcast(privateKey);   // 用這個 key 簽名（不用命令列傳）
```

### 時間 / 區塊

| Cheatcode | 用途 |
| --- | --- |
| `vm.warp(timestamp)` | 把 `block.timestamp` 改成指定值 |
| `vm.roll(blockNumber)` | 把 `block.number` 改成指定值 |

這個專案沒用到，但 staking、vesting、auction 等場景會用到。

### 其他

| Cheatcode | 用途 |
| --- | --- |
| `makeAddr("name")` | 產生 deterministic 的可讀地址（hash 過） |
| `vm.label(addr, "name")` | 在 trace log 把地址換成名字（除錯時超有用） |
| `assertEq(a, b)` | a 跟 b 必須相等，不等就 fail |
| `assertTrue(condition)` | condition 必須為 true |
| `assertGt(a, b)` | a > b |

---

## 五、`foundry.toml` 設定

```toml
[profile.default]
src = "src"
out = "out"
libs = ["lib"]
remappings = [
  '@openzeppelin/contracts=lib/openzeppelin-contracts/contracts'
]

fs_permissions = [
    { access = "read", path = "./images/" },
    { access = "read", path = "./img/" },
    { access = "read", path = "./broadcast" },
    { access = "read", path = "./lib/foundry-devops" }
]
```

**逐項解說**

- `src = "src"`：合約原始碼放這
- `out = "out"`：編譯輸出（artifact、ABI、bytecode）放這
- `libs = ["lib"]`：dependency 從 `lib/` 找
- `remappings`：把 `@openzeppelin/contracts/...` 對應到實際路徑。沒這行 import 會找不到。
- `fs_permissions`：白名單機制，限制 `vm.readFile` 能讀哪些路徑。

**⚠️ 誤區**

- 加新依賴後忘記加 remapping，IDE 紅字、build 失敗
- 移動 SVG 到新資料夾後忘記更新 `fs_permissions`，`vm.readFile` revert

---

## 六、Makefile 模式

這個專案的 `Makefile` 是 cyfrin / foundry 社群慣用的模板。重點段落解析。

### 載入 `.env`

```makefile
-include .env
```

把 `.env` 內的環境變數載入。`-include` 的 `-` 表示「檔案不存在也不報錯」。常見內容：

```bash
SEPOLIA_RPC_URL=https://...
PRIVATE_KEY=0x...
ETHERSCAN_API_KEY=...
IPFS_BASE_TOKEN_URI=ipfs://Qm.../
```

**⚠️ 誤區**

- `.env` **永遠** 加進 `.gitignore`，不能 commit 私鑰
- 私鑰用 raw hex 是教學方便，正式環境用 `cast wallet import` 加密保存

### 變數切換 `NETWORK_ARGS`

```makefile
NETWORK_ARGS := --rpc-url http://localhost:8545 --private-key $(DEFAULT_ANVIL_KEY) --broadcast
SEPOLIA_ARGS := --rpc-url $(SEPOLIA_RPC_URL) --private-key $(PRIVATE_KEY) --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv

ifeq ($(findstring --network sepolia,$(ARGS)),--network sepolia)
    NETWORK_ARGS := $(SEPOLIA_ARGS)
endif
```

預設 `NETWORK_ARGS` 指向 anvil。如果跑 `make deploy ARGS="--network sepolia"`，`NETWORK_ARGS` 會被換成 Sepolia 版本。

### Target 範例

```makefile
deploy:
    @forge script script/DeployBasicNft.s.sol:DeployBasicNft $(NETWORK_ARGS)

mint:
    @forge script script/Interactions.s.sol:MintBasicNft ${NETWORK_ARGS}

flipMoodNft:
    @if [ -z "$(TOKEN_ID)" ]; then echo "TOKEN_ID is required. Usage: make flipMoodNft TOKEN_ID=0"; exit 1; fi
    @TOKEN_ID=$(TOKEN_ID) forge script script/Interactions.s.sol:FlipMoodNft $(NETWORK_ARGS)
```

**規則**

- `@` 開頭：執行時不要把指令本身印出來
- `;\` 與 indent：`Makefile` 的 target body 必須**用 tab**，不是 space，這是新人常見地雷
- `-include` 的 `-`：檔案不存在不報錯
- `$(VAR)` 與 `${VAR}` 是同樣意思

### 完整 Makefile target 對照

| Make 指令 | 對應動作 | 何時用 |
| --- | --- | --- |
| `make build` | `forge build` | 改完合約看編不編得過 |
| `make test` | `forge test` | 跑全部 test |
| `make anvil` | 啟動本地鏈 | 開發第一步 |
| `make deploy` | 部署 BasicNft 到 anvil | Exercise 5 |
| `make mint` | mint 一顆 BasicNft | Exercise 5 |
| `make update-base-uri NEW_IPFS_BASE_TOKEN_URI=...` | 更新 baseURI | Exercise 5 進階 |
| `make deployMood` | 部署 MoodNft 到 anvil | Exercise 6 |
| `make mintMoodNft` | mint 一顆 MoodNft | Exercise 6 |
| `make flipMoodNft TOKEN_ID=0` | 翻 token 0 的 mood | Exercise 6 |
| `make deploy-sepolia` / `mint-sepolia` | 同上但對 Sepolia | 上測試網 |

---

## 七、`DevOpsTools.get_most_recent_deployment`

`Interactions.s.sol` 用到的 helper：

```solidity
address mostRecentDeployment =
    DevOpsTools.get_most_recent_deployment("BasicNft", block.chainid);
```

**內部做了什麼**

1. 讀 `broadcast/<合約檔名>/<chainId>/run-latest.json`
2. 找出最後一次部署的合約地址

例如部署 `BasicNft` 到 anvil（chainId 31337）後，會生成：

```
broadcast/DeployBasicNft.s.sol/31337/run-latest.json
```

裡面記錄了部署地址、tx hash、block number 等。

**⚠️ 誤區**

- **必須 `--broadcast`**：沒加 `--broadcast` flag 跑 script，就不會生成 broadcast 紀錄，`get_most_recent_deployment` 會找不到
- **跨 chainId 找不到**：今天在 anvil（31337）部署，明天打 Sepolia（11155111），是兩個不同資料夾
- **刪 `broadcast/` 就壞**：千萬不要 `rm -rf broadcast/`
- 也可以手動指定地址（不用 helper）：把 `mostRecentDeployment` 寫成 hardcoded address

---

## 八、Verbose log 速查表

debug 時 verbose level 是你的好朋友。

| Flag | 看到什麼 |
| --- | --- |
| 不加 | 只看 pass / fail 統計 |
| `-v` | 列出每個 test 的 pass / fail |
| `-vv` | 加印 `console.log()` 內容 |
| `-vvv` | fail 時印 stack trace（function call sequence） |
| `-vvvv` | 加印每筆 storage 讀寫、internal call |
| `-vvvvv` | 加印 setUp 的 trace（極詳細） |

**建議用法**

- 平常 `-vv`
- 一個 test fail 了：`forge test --match-test xxx -vvvv`
- script 跑不出來：`forge script ... -vvvv`

---

## 九、常見錯誤訊息對照

| 錯誤訊息 | 真正原因 |
| --- | --- |
| `cannot find file: lib/openzeppelin-contracts/...` | 沒跑 `git submodule update --init --recursive` |
| `Source file requires different compiler version` | `pragma` 與本地 compiler 版本不合 |
| `OwnableUnauthorizedAccount(0x...)` | 用非 owner 帳號呼叫 `onlyOwner` 函式 |
| `ERC721NonexistentToken(...)` | 對沒鑄出來的 tokenId 呼叫 `ownerOf` / `tokenURI` |
| `Reason: PermissionDenied("xxx not allowed")` | `vm.readFile` 路徑沒在 `fs_permissions` 白名單 |
| `vm.envXxx: environment variable "X" not found` | 環境變數沒設；改 `vm.envOr` 或設環境變數 |
| `No deployment artifacts could be found` | 沒部署過該合約、沒 `--broadcast`、或刪了 `broadcast/` |
| `make: *** No rule to make target ...` | Makefile target 名拼錯，或 indent 用 space 而不是 tab |

---

## 延伸閱讀

- Foundry 官方文件：https://book.getfoundry.sh/
- forge-std cheatcodes 速查：`lib/forge-std/src/Vm.sol`（讀原始 interface）
- OpenZeppelin v5 升級指南：https://docs.openzeppelin.com/contracts/5.x/upgrade-from-4.x（解釋 `Ownable` constructor 變動、custom error 等）
