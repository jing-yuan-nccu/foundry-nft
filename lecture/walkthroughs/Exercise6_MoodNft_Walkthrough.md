# Exercise 6：MoodNft 程式碼逐行解說

## 這篇要看什麼

這份文件搭配 `6_Exercise6.md` 使用。Exercise 5 的 `BasicNft` 把 metadata 放在 IPFS 的 JSON 檔，這裡的 `MoodNft` **完全不依賴外部儲存**——SVG 圖、JSON metadata 都在合約裡用 Base64 即時組出來。

涵蓋的檔案：

| 檔案                                                        | 行數   | 角色                              |
| ----------------------------------------------------------- | ------ | --------------------------------- |
| `src/MoodNft.sol`                                           | 81     | 動態 NFT 合約                     |
| `script/DeployMoodNft.s.sol`                                | 25     | 把 SVG 讀入並編碼後部署           |
| `script/Interactions.s.sol`（`MintMoodNft`、`FlipMoodNft`） | L32-53 | 鑄造 / 翻轉心情                   |
| `test/MoodNftTest.t.sol`                                    | 101    | 測試（含 zksync 分支與 log 解析） |
| `img/happy.svg`、`img/sad.svg`                              | —      | SVG 原檔                          |

## 必備前置觀念（請先看完）

- `lecture/Onchain_NFT_Metadata.md`：onchain Base64 metadata 的概念
- `lecture/Static_vs_Dynamic_NFTs.md`：靜態 vs 動態 NFT
- 已讀完 `lecture/walkthroughs/Exercise5_BasicNft_Walkthrough.md`：本篇假設你已熟悉 ERC721、`_safeMint`、`tokenURI` override、`vm.prank` 等基礎

Foundry 指令、cheatcode、Makefile 共用知識請見 `lecture/walkthroughs/Foundry_Cheatcodes_and_Makefile.md`。

---

## 〇、整體資料流（最重要的一張圖）

理解 `MoodNft` 的關鍵是：**`tokenURI` 回傳的字串裡藏了兩層 Base64**。

```
img/happy.svg            （原始 SVG 文字，例如 "<svg ...>...</svg>")
   │
   ├─ DeployMoodNft.svgToImageURI()
   ▼
"data:image/svg+xml;base64,PHN2ZyAuLi4+...PC9zdmc+"        ← 第一層：image URI
   │
   ├─ 存進 s_happySvgUri / s_sadSvgUri（合約 storage）
   │
   └─ 之後 tokenURI() 被呼叫時：
       │
       ├─ 把 image URI 包進 JSON：
       │     '{"name":"...","image":"data:image/svg+xml;base64,..."}'
       │
       ├─ 整段 JSON 再 Base64 一次
       ▼
"data:application/json;base64,eyJuYW1lIjoiLi4uIn0="        ← 第二層：metadata URI
       │
       ▼
   tokenURI(0) 回傳這串給 wallet / marketplace
```

Wallet 拿到 `data:application/json;base64,...`：

1. decode Base64 → 拿到 JSON 字串
2. parse JSON → 拿到 `image` 欄位
3. `image` 欄位又是 `data:image/svg+xml;base64,...` → 再 decode 一次 → 渲染 SVG

**整個過程不需要任何外部 server**。這就是「fully onchain NFT」。

帶著這張圖看下面每一段程式碼，會清楚很多。

## 一、`src/MoodNft.sol` 逐段解說

### 1. Import（L4-6）

```solidity
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";
```

- `ERC721`、`Ownable`：與 `BasicNft` 一樣
- `Base64`：OZ 提供的 `Base64.encode(bytes)` helper，回傳 Base64 字串。**這是這個合約的核心工具**。

---

### 2. enum 與 state variables（L9-17）

```solidity
enum NFTState {
    HAPPY,
    SAD
}

uint256 private s_tokenCounter;
string private s_sadSvgUri;
string private s_happySvgUri;
mapping(uint256 => NFTState) private s_tokenIdToState;
```

**在做什麼**

- `enum NFTState { HAPPY, SAD }`：定義一個列舉型別，表示 NFT 的兩種心情。
- `s_sadSvgUri` / `s_happySvgUri`：部署時傳進來，已經是 `data:image/svg+xml;base64,...` 字串（在 `DeployMoodNft.svgToImageURI` 處理過）。
- `s_tokenIdToState`：每顆 NFT 對應的 mood state。

**語法補充：enum**

- Solidity 的 enum **底層就是 `uint8`**（從 0 開始），所以：
  - `NFTState.HAPPY` == `0`
  - `NFTState.SAD` == `1`
- 可以 cast：`uint8(NFTState.SAD)` 會得到 `1`。
- enum 最多 256 個成員（因為是 `uint8`）。

**⚠️ 誤區**

- mapping 對沒設過的 key 會回傳預設值。`s_tokenIdToState[999]` 會回傳 `NFTState.HAPPY`（因為 `HAPPY = 0` 是 enum 的預設值）。所以：
  - 「狀態是 HAPPY」 ≠ 「這顆 NFT 真的存在」
  - 別用 mapping 的回傳值來判斷 NFT 存不存在；要用 `_requireOwned(tokenId)`。

---

### 3. Custom error 與 constructor（L19-27）

```solidity
error MoodNft__CantFlipMoodIfNotOwner();

constructor(string memory sadUri, string memory happyUri)
    ERC721("Mood NFT", "MN")
    Ownable(msg.sender)
{
    s_sadSvgUri = sadUri;
    s_happySvgUri = happyUri;
}
```

**Custom error 命名慣例**

- 業界慣例：`<合約名>__<原因>`，雙底線分隔。
- 這樣 revert 時看到 `MoodNft__CantFlipMoodIfNotOwner`，立刻知道是哪個合約噴的。

**為什麼用 custom error 不用 `require(..., "string")`？**

- **省 gas**：custom error 編譯後是 4 bytes selector，字串可能是幾十 bytes

**Constructor 與 Exercise 5 的差別**

- 接收兩個 SVG URI 而不是一個 baseURI
- `name` / `symbol` 改成 `"Mood NFT"` / `"MN"`

---

### 4. `mintNft`（L29-33）

```solidity
function mintNft() public {
    s_tokenIdToState[s_tokenCounter] = NFTState.HAPPY;
    _safeMint(msg.sender, s_tokenCounter);
    s_tokenCounter++;
}
```

**為什麼先寫 state，再 `_safeMint`？**

`_safeMint` 對合約收款者會回呼 `onERC721Received(...)`。如果該合約的 `onERC721Received` 內**反向呼叫回 `MoodNft.tokenURI(tokenId)` 來顯示自己剛收到的 NFT**，這時候：

- 如果你**先 mint 後設 state**：mint 觸發 callback → callback 內呼叫 `tokenURI` → 讀到 `s_tokenIdToState[id]` 還是預設值 → 顯示成 HAPPY。在這個合約裡剛好「沒事」（因為預設就是 HAPPY），但這是**運氣好**。
- 如果你**先設 state 後 mint**：callback 看到的 state 已經正確。

這就是 **Checks-Effects-Interactions** pattern：對外部呼叫之前，先把所有 state 寫好。寫慣了能避免一整類 reentrancy 與 callback 邏輯錯誤。

---

### 5. `flipMood` 與權限模型（L35-46）

```solidity
function flipMood(uint256 tokenId) public {
    address owner = ownerOf(tokenId);
    if (msg.sender != owner && msg.sender != getApproved(tokenId) && !isApprovedForAll(owner, msg.sender)) {
        revert MoodNft__CantFlipMoodIfNotOwner();
    }

    if (s_tokenIdToState[tokenId] == NFTState.HAPPY) {
        s_tokenIdToState[tokenId] = NFTState.SAD;
    } else {
        s_tokenIdToState[tokenId] = NFTState.HAPPY;
    }
}
```

**為什麼權限要放行三種人？**

ERC721 的授權模型有三種「能操作 NFT 的角色」：

| 角色           | 怎麼變成                                      | 說明                                                 |
| -------------- | --------------------------------------------- | ---------------------------------------------------- |
| Owner          | `_safeMint` 或 `transferFrom` 收到            | 真的擁有                                             |
| Approved       | owner 呼叫`approve(operator, tokenId)`        | 對**單一 token** 授權                                |
| OperatorForAll | owner 呼叫`setApprovalForAll(operator, true)` | 對**整個 collection** 授權（marketplace 通常用這個） |

`flipMood` 視為「修改 NFT 屬性」，跟「轉讓 NFT」一樣應該允許這三種人操作。如果只判斷 owner，掛在 OpenSea 上的 NFT 就**沒辦法被 OpenSea 代為操作**。

---

### 6. `tokenURI` —— 雙層 Base64 的核心（L48-72）

```solidity
function tokenURI(uint256 tokenId) public view override returns (string memory) {
    _requireOwned(tokenId);

    string memory imageURI = s_tokenIdToState[tokenId] == NFTState.HAPPY ? s_happySvgUri : s_sadSvgUri;

    return string(
        abi.encodePacked(
            _baseURI(),
            Base64.encode(
                bytes(
                    abi.encodePacked(
                        '{"name":"',
                        name(),
                        '",',
                        '"description":"An NFT that reflects mood.",',
                        '"attributes":[{"trait_type":"moodiness","value":100}],',
                        '"image":"',
                        imageURI,
                        '"}'
                    )
                )
            )
        )
    );
}
```

**從外往內拆解**

最外層：

```solidity
string(abi.encodePacked(_baseURI(), Base64.encode(...)))
```

- `_baseURI()` 在 L78 被 override 成 `"data:application/json;base64,"`
- 所以最後拼出 `data:application/json;base64,<Base64 後的 JSON>`

中間層 `Base64.encode(bytes(...))`：

- 把 JSON 字串轉成 `bytes`，餵給 `Base64.encode`
- 為什麼要 `bytes(...)` cast？因為內層 `abi.encodePacked` 已經回傳 `bytes`，但 Solidity 不會自動再餵給 `Base64.encode(bytes memory)`，**多寫一次 `bytes(...)` 是明確 cast**。
  - 嚴格說，這個 `bytes(...)` 包在 `abi.encodePacked(...)` 外是 redundant（abi.encodePacked 已經回傳 bytes），但很多開源範例都這樣寫，因為加了不會錯，可讀性也好。

最內層 `abi.encodePacked(...)`：

- 把所有字串片段拼成一段連續 `bytes`
- 這就是真正的 JSON 字串：

  ```json
  {
    "name": "Mood NFT",
    "description": "An NFT that reflects mood.",
    "attributes": [{ "trait_type": "moodiness", "value": 100 }],
    "image": "data:image/svg+xml;base64,..."
  }
  ```

**為什麼用 `abi.encodePacked` 不用 `string.concat`？**

兩者在這裡幾乎等價。差別：

| 寫法                     | 回傳型別 | 用途                                     |
| ------------------------ | -------- | ---------------------------------------- |
| `string.concat(a, b)`    | `string` | 純粹要拼字串                             |
| `abi.encodePacked(a, b)` | `bytes`  | 要拼成 bytes（為了餵給 hash、Base64 等） |

這裡內層拼出來**馬上要 `Base64.encode(bytes)`**，所以用 `abi.encodePacked` 直接得到 `bytes`，省一次 `bytes()` cast。

**⚠️ 誤區（極度重要）**

1. **JSON 字串內的雙引號要用單引號 wrap**：
   - Solidity 字串 literal 用單引號或雙引號都可以
   - JSON 規定 key 必須用雙引號 `"name"`
   - 所以 Solidity 寫 `'{"name":"'` —— 外面單引號、裡面雙引號
   - 寫成 `"{\"name\":\""` 也可以但難讀

---

### 7. `getTokenCounter` 與 `_baseURI` override（L74-80）

```solidity
function getTokenCounter() public view returns (uint256) {
    return s_tokenCounter;
}

function _baseURI() internal pure override returns (string memory) {
    return "data:application/json;base64,";
}
```

**`getTokenCounter` 的存在意義**

- `s_tokenCounter` 是 `private`，其他合約讀不到。
- 提供 getter 讓 test 與 dapp 能查當前 counter（測試裡 `currentAvailableTokenId = moodNft.getTokenCounter()` 就靠它）

**`_baseURI` override 為什麼是 `pure`？**

- `_baseURI()` 是 ERC721 的 internal hook，預設回傳空字串
- 我們覆寫成固定值 `"data:application/json;base64,"`
- 這個函式**完全不讀 storage**，所以可以是 `pure`（比 `view` 更省 gas）

---

## 二、`script/DeployMoodNft.s.sol` 逐段解說

```solidity
contract DeployMoodNft is Script {
    function run() external returns (MoodNft) {
        string memory sadSvg = vm.readFile("./img/sad.svg");
        string memory happySvg = vm.readFile("./img/happy.svg");

        vm.startBroadcast();
        MoodNft moodNft = new MoodNft(svgToImageURI(sadSvg), svgToImageURI(happySvg));
        vm.stopBroadcast();

        return moodNft;
    }

    function svgToImageURI(string memory svg) public pure returns (string memory) {
        string memory baseURI = "data:image/svg+xml;base64,";
        string memory svgBase64Encoded = Base64.encode(bytes(svg));
        return string(abi.encodePacked(baseURI, svgBase64Encoded));
    }
}
```

**逐段解說**

- `vm.readFile("./img/sad.svg")` 讀進整個 SVG 檔案內容（純文字字串）。
- 這個讀檔動作在 `vm.startBroadcast` **之前**——讀檔是腳本本地行為，不該被當作鏈上交易。
- `svgToImageURI(svg)`：把原始 SVG 轉成 `data:image/svg+xml;base64,<base64>`，這就是「資料流圖」中的「第一層」。
- `new MoodNft(svgToImageURI(sadSvg), svgToImageURI(happySvg))`：constructor 接收的就是「已經 base64 化好的 image URI」。

**`vm.readFile` 的安全限制**

`vm.readFile` 會被 `foundry.toml` 的 `fs_permissions` 卡住。對照 `foundry.toml:9-14`：

```toml
fs_permissions = [
    { access = "read", path = "./images/" },
    { access = "read", path = "./img/" },
    { access = "read", path = "./broadcast" },
    { access = "read", path = "./lib/foundry-devops" }
]
```

只有列出的路徑可讀。試圖讀 `./../../etc/passwd` 會被擋。

**⚠️ 誤區**

- 沒設 `fs_permissions` 就用 `vm.readFile` 會 revert（permission denied）。
- 路徑寫錯（例如 `./images/sad.svg` 而不是 `./img/sad.svg`）也會 revert。
- 如果你新增了 SVG 放在別的資料夾，記得把該資料夾加到 `fs_permissions`。

**為什麼 `svgToImageURI` 是 `public pure`？**

- `pure`：完全不讀 / 寫合約 state，純字串轉換
- `public`：因為 **test 要直接呼叫它**（`MoodNftTest._expectedTokenUri` 內 `deployer.svgToImageURI(...)`）
- 如果改成 `internal`，test 就呼叫不到了

---

## 三、`script/Interactions.s.sol` 中的 MoodNft 部分

### `MintMoodNft`（L32-41）

```solidity
contract MintMoodNft is Script {
    function run() external {
        address mostRecentDeployment =
            DevOpsTools.get_most_recent_deployment("MoodNft", block.chainid);

        vm.startBroadcast();
        MoodNft(mostRecentDeployment).mintNft();
        vm.stopBroadcast();
    }
}
```

行為與 `MintBasicNft` 完全平行，只是換找 `"MoodNft"` 的部署地址。

### `FlipMoodNft`（L43-53）

```solidity
contract FlipMoodNft is Script {
    function run() external {
        uint256 tokenId = vm.envUint("TOKEN_ID");
        address mostRecentDeployment =
            DevOpsTools.get_most_recent_deployment("MoodNft", block.chainid);

        vm.startBroadcast();
        MoodNft(mostRecentDeployment).flipMood(tokenId);
        vm.stopBroadcast();
    }
}
```

**`vm.envUint("TOKEN_ID")`**

- 從環境變數讀字串並 decode 成 `uint256`
- Makefile 用法：`make flipMoodNft TOKEN_ID=0` 會設環境變數再呼叫 forge script

**⚠️ 誤區**

- `TOKEN_ID=abc`（非數字）會 revert，error 訊息不太友善
- `TOKEN_ID=` 空值也會 revert
- Makefile 在 `flipMoodNft` target 裡有先檢查 `[ -z "$(TOKEN_ID)" ]`，提供更友善的錯誤訊息

**為什麼 mint 與 flip 要分開兩個 contract？**

- 部署 / 互動 / 修改三件事，每件職責不同，分開才能單獨呼叫
- `make` target 也比較直覺：`make mintMoodNft`、`make flipMoodNft TOKEN_ID=0`

---

## 四、`test/MoodNftTest.t.sol` 逐段解說

### 繼承與 setup（L13-31）

```solidity
contract MoodNftTest is Test, ZkSyncChainChecker, FoundryZkSyncChecker {
    ...
    function setUp() public {
        deployer = new DeployMoodNft();
        if (!isZkSyncChain()) {
            moodNft = deployer.run();
        } else {
            string memory sadSvg = vm.readFile("./img/sad.svg");
            string memory happySvg = vm.readFile("./img/happy.svg");
            moodNft = new MoodNft(deployer.svgToImageURI(sadSvg), deployer.svgToImageURI(happySvg));
        }
    }
```

**為什麼有 zksync 分支？**

- zksync 的 EVM 不支援 `vm.startBroadcast()` 在 script 中部署的某些行為
- `ZkSyncChainChecker.isZkSyncChain()` 偵測當前是否在 zksync 環境
- 一般情況走 `deployer.run()`（會走 broadcast 流程）；zksync 則直接 `new MoodNft(...)`（不走 broadcast）

**初學者請忽略**

zksync 分支對學習 NFT 不重要，看到 `if/else` 知道是「部署方式的環境分流」即可。專注在 `if` 分支即可。

### 簡單測試（L33-43）

```solidity
function testInitializedCorrectly() public view {
    assertEq(moodNft.name(), NFT_NAME);
    assertEq(moodNft.symbol(), NFT_SYMBOL);
}

function testCanMintAndHaveABalance() public {
    vm.prank(USER);
    moodNft.mintNft();
    assertEq(moodNft.balanceOf(USER), 1);
}
```

跟 `BasicNftTest` 同款，沒新東西。

### `testTokenURIDefaultIsCorrectlySet`（L45-50）

```solidity
function testTokenURIDefaultIsCorrectlySet() public {
    vm.prank(USER);
    moodNft.mintNft();
    assertEq(moodNft.tokenURI(0), _expectedTokenUri(true));
}
```

**`_expectedTokenUri(true)` 在做什麼？**

- 在測試裡**重新組裝一次**合約預期會回傳的 tokenURI（`true` 代表 HAPPY）
- 然後比對合約真的回傳的 tokenURI 與這個預期值是否一致

**為什麼這樣寫？**

因為 tokenURI 是 base64-encoded JSON，**沒辦法用人眼直接寫死預期字串**。所以 test 裡也要實作一份「合約應該怎麼組」的邏輯，當作 source of truth。

**⚠️ 誤區（重要陷阱）**

這種寫法有個風險：**如果合約邏輯錯了，測試裡若用同樣的錯邏輯組 expected 值，兩邊會「一起錯」、test 卻通過**。所以更嚴謹的測法是：

1. 把固定的 `tokenURI` 字串硬寫在測試裡（先在 anvil 上跑一次拿到正確值）
2. 或對 `tokenURI` 結果 base64 decode 後 parse JSON 比對個別欄位

教學時可以提這點，但實作上 cyfrin 的範例就是用「自己組一份」的做法，學員照抄即可。

### `testFlipTokenToSad`（L52-60）

```solidity
function testFlipTokenToSad() public {
    vm.prank(USER);
    moodNft.mintNft();

    vm.prank(USER);
    moodNft.flipMood(0);

    assertEq(moodNft.tokenURI(0), _expectedTokenUri(false));
}
```

**為什麼要寫兩次 `vm.prank(USER)`？**

`vm.prank` **只影響下一筆**呼叫。第一次 prank 給 `mintNft`，第二次 prank 給 `flipMood`。中間不寫第二次的話，`flipMood` 的 `msg.sender` 會變回 test contract 地址，不是 owner，會 revert `MoodNft__CantFlipMoodIfNotOwner`。

### `testEventRecordsCorrectTokenIdOnMinting`（L62-74）

```solidity
function testEventRecordsCorrectTokenIdOnMinting() public {
    uint256 currentAvailableTokenId = moodNft.getTokenCounter();

    vm.prank(USER);
    vm.recordLogs();
    moodNft.mintNft();
    Vm.Log[] memory entries = vm.getRecordedLogs();

    bytes32 tokenIdProto = entries[0].topics[3];
    uint256 tokenId = uint256(tokenIdProto);

    assertEq(tokenId, currentAvailableTokenId);
}
```

**整段在做什麼**

- 記下 `vm.recordLogs()` 之後所有 emit 的 log
- mint 一顆 NFT（會 emit ERC721 的 `Transfer(address indexed from, address indexed to, uint256 indexed tokenId)`）
- 從 log 裡撈出 `tokenId`，確認跟我們預期的一樣

**`entries[0].topics[3]` 為什麼是 `[0][3]`？**

- `entries[0]`：第 0 筆 log（`mintNft` 過程中第一個 emit 的事件，就是 `Transfer`）
- `topics[3]`：log 的第 4 個 topic
  - `topics[0]` 永遠是 event signature 的 keccak256（`Transfer(address,address,uint256)` 的 hash）
  - `topics[1]` 是第 1 個 indexed 參數（`from`）
  - `topics[2]` 是第 2 個 indexed 參數（`to`）
  - `topics[3]` 是第 3 個 indexed 參數（`tokenId`）

**Indexed vs non-indexed 的差別**

- 一個 event 最多 **3 個 indexed 參數**（不算 topic[0]）
- indexed 參數會被存進 `topics[]`，可以在外面用 filter 搜尋
- non-indexed 參數會被打包進 `data` 欄位，要 decode 才能讀

---

## 六、常見誤區 Checklist

教學收尾用：

1. ⚠️ **雙層 Base64**：image 一層 + metadata 一層。畫出資料流圖能省一大堆解釋時間。
2. ⚠️ JSON 字串裡 key 必須**雙引號**，所以 Solidity 字串用單引號 wrap：`'{"name":"...'`。
3. ⚠️ `flipMood` 的權限檢查必須包含 `getApproved` 與 `isApprovedForAll`，否則掛在 marketplace 上會被擋。
4. ⚠️ `_safeMint` 之前要先設好 state（Checks-Effects-Interactions）。
5. ⚠️ `_baseURI()` 是 internal hook，**不會自動套用**。`tokenURI` 必須自己呼叫它。
6. ⚠️ `vm.readFile` 受 `foundry.toml` 的 `fs_permissions` 限制，路徑沒列出會 revert。
7. ⚠️ `vm.recordLogs()` 必須在事件觸發**之前**呼叫。
8. ⚠️ `entries[0].topics[3]` 的編號：`topics[0]` 是 event signature hash，`topics[1..3]` 是 3 個 indexed 參數，**最多 3 個**。
9. ⚠️ Mapping 對沒設過的 key 回傳預設值；`s_tokenIdToState[999]` 會回傳 `HAPPY`（==0），別用它判斷 token 存不存在，要用 `_requireOwned`。
10. ⚠️ `vm.prank` 只影響下一筆；連續多筆要用 `vm.startPrank/stopPrank`。
11. ⚠️ 「測試裡再現一次合約字串組裝邏輯」的寫法，兩邊一起錯就抓不到 bug。教學時要提醒這點。
