# Exercise 5：BasicNft 程式碼逐行解說

## 這篇要看什麼

這份文件搭配 `5_Exercise5.md` 使用。`5_Exercise5.md` 告訴你「**要打哪些指令**」，這份文件告訴你「**這些程式碼到底在做什麼**」、用到哪些 Solidity / Foundry 語法、以及初學者常踩的坑。

涵蓋的檔案：

| 檔案                                                                   | 行數  | 角色                           |
| ---------------------------------------------------------------------- | ----- | ------------------------------ |
| `src/BasicNft.sol`                                                     | 41    | NFT 合約本體                   |
| `script/DeployBasicNft.s.sol`                                          | 19    | 部署腳本                       |
| `script/Interactions.s.sol`（`MintBasicNft`、`UpdateBasicNftBaseUri`） | L9-30 | 鑄造 / 更新 baseURI 的互動腳本 |
| `test/BasicNftTest.t.sol`                                              | 63    | 測試                           |

## 必備前置觀念（請先看完）

- `lecture/NFT_Metadata_and_IPFS.md`：tokenURI 與 IPFS 的關係
- `lecture/Static_vs_Dynamic_NFTs.md`：靜態 NFT 的特性
- `lecture/ERC165_and_ERC4906.md`：為什麼這個合約要實作 IERC4906

Foundry 指令、cheatcode、Makefile 的共用知識請見 `lecture/walkthroughs/Foundry_Cheatcodes_and_Makefile.md`。

---

## 一、`src/BasicNft.sol` 逐段解說

### 1. License 與 Solidity 版本（L1-2）

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
```

**在做什麼**

- 第 1 行宣告開源授權。即便不寫合約也能 compile，但 compiler 會警告。
- 第 2 行宣告編譯器版本。`^0.8.18` 表示「`0.8.18` 以上、但小於 `0.9.0`」。

**語法補充**

| 寫法                        | 意義                                               |
| --------------------------- | -------------------------------------------------- |
| `pragma solidity 0.8.18;`   | 只允許剛好`0.8.18`                                 |
| `pragma solidity ^0.8.18;`  | `>=0.8.18 <0.9.0`（目前用這個）                    |
| `pragma solidity >=0.8.18;` | 不限上限（**不建議**，新版可能有 breaking change） |

**⚠️ 誤區**

- 部署時 Foundry 會自動下載合適的 compiler，不需要自己裝 `solc`。
- Solidity `0.8.x` 預設整數溢位會 revert（不需要 SafeMath），但這在 ERC-20 教材常被誤以為仍要手動防溢位。

---

### 2. Import OpenZeppelin（L4-8）

```solidity
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC4906} from "@openzeppelin/contracts/interfaces/IERC4906.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
```

**在做什麼**

- `{ERC721}` 是「named import」：只把這個 symbol 拉進來，避免污染命名空間。
- `@openzeppelin/contracts/...` 是 alias，由 `foundry.toml` 的 `remappings` 對應到 `lib/openzeppelin-contracts/contracts/...`。

**對照 `foundry.toml:5-7`**

```toml
remappings = [
  '@openzeppelin/contracts=lib/openzeppelin-contracts/contracts'
]
```

**⚠️ 誤區**

- 沒有 remapping 的話 `@openzeppelin/contracts/...` 會找不到檔案，IDE 會紅字、`forge build` 會失敗。
- 沒有 `git submodule update --init --recursive` 把 `lib/` 拉下來，import 也會失敗。
- 不要寫成 `import "..."`（沒有大括號）— 那會把整個檔案的所有 symbol 都帶進來，污染命名空間。把該檔案所有頂層宣告 + 它自己 import 的東西全都拉進你的命名空間

---

### 3. 合約宣告與多重繼承（L10）

```solidity
contract BasicNft is ERC721, Ownable, IERC4906 {
```

**在做什麼**

`BasicNft` 同時繼承三個東西：

- `ERC721`：標準的 NFT 實作（提供 `_safeMint`、`ownerOf`、`balanceOf`、`tokenURI` 預設行為等）
- `Ownable`：給「合約擁有者」概念與 `onlyOwner` modifier 「貼在某個 function 前面，會強制檢查 msg.sender == \_owner，不是的話直接 revert。」
- `IERC4906`：純介面，只有兩個事件 `MetadataUpdate` 「這一顆 NFT 的 metadata 變了，請重抓」與 `BatchMetadataUpdate` 「從 \_from 到 \_to 這一段範圍的 NFT metadata 都變了，請重抓」

**語法補充**

- Solidity 是支援多重繼承的，順序由「**最一般 → 最特定**」（C3 linearization）。
- `IERC4906` 是 interface，本身**沒有實作**，只是宣告事件。我們透過：
  1. 在 `setBaseTokenUri` 內 `emit BatchMetadataUpdate(...)`
  2. 在 `supportsInterface` 註冊 `type(IERC4906).interfaceId`

  來「實作」這個介面。

**⚠️ 誤區**

- 多重繼承時若有同名函式，必須在覆寫處用 `override(A, B)` 把所有父類列出（後面 `supportsInterface` 就是這樣寫）。

---

### 4. State variables 與命名慣例（L11-12）

```solidity
uint256 private s_tokenCounter;
string private s_baseTokenUri;
```

**在做什麼**

- `s_tokenCounter`：下一個要鑄造的 tokenId（從 0 開始遞增）
- `s_baseTokenUri`：metadata 資料夾的 base URI（例如 `ipfs://Qm.../`）

**⚠️ 誤區（非常重要）**

- `private` **不等於「鏈上看不到」**。
- `private` 只是限制「**其他合約** 無法用 `.s_baseTokenUri` 讀到」，但任何人都能用 `cast storage <地址> <slot>` 讀區塊鏈上的 storage slot。
- Solidity 的 private 是給程式員看的「請勿觸碰」標籤，不是給駭客看的「無法觸碰」鎖頭。鏈上沒有秘密。要藏就別放上去。真的要藏資料，不要放上鏈。

---

### 5. Constructor 與 chaining（L14-17）

```solidity
constructor(string memory initialBaseTokenUri) ERC721("Charizard", "006") Ownable(msg.sender) {
    s_tokenCounter = 0;
    s_baseTokenUri = initialBaseTokenUri;
}
```

**在做什麼**

- 接收一個 `initialBaseTokenUri`（部署腳本會傳 `ipfs://YOUR_METADATA_FOLDER_CID/`）
- 同時呼叫父類的 constructor：
  - `ERC721("Charizard", "006")` → NFT 的 `name` 與 `symbol`
  - `Ownable(msg.sender)` → 把部署者設為 owner

**語法補充**

- `string memory`：函式參數的字串型別必須加 data location（`memory` 或 `calldata`），否則 compile error。
  - `memory`：函式內可改、可 copy
  - `calldata`：唯讀、不可改、最省 gas（如果你不會修改它，**用 `calldata` 更好**）

**⚠️ 誤區（OpenZeppelin v5 重要變動）**

- OZ v4 的 `Ownable()` constructor 不需傳參，會自動把 `msg.sender` 設成 owner。
- OZ **v5（也就是這個專案用的版本）改成必須傳 `Ownable(msg.sender)`**，沒傳會 compile error。
- 很多舊教材還是 v4 寫法，照抄會跑不起來。

---

### 6. `mintNft` 鑄造一顆 NFT（L19-22）

```solidity
function mintNft() public {
    _safeMint(msg.sender, s_tokenCounter);
    s_tokenCounter++;
}
```

**在做什麼**

- 把當前 `s_tokenCounter` 的 tokenId 鑄給 `msg.sender`
- counter 加 1，下一次鑄造會用新的 tokenId

**語法補充：`_safeMint` vs `_mint`**

| 函式                | 行為                                                                      |
| ------------------- | ------------------------------------------------------------------------- |
| `_mint(to, id)`     | 直接寫進 storage，不檢查收款者                                            |
| `_safeMint(to, id)` | 若`to` 是合約地址，會呼叫 `to.onERC721Received(...)`，回傳值不對就 revert |

**為什麼要用 `_safeMint`**

防止 NFT 被誤鑄到「不會處理 NFT 的合約」裡，永久卡住。會做以下的步驟：

1. 先 mint 進去（這時候 storage 已經寫了，ownerOf(id) == to）
2. 檢查 to 是不是合約：用 to.code.length > 0 判斷。EOA 沒有 bytecode、合約有。
3. 如果是合約：呼叫 to.onERC721Received(operator, from, tokenId, data)
4. 比對回傳值：必須是 IERC721Receiver.onERC721Received.selector（一個固定的 4 bytes magic value）。沒回傳這個值 / 對方根本沒這個 function / 對方 revert，整筆 tx 都會 revert，連步驟 1 的 mint 都會被
   rollback。

**⚠️ 誤區**

- `_safeMint` 鑄到合約地址時，該合約**必須實作 `IERC721Receiver`** 並回傳正確的 magic value，否則會 revert。
- `s_tokenCounter++` 是「**先用後加**」（post-increment）：當下這次 mint 用的是舊值，加 1 是給下一次用。

---

### 7. `tokenURI` 拼接（L24-27）

```solidity
function tokenURI(uint256 tokenId) public view override returns (string memory) {
    _requireOwned(tokenId);
    return string.concat(s_baseTokenUri, Strings.toString(tokenId), ".json");
}
```

**在做什麼**

- 回傳這顆 NFT 的 metadata URI，格式為 `<baseURI><tokenId>.json`
- 例如 baseURI 是 `ipfs://Qm.../`、tokenId 是 0，回傳 `ipfs://Qm.../0.json`

**語法補充**

- `override`：因為 `ERC721` 父類有同名 `tokenURI`，我們覆寫它。沒寫 `override` 會 compile error。
- `_requireOwned(tokenId)`：OZ v5 的 internal helper，**檢查這個 tokenId 是否已經被鑄出來**。沒鑄就會 revert（`ERC721NonexistentToken`）。
- `Strings.toString(uint256)`：把 `uint256` 轉成可讀字串（`123` → `"123"`）

**⚠️ 誤區**

- `abi.encodePacked` 回傳的是 `bytes`，要再 `string(...)` cast 一次。
- 如果你忘記寫 `_requireOwned(tokenId)`，呼叫 `tokenURI(999)` 不會 revert，會回傳一個拼出來的假 URI（`ipfs://.../999.json`），讓 marketplace 以為這顆存在。

---

### 8. `setBaseTokenUri` 與 IERC4906 事件（L29-32）[ 非教材內容 ]

```solidity
function setBaseTokenUri(string memory newBaseTokenUri) public onlyOwner {
    s_baseTokenUri = newBaseTokenUri;
    emit BatchMetadataUpdate(0, type(uint256).max);
}
```

**在做什麼**

- 只有 owner 可以更新 baseURI（之後所有 `tokenURI(id)` 都會用新的 base）
- 發出 `BatchMetadataUpdate(0, type(uint256).max)`：告訴 marketplace「**從 token 0 到最大值的所有 NFT，metadata 都變了，請重抓**」

**語法補充**

- `onlyOwner` 是 `Ownable` 提供的 modifier；非 owner 呼叫會 revert `OwnableUnauthorizedAccount(msg.sender)`。
- `type(uint256).max` 是 `2^256 - 1`，常用來表示「無上限」。
- `BatchMetadataUpdate` 是 IERC4906 定義的事件，OZ 並沒有自動在 base 合約中 emit，**要自己在改變 metadata 的地方 emit**。

**⚠️ 誤區**

- 改 IPFS 上的檔案時，整個資料夾的 CID 會跟著變（IPFS 是 content-addressed）。所以正確流程是：
  1. 先把新 metadata 上傳 IPFS，拿到新 CID
  2. 呼叫 `setBaseTokenUri("ipfs://<新 CID>/")`
  3. 合約自動 emit `BatchMetadataUpdate`
- 如果只 emit 事件、忘了真的更新 `s_baseTokenUri`，marketplace 重抓也只會抓到舊的內容。

---

### 9. `baseTokenUri` getter（L34-36）

```solidity
function baseTokenUri() public view returns (string memory) {
    return s_baseTokenUri;
}
```

**為什麼要寫這個 getter？**

`s_baseTokenUri` 是 `private`，外部讀不到。手寫一個 `public view` getter 才能讓 cast / dapp 查詢當前 baseURI。

**對照：如果改成 `public`**

```solidity
string public s_baseTokenUri;  // 自動產生 getter，名字是 s_baseTokenUri()
```

但函式名會變成 `s_baseTokenUri()`，名稱有底線前綴對外不漂亮，所以這裡選擇 `private` + 手寫 `baseTokenUri()` getter。

---

### 10. `supportsInterface` 與 ERC165（L38-40）[ 非教材內容 ]

```solidity
function supportsInterface(bytes4 interfaceId) public view override(ERC721, IERC165) returns (bool) {
    return interfaceId == type(IERC4906).interfaceId || super.supportsInterface(interfaceId);
}
```

**在做什麼**

- 任何人（marketplace、indexer）可以呼叫 `supportsInterface(bytes4)` 詢問「你支援這個介面嗎」
- 我們明確回答「**支援 IERC4906**」，其他標準（ERC721、ERC165 自己）由 `super.supportsInterface` 處理。

**語法補充**

- `override(ERC721, IERC165)`：因為 `ERC721` 與 `IERC165`（被 IERC4906 間接繼承）都有 `supportsInterface`，**多重繼承覆寫必須把所有父類列出**。
- `type(IERC4906).interfaceId` 在 compile time 算出 `0x49064906`（IERC4906 所有 function selector 的 XOR）。
- `super.supportsInterface(interfaceId)`：把問題往父類傳，讓 ERC721 那邊回答 `0x80ac58cd`（ERC721）、`0x5b5e139f`（ERC721Metadata）、`0x01ffc9a7`（ERC165）這些 `0x49064906` (ERC4906)。

**⚠️ 誤區**

- 忘了 `super.supportsInterface(...)`，會把 ERC721、ERC165 的支援都「弄丟」，wallet / marketplace 會以為你不是 NFT。
- `bytes4` 不是 `bytes`，是固定 4 bytes 長度（function selector 的長度）。

---

## 二、`script/DeployBasicNft.s.sol` 逐段解說

```solidity
contract DeployBasicNft is Script {
    string public constant DEFAULT_BASE_TOKEN_URI = "ipfs://YOUR_METADATA_FOLDER_CID/";

    function run() external returns (BasicNft) {
        string memory baseTokenUri = vm.envOr("IPFS_BASE_TOKEN_URI", DEFAULT_BASE_TOKEN_URI);

        vm.startBroadcast();
        BasicNft basicNft = new BasicNft(baseTokenUri);
        vm.stopBroadcast();

        return basicNft;
    }
}
```

**逐段解說**

- `is Script`：繼承 forge-std 的 `Script`，自動拿到 `vm` 物件（Foundry cheatcodes）。
- `vm.envOr("IPFS_BASE_TOKEN_URI", DEFAULT_BASE_TOKEN_URI)`：
  - **有**設環境變數 `IPFS_BASE_TOKEN_URI`，就用環境變數的值 (.env)
  - **沒**設，就 fallback 到 `DEFAULT_BASE_TOKEN_URI`
- `vm.startBroadcast() / vm.stopBroadcast()`：之間的 state-changing 呼叫（`new BasicNft(...)`）會被打包成**真實交易**，用 `--private-key` 指定的 key 簽名送出。
- `return basicNft;`：把部署出的合約 instance 回傳，forge 會把 deployment 紀錄寫進 `broadcast/<chainId>/run-latest.json`，方便後續 `Interactions.s.sol` 查詢地址。

**⚠️ 誤區**

- `vm.envString("KEY")` 沒設環境變數會 **revert**；`vm.envOr("KEY", default)` 不會。
- 這個專案選 `vm.envOr` 是因為「沒設 IPFS CID 時也要能跑（用 placeholder 部署）」。
- 在 `vm.startBroadcast` **之前**的程式碼**不會**被廣播，例如讀檔、計算字串、組裝參數。這正是我們要的：只有真正要上鏈的呼叫才花 gas。

---

## 三、`script/Interactions.s.sol` 中的 BasicNft 部分

### `MintBasicNft`（L9-18）

```solidity
contract MintBasicNft is Script {
    function run() external {
        address mostRecentDeployment =
            DevOpsTools.get_most_recent_deployment("BasicNft", block.chainid);

        vm.startBroadcast();
        BasicNft(mostRecentDeployment).mintNft();
        vm.stopBroadcast();
    }
}
```

**在做什麼**

- 從 `broadcast/<chainId>/run-latest.json` 找到最近一次 `BasicNft` 部署地址
- 對它呼叫 `mintNft()`（會把 NFT 鑄給 broadcast 的私鑰持有者）

**語法補充**

- `BasicNft(mostRecentDeployment)` 是把 `address` cast 成 `BasicNft` 型別，這樣才能呼叫 `mintNft()`。
- `block.chainid`：當前鏈的 chainId（anvil 預設 31337、Sepolia 是 11155111、Mainnet 是 1）。

**⚠️ 誤區**

- 這個 helper 是讀檔，不是讀鏈。如果你刪了 `broadcast/` 資料夾，這個 function 就壞掉了。

### `UpdateBasicNftBaseUri`（L20-30） [ 非教材內容 ]

```solidity
contract UpdateBasicNftBaseUri is Script {
    function run() external {
        string memory newBaseTokenUri = vm.envString("NEW_IPFS_BASE_TOKEN_URI");
        ...
```

**為什麼這裡用 `vm.envString` 而不是 `vm.envOr`？**

更新 baseURI 是**有破壞性的動作**——如果 `NEW_IPFS_BASE_TOKEN_URI` 沒設，與其用 fallback 把 base 改成預設 placeholder，**寧可直接 revert**。`vm.envString` 沒設變數會 revert，正合此用途。

**Makefile 對應**（`Makefile:48-50`）：

```makefile
update-base-uri:
    @if [ -z "$(NEW_IPFS_BASE_TOKEN_URI)" ]; then echo "NEW_IPFS_BASE_TOKEN_URI is required..."; exit 1; fi
    @NEW_IPFS_BASE_TOKEN_URI=$(NEW_IPFS_BASE_TOKEN_URI) forge script ... :UpdateBasicNftBaseUri $(NETWORK_ARGS)
```

Makefile 也做了一層保護，這是**雙保險**。

---

## 四、`test/BasicNftTest.t.sol` 逐段解說

### 測試 setup（L9-18）

```solidity
contract BasicNftTest is Test {
    BasicNft private basicNft;

    string public constant BASE_TOKEN_URI = "ipfs://QmMetaDataFolder/";
    string public constant UPDATED_BASE_TOKEN_URI = "ipfs://QmUpdatedMetaDataFolder/";
    address public USER = makeAddr("user");

    function setUp() public {
        basicNft = new BasicNft(BASE_TOKEN_URI);
    }
```

**語法補充**

- `is Test`：拿到 `vm`、`assertEq`、`makeAddr` 等測試工具。
- `setUp()` 在**每個** `testXxx()` 之前都會被呼叫一次，確保每個 test 都從乾淨狀態開始。
- `makeAddr("user")`：把字串 hash 成一個 deterministic 的 address，比 `address(1)` 可讀。
- `string public constant`：constant 必須在宣告時賦值，編譯時就決定，幾乎不花 gas。

**⚠️ 誤區**

- test contract 的 storage 在每個 test 之間**會 reset**（forge 開新 EVM state）。所以不能依賴上一個 test 留下的 state。
- `makeAddr` 產生的地址沒有 ETH 餘額，要轉帳測試的話要 `vm.deal(USER, 1 ether)` 補餘額。

### 簡單 view 測試（L20-26）

```solidity
function testNftNameIsCorrect() public view {
    assertEq(basicNft.name(), "Charizard");
}
```

**為什麼可以加 `view`？**

這個 test 沒有寫任何 state，加上 `view` 讓 forge 可以省掉 gas snapshot。**只要你的 test 沒改 state 就應該加 `view`**。

| 修飾子 | 可以讀 state？ | 可以寫 state？ | 範例                      |
| ------ | :------------: | :------------: | ------------------------- |
| `pure` |       ❌       |       ❌       | 純數學運算`a + b`         |
| `view` |       ✅       |       ❌       | getter、`balanceOf(addr)` |
| (預設) |       ✅       |       ✅       | `transfer`、`mint`        |

### `testCanMintAndHaveBalance`（L28-35）

```solidity
function testCanMintAndHaveBalance() public {
    vm.prank(USER);
    basicNft.mintNft();

    assertEq(basicNft.balanceOf(USER), 1);
    assertEq(basicNft.ownerOf(0), USER);
    assertEq(basicNft.tokenURI(0), string.concat(BASE_TOKEN_URI, "0.json"));
}
```

**`vm.prank(USER)` 在做什麼**

下一筆呼叫的 `msg.sender` 會被臨時換成 `USER`。所以 `mintNft()` 會把 NFT 鑄給 `USER`。

**⚠️ 誤區（極度重要）**

- `vm.prank` **只影響下一筆**呼叫。
- 如果你連續寫：

  ```solidity
  vm.prank(USER);
  basicNft.mintNft();   // ← msg.sender 是 USER
  basicNft.mintNft();   // ← msg.sender 已經 reset 回測試合約地址！
  ```

- 要連續多筆都 prank，用 `vm.startPrank(USER) ... vm.stopPrank()`。

### `testOwnerCanUpdateBaseTokenUri`（L37-43）[ 非教材內容 ]

```solidity
function testOwnerCanUpdateBaseTokenUri() public {
    vm.expectEmit(true, true, true, true);
    emit IERC4906.BatchMetadataUpdate(0, type(uint256).max);
    basicNft.setBaseTokenUri(UPDATED_BASE_TOKEN_URI);

    assertEq(basicNft.baseTokenUri(), UPDATED_BASE_TOKEN_URI);
}
```

**`vm.expectEmit(true, true, true, true)` 的四個 bool**

對應 (topic1, topic2, topic3, data) 是否要比對：

- `true, true, true, true`：四個欄位都嚴格比對
- `false, false, false, false`：只比對 event signature，不比對欄位
- ERC4906 的 `BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId)` 兩個參數**都不是 indexed**，所以 topic2/3 其實沒東西比，但寫 `true` 也沒事。

**呼叫順序**

```
vm.expectEmit(...);     ← 1. 先告訴 forge「下一個 state-changing call 我預期會 emit 什麼」
emit Xxx(...);          ← 2. 寫一個「預期 emit 的事件」當作比對範本
realCall();             ← 3. 真的呼叫，forge 會比對它真的 emit 的事件是不是符合
```

**⚠️ 誤區**

- 順序顛倒（先呼叫再 expect）會 fail。
- `expectEmit` 後**馬上**就要 emit 範本與真的呼叫，中間不能再插別的 cheatcode。

### `testNonOwnerCannotUpdateBaseTokenUri`（L45-49）[ 非教材內容 ]

```solidity
function testNonOwnerCannotUpdateBaseTokenUri() public {
    vm.prank(USER);
    vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, USER));
    basicNft.setBaseTokenUri(UPDATED_BASE_TOKEN_URI);
}
```

**Custom error 的 expectRevert 寫法**

- OZ v5 把所有 `require(..., "string")` 改成 custom error，例如 `OwnableUnauthorizedAccount(address account)`。
- 要比對到參數，必須用 `abi.encodeWithSelector(Error.selector, args...)`。

**⚠️ 誤區**

- 用字串 `vm.expectRevert("Ownable: caller is not the owner")` 是 **OZ v4 的寫法**，在 v5 不會 match，test 會 fail。
- `vm.expectRevert` 也是「**只影響下一筆**」呼叫，跟 `vm.prank` 一樣。所以 `vm.prank` + `vm.expectRevert` + 真的呼叫，這個順序不能亂。

### `testTokenUriUsesUpdatedBaseTokenUri`（L51-58）[ 非教材內容 ]

```solidity
function testTokenUriUsesUpdatedBaseTokenUri() public {
    vm.prank(USER);
    basicNft.mintNft();

    basicNft.setBaseTokenUri(UPDATED_BASE_TOKEN_URI);

    assertEq(basicNft.tokenURI(0), string.concat(UPDATED_BASE_TOKEN_URI, "0.json"));
}
```

**驗證的事**

- USER 鑄了 token 0
- 接著 test contract（**owner**，因為 `setUp` 裡 `new BasicNft(...)` 是 test contract 部署的）改了 baseURI
- token 0 的 tokenURI **馬上**反映新的 baseURI

這就是 **mutable metadata** 的價值：不必 redeploy 合約，metadata folder 就能換。

### `testSupportsErc4906Interface`（L60-62）[ 非教材內容 ]

```solidity
function testSupportsErc4906Interface() public view {
    assertTrue(basicNft.supportsInterface(type(IERC4906).interfaceId));
}
```

直接驗證 ERC165 註冊正確。如果你不小心把 `supportsInterface` 寫錯（例如忘了 `super.supportsInterface(...)`、忘了或寫錯 `type(IERC4906).interfaceId`），這個 test 會 fail。

## 六、常見誤區 Checklist

教學時可以拿這份來當收尾的 quick review：

1. ⚠️ `private` state variable **不等於鏈上看不到**，用 `cast storage` 還是讀得到。
2. ⚠️ OpenZeppelin **v5** 的 `Ownable()` constructor 必須傳 `Ownable(msg.sender)`，v4 寫法會 compile error。
3. ⚠️ `_safeMint` 鑄到合約地址時，該合約必須實作 `IERC721Receiver`，否則 revert。
4. ⚠️ `tokenURI()` 內忘了 `_requireOwned(tokenId)`，查不存在的 tokenId 不會 revert。
5. ⚠️ 多重繼承覆寫必須 `override(A, B)` 列出所有父類。
6. ⚠️ `vm.prank` **只影響下一筆**呼叫；要連續多筆用 `vm.startPrank/stopPrank`。
7. ⚠️ `vm.expectRevert` 對 OZ v5 custom error 必須用 `abi.encodeWithSelector(Error.selector, args)`，舊的字串寫法會 fail。
8. ⚠️ `vm.expectEmit` 必須在「真正會 emit 的呼叫」之前緊接著 emit 範本，順序不能亂。
9. ⚠️ IPFS folder 改檔案 → CID 變 → 老合約還指向舊 CID。要嘛用 `setBaseTokenUri` 改、要嘛事先用 IPNS / pinning service / 不可變的 CID 設計。
10. ⚠️ `DevOpsTools.get_most_recent_deployment` 是讀 `broadcast/` 資料夾，不是讀鏈；換 chainId / 刪資料夾就找不到。
11. ⚠️ `vm.envString` 沒設變數會 revert；`vm.envOr` 不會。挑哪個取決於「沒值是不是該停下」。
