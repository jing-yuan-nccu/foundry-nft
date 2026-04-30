import React, { useEffect, useMemo, useState } from "https://esm.sh/react@18.3.1";
import { createRoot } from "https://esm.sh/react-dom@18.3.1/client";
import { ethers } from "https://cdn.jsdelivr.net/npm/ethers@6.13.4/+esm";

const h = React.createElement;

const LOCAL_CHAIN = {
  chainId: "0x7a69",
  chainName: "Anvil Local",
  nativeCurrency: { name: "Ether", symbol: "ETH", decimals: 18 },
  rpcUrls: ["http://127.0.0.1:8545"],
};

const abi = [
  "function mintNft() external",
  "function refreshMetadata(uint256 tokenId) external",
  "function getTokenCounter() view returns (uint256)",
  "function ownerOf(uint256 tokenId) view returns (address)",
  "function tokenURI(uint256 tokenId) view returns (string)",
  "function getPokemon(uint256 tokenId) view returns (uint8 species, uint8 stage, uint256 birthTime, uint256 age)",
  "function getTimeUntilNextStage(uint256 tokenId) view returns (uint256)",
];

const speciesNames = ["Squirtle", "Charmander", "Bulbasaur"];
const stageNames = ["Baby", "Teen", "Adult"];
const assetVersion = "pokemon-svg-v2";
const questStages = [
  { id: 1, label: "Stage 1 - ERC20" },
  { id: 2, label: "Stage 2 - ERC721" },
  { id: 3, label: "Stage 3 - Onchain ERC721" },
];

function App() {
  const [account, setAccount] = useState("");
  const [chainId, setChainId] = useState("");
  const [provider, setProvider] = useState(null);
  const [signer, setSigner] = useState(null);
  const [contractAddress, setContractAddress] = useState(
    localStorage.getItem("pokemonContractAddress") || "",
  );
  const [contractStatus, setContractStatus] = useState("missing");
  const [cards, setCards] = useState([]);
  const [status, setStatus] = useState("Connect a wallet and enter a contract address.");
  const [busy, setBusy] = useState(false);
  const [questForm, setQuestForm] = useState({
    stage: "1",
    contractAddress: "",
    txHash: "",
    tokenId: "0",
  });
  const [questStatus, setQuestStatus] = useState("Submit a Sepolia deployment to verify a learning stage.");
  const [questSubmissions, setQuestSubmissions] = useState([]);

  const contract = useMemo(() => {
    if (!signer || !ethers.isAddress(contractAddress)) {
      return null;
    }
    return new ethers.Contract(contractAddress, abi, signer);
  }, [contractAddress, signer]);

  const isLocalChain = chainId === LOCAL_CHAIN.chainId;
  const canUseContract = Boolean(account && contract && isLocalChain && contractStatus === "ready" && !busy);

  useEffect(() => {
    if (!window.ethereum) {
      return;
    }

    const handleAccountsChanged = (accounts) => {
      initializeWalletFromAccounts(accounts);
      if (!accounts[0]) {
        setCards([]);
        setStatus("Wallet disconnected.");
      }
    };

    const handleChainChanged = (newChainId) => {
      setChainId(newChainId);
      setCards([]);
      setStatus(newChainId === LOCAL_CHAIN.chainId ? "Anvil local network selected." : "Switch to Anvil local network.");
    };

    window.ethereum.request({ method: "eth_chainId" }).then(setChainId).catch(() => {});
    window.ethereum.request({ method: "eth_accounts" }).then(initializeWalletFromAccounts).catch(() => {});
    window.ethereum.on("accountsChanged", handleAccountsChanged);
    window.ethereum.on("chainChanged", handleChainChanged);

    return () => {
      window.ethereum.removeListener("accountsChanged", handleAccountsChanged);
      window.ethereum.removeListener("chainChanged", handleChainChanged);
    };
  }, []);

  useEffect(() => {
    localStorage.setItem("pokemonContractAddress", contractAddress.trim());
  }, [contractAddress]);

  useEffect(() => {
    let cancelled = false;

    async function validateContractAddress() {
      if (!contractAddress.trim()) {
        setContractStatus("missing");
        setCards([]);
        return;
      }

      if (!ethers.isAddress(contractAddress.trim())) {
        setContractStatus("invalid");
        setCards([]);
        return;
      }

      if (!provider || !isLocalChain) {
        setContractStatus("unchecked");
        return;
      }

      try {
        setContractStatus("checking");
        const code = await provider.getCode(contractAddress.trim());
        if (cancelled) {
          return;
        }
        setContractStatus(code === "0x" ? "no-code" : "ready");
      } catch {
        if (!cancelled) {
          setContractStatus("error");
        }
      }
    }

    validateContractAddress();

    return () => {
      cancelled = true;
    };
  }, [contractAddress, provider, isLocalChain]);

  useEffect(() => {
    if (!canUseContract) {
      return;
    }

    loadCollection(contract, account, { silent: true });
  }, [account, contract, canUseContract]);

  useEffect(() => {
    if (!account) {
      setQuestSubmissions([]);
      return;
    }

    loadQuestSubmissions(account);
  }, [account]);

  async function initializeWalletFromAccounts(accounts) {
    const nextAccount = accounts[0] || "";
    setAccount(nextAccount);

    if (!nextAccount || !window.ethereum) {
      setProvider(null);
      setSigner(null);
      setCards([]);
      return;
    }

    const browserProvider = new ethers.BrowserProvider(window.ethereum);
    const connectedSigner = await browserProvider.getSigner();
    const network = await browserProvider.getNetwork();

    setProvider(browserProvider);
    setSigner(connectedSigner);
    setChainId(`0x${network.chainId.toString(16)}`);
    setStatus(network.chainId === 31337n ? "Wallet restored on Anvil." : "Wallet restored. Switch to Anvil local network.");
  }

  function clearContractAddress() {
    setContractAddress("");
    setContractStatus("missing");
    setCards([]);
    localStorage.removeItem("pokemonContractAddress");
    setStatus("Contract address cleared. Paste the latest Anvil deployment address.");
  }

  function clearLocalDemoState() {
    clearContractAddress();
    setCards([]);
    setStatus("Local demo state cleared. Redeploy the contract if Anvil was restarted.");
  }

  async function connectWallet() {
    if (!window.ethereum) {
      setStatus("MetaMask is not available in this browser.");
      return;
    }

    try {
      setBusy(true);
      setStatus("Switching to Anvil local network...");
      await switchToLocalChain();

      const browserProvider = new ethers.BrowserProvider(window.ethereum);
      const accounts = await browserProvider.send("eth_requestAccounts", []);
      const connectedSigner = await browserProvider.getSigner();
      const network = await browserProvider.getNetwork();

      setProvider(browserProvider);
      setSigner(connectedSigner);
      setAccount(accounts[0] || "");
      setChainId(`0x${network.chainId.toString(16)}`);
      setStatus("Wallet connected. Enter the deployed contract address.");
    } catch (error) {
      setStatus(readError(error));
    } finally {
      setBusy(false);
    }
  }

  async function switchToLocalChain() {
    try {
      await window.ethereum.request({
        method: "wallet_switchEthereumChain",
        params: [{ chainId: LOCAL_CHAIN.chainId }],
      });
    } catch (error) {
      if (error.code !== 4902) {
        throw error;
      }
      await window.ethereum.request({
        method: "wallet_addEthereumChain",
        params: [LOCAL_CHAIN],
      });
    }
  }

  async function resetWalletConnection() {
    setCards([]);
    setAccount("");
    setProvider(null);
    setSigner(null);
    setStatus("Wallet connection reset. Connect again and choose the imported Anvil account.");

    if (!window.ethereum) {
      return;
    }

    try {
      await window.ethereum.request({
        method: "wallet_revokePermissions",
        params: [{ eth_accounts: {} }],
      });
    } catch {
      // Some wallet versions do not expose permission revocation to dApps.
    }
  }

  async function mintPokemon() {
    if (!contract) {
      setStatus("Enter the deployed PokemonNft contract address.");
      return;
    }

    try {
      setBusy(true);
      setStatus("Drawing Pokemon...");
      const tx = await contract.mintNft();
      const receipt = await tx.wait();
      setStatus(`Minted in block ${receipt.blockNumber}. Loading your collection...`);
      await loadCollection(contract, account);
    } catch (error) {
      setStatus(readError(error));
    } finally {
      setBusy(false);
    }
  }

  async function loadCollection(activeContract = contract, activeAccount = account, options = {}) {
    if (!activeContract || !activeAccount) {
      setStatus("Connect wallet and contract first.");
      return;
    }

    try {
      if (!options.silent) {
        setBusy(true);
        setStatus("Loading collection...");
      }
      const total = Number(await activeContract.getTokenCounter());
      const loadedCards = [];

      for (let tokenId = 0; tokenId < total; tokenId++) {
        try {
          const owner = await activeContract.ownerOf(tokenId);
          if (owner.toLowerCase() !== activeAccount.toLowerCase()) {
            continue;
          }

          const [uri, pokemon, nextStage] = await Promise.all([
            activeContract.tokenURI(tokenId),
            activeContract.getPokemon(tokenId),
            activeContract.getTimeUntilNextStage(tokenId),
          ]);
          const metadata = await fetchMetadata(uri);
          loadedCards.push({ tokenId, uri, pokemon, nextStage: Number(nextStage), metadata });
        } catch {
          // Local demo token scans should continue even if one token read fails.
        }
      }

      setCards(loadedCards);
      if (!options.silent) {
        setStatus(loadedCards.length ? "Collection loaded." : "No Pokemon found for this wallet.");
      }
    } catch (error) {
      if (!options.silent) {
        setStatus(readError(error));
      }
    } finally {
      if (!options.silent) {
        setBusy(false);
      }
    }
  }

  async function refreshMetadata(tokenId) {
    try {
      setBusy(true);
      setStatus(`Refreshing token #${tokenId} metadata...`);
      const tx = await contract.refreshMetadata(tokenId);
      await tx.wait();
      setStatus(`Refresh event emitted for token #${tokenId}.`);
      await loadCollection();
    } catch (error) {
      setStatus(readError(error));
    } finally {
      setBusy(false);
    }
  }

  function updateQuestForm(field, value) {
    setQuestForm((current) => ({ ...current, [field]: value }));
  }

  async function submitQuestVerification() {
    if (!account) {
      setQuestStatus("Connect a wallet first so the verifier knows which student is submitting.");
      return;
    }

    try {
      setBusy(true);
      setQuestStatus("Verifying Sepolia contract...");
      const response = await fetch("/api/verify-submission", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          student: account,
          stage: Number(questForm.stage),
          contractAddress: questForm.contractAddress.trim(),
          txHash: questForm.txHash.trim(),
          tokenId: questForm.tokenId.trim() || "0",
        }),
      });
      const result = await response.json();
      if (!result.ok) {
        setQuestStatus(result.reason || "Verification failed.");
      } else {
        setQuestStatus(`${result.message} ${result.nextAction}`);
        setQuestForm((current) => ({ ...current, contractAddress: "", txHash: "" }));
      }
      await loadQuestSubmissions(account);
    } catch (error) {
      setQuestStatus(readError(error));
    } finally {
      setBusy(false);
    }
  }

  async function loadQuestSubmissions(student = account) {
    if (!student) {
      return;
    }

    try {
      const response = await fetch(`/api/submissions?student=${student}`, { cache: "no-store" });
      const result = await response.json();
      if (result.ok) {
        setQuestSubmissions(result.submissions || []);
      }
    } catch {
      // Submission history is helpful, but it should not block the main demo.
    }
  }

  return h(
    React.Fragment,
    null,
    h(Header, {
      account,
      chainId,
      busy,
      isLocalChain,
      onConnect: connectWallet,
      onSwitchNetwork: async () => {
        try {
          await switchToLocalChain();
          setChainId(LOCAL_CHAIN.chainId);
          setStatus("Anvil local network selected.");
        } catch (error) {
          setStatus(readError(error));
        }
      },
      onReset: resetWalletConnection,
    }),
    h(
      "main",
      null,
      h(
        "section",
        { className: "draw-panel" },
        h(
          "div",
          { className: "draw-copy" },
          h("p", { className: "eyebrow" }, "Draw, wait, evolve"),
          h("h2", null, "Your Pokemon grows with time."),
          h(
            "p",
            null,
            "Mint a random Pokemon NFT on local Anvil. It starts as Baby, becomes Teen after 60 seconds, and reaches Adult after 180 seconds.",
          ),
          h(
            "div",
            { className: "contract-row" },
            h(
              "div",
              { className: "field-head" },
              h("label", { htmlFor: "contractAddress" }, "Contract"),
              h("span", { className: `contract-state ${contractStatus}` }, contractStatusLabel(contractStatus)),
            ),
            h("input", {
              id: "contractAddress",
              placeholder: "0x...",
              autoComplete: "off",
              value: contractAddress,
              onChange: (event) => setContractAddress(event.target.value.trim()),
            }),
            h(
              "div",
              { className: "inline-actions" },
              h("button", { className: "text-button", type: "button", onClick: clearContractAddress }, "Clear contract"),
              h("button", { className: "text-button", type: "button", onClick: clearLocalDemoState }, "Reset local demo"),
            ),
          ),
        ),
        h(
          "div",
          { className: "draw-action" },
          h("div", { className: "card-preview" }, h("span", null, "?")),
          h("button", { className: "button primary", disabled: !canUseContract, onClick: mintPokemon }, "Draw Pokemon"),
          h("p", { className: "status" }, status),
        ),
      ),
      h(QuestPanel, {
        account,
        busy,
        questForm,
        questStatus,
        submissions: questSubmissions,
        onChange: updateQuestForm,
        onSubmit: submitQuestVerification,
        onReload: () => loadQuestSubmissions(),
      }),
      h(
        "section",
        { className: "collection" },
        h(
          "div",
          { className: "section-title" },
          h("div", null, h("p", { className: "eyebrow" }, "Wallet collection"), h("h2", null, "My Pokemon")),
          h(
            "div",
            { className: "collection-actions" },
            h("button", { className: "button secondary", disabled: !canUseContract, onClick: () => loadCollection() }, "Reload"),
          ),
        ),
        h(CollectionGrid, { cards, onRefresh: refreshMetadata }),
      ),
    ),
  );
}

function QuestPanel({ account, busy, questForm, questStatus, submissions, onChange, onSubmit, onReload }) {
  return h(
    "section",
    { className: "quest-panel" },
    h(
      "div",
      { className: "section-title" },
      h(
        "div",
        null,
        h("p", { className: "eyebrow" }, "Sepolia quest"),
        h("h2", null, "Verify deployments to evolve your learning card."),
      ),
      h("button", { className: "button secondary", type: "button", disabled: !account, onClick: onReload }, "Reload history"),
    ),
    h(
      "div",
      { className: "quest-layout" },
      h(
        "div",
        { className: "quest-form" },
        h("label", { htmlFor: "questStage" }, "Challenge stage"),
        h(
          "select",
          {
            id: "questStage",
            value: questForm.stage,
            onChange: (event) => onChange("stage", event.target.value),
          },
          questStages.map((stage) => h("option", { key: stage.id, value: String(stage.id) }, stage.label)),
        ),
        h("label", { htmlFor: "questContract" }, "Sepolia contract address"),
        h("input", {
          id: "questContract",
          placeholder: "0x...",
          autoComplete: "off",
          value: questForm.contractAddress,
          onChange: (event) => onChange("contractAddress", event.target.value.trim()),
        }),
        h("label", { htmlFor: "questTx" }, "Deployment transaction hash"),
        h("input", {
          id: "questTx",
          placeholder: "0x... optional if owner() proves ownership",
          autoComplete: "off",
          value: questForm.txHash,
          onChange: (event) => onChange("txHash", event.target.value.trim()),
        }),
        h("label", { htmlFor: "questTokenId" }, "ERC721 token id"),
        h("input", {
          id: "questTokenId",
          placeholder: "0",
          autoComplete: "off",
          value: questForm.tokenId,
          onChange: (event) => onChange("tokenId", event.target.value.trim()),
        }),
        h(
          "button",
          {
            className: "button primary",
            type: "button",
            disabled: busy || !account,
            onClick: onSubmit,
          },
          "Verify Sepolia Contract",
        ),
        h("p", { className: "quest-status" }, account ? questStatus : "Connect a wallet before submitting a quest."),
      ),
      h(QuestHistory, { submissions }),
    ),
  );
}

function QuestHistory({ submissions }) {
  if (!submissions.length) {
    return h("div", { className: "quest-history empty" }, "No Sepolia quest submissions for this wallet yet.");
  }

  return h(
    "div",
    { className: "quest-history" },
    submissions.slice(0, 6).map((submission) =>
      h(
        "div",
        { className: `submission ${submission.status}`, key: submission.id },
        h(
          "div",
          { className: "submission-head" },
          h("strong", null, submission.stageLabel || `Stage ${submission.stage}`),
          h("span", null, submission.status),
        ),
        h("code", null, shortAddress(submission.contractAddress || "0x0000000000000000000000000000000000000000")),
        h("p", null, submission.status === "passed" ? "Verification passed." : submission.reason),
      ),
    ),
  );
}

function Header({ account, chainId, busy, isLocalChain, onConnect, onSwitchNetwork, onReset }) {
  const label = account ? `${shortAddress(account)} · ${isLocalChain ? "Anvil 31337" : `chain ${Number(chainId)}`}` : "No wallet";

  return h(
    "header",
    { className: "topbar" },
    h("div", null, h("p", { className: "eyebrow" }, "Growth Gacha"), h("h1", null, "Pokemon NFT Draw")),
    h(
      "div",
      { className: "wallet" },
      h("span", { className: "network-label" }, label),
      account && !isLocalChain
        ? h("button", { className: "button secondary", disabled: busy, onClick: onSwitchNetwork }, "Switch Anvil")
        : null,
      account
        ? h("button", { className: "button secondary", disabled: busy, onClick: onReset }, "Reset Wallet")
        : null,
      h("button", { className: "button secondary", disabled: busy, onClick: onConnect }, account ? "Reconnect" : "Connect"),
    ),
  );
}

function CollectionGrid({ cards, onRefresh }) {
  if (!cards.length) {
    return h("div", { className: "grid empty" }, "No Pokemon loaded yet.");
  }

  return h(
    "div",
    { className: "grid" },
    cards.map((card) => h(PokemonCard, { key: card.tokenId, card, onRefresh })),
  );
}

function PokemonCard({ card, onRefresh }) {
  const species = speciesNames[Number(card.pokemon.species)] || "Unknown";
  const stage = stageNames[Number(card.pokemon.stage)] || "Unknown";
  const age = Number(card.pokemon.age);

  return h(
    "article",
    { className: "pokemon-card" },
    h("img", { src: withAssetVersion(card.metadata.image), alt: card.metadata.name }),
    h(
      "div",
      { className: "pokemon-card-body" },
      h("div", { className: "pokemon-name" }, h("span", null, `#${card.tokenId} ${species}`), h("span", { className: "badge" }, stage)),
      h(
        "div",
        { className: "stats" },
        h("span", null, `Age: ${formatSeconds(age)}`),
        h("span", null, `Next evolution: ${card.nextStage === 0 ? "Fully grown" : formatSeconds(card.nextStage)}`),
      ),
      h(
        "div",
        { className: "card-actions" },
        h("button", { className: "button secondary", onClick: () => onRefresh(card.tokenId) }, "Refresh Metadata"),
      ),
    ),
  );
}

async function fetchMetadata(uri) {
  const response = await fetch(uri, { cache: "no-store" });
  if (!response.ok) {
    throw new Error(`Could not load metadata: ${uri}`);
  }
  return response.json();
}

function withAssetVersion(url) {
  const separator = url.includes("?") ? "&" : "?";
  return `${url}${separator}v=${assetVersion}`;
}

function contractStatusLabel(status) {
  if (status === "ready") {
    return "Contract found";
  }
  if (status === "checking") {
    return "Checking";
  }
  if (status === "no-code") {
    return "No contract at address";
  }
  if (status === "invalid") {
    return "Invalid address";
  }
  if (status === "unchecked") {
    return "Switch Anvil to check";
  }
  if (status === "error") {
    return "Check failed";
  }
  return "No contract";
}

function shortAddress(address) {
  return `${address.slice(0, 6)}...${address.slice(-4)}`;
}

function formatSeconds(totalSeconds) {
  const minutes = Math.floor(totalSeconds / 60);
  const seconds = totalSeconds % 60;
  return `${String(minutes).padStart(2, "0")}:${String(seconds).padStart(2, "0")}`;
}

function readError(error) {
  return error?.shortMessage || error?.reason || error?.message || "Something went wrong.";
}

createRoot(document.querySelector("#root")).render(h(App));
