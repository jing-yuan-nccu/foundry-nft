const http = require("http");
const fs = require("fs");
const path = require("path");

const root = __dirname;
loadEnvFile(path.join(root, "..", ".env"));
const port = Number(process.env.PORT || 5173);
const dataDir = path.join(root, "data");
const submissionsPath = path.join(dataDir, "submissions.json");

const types = {
  ".html": "text/html; charset=utf-8",
  ".css": "text/css; charset=utf-8",
  ".js": "text/javascript; charset=utf-8",
  ".json": "application/json; charset=utf-8",
  ".svg": "image/svg+xml; charset=utf-8",
};

const selectors = {
  name: "0x06fdde03",
  symbol: "0x95d89b41",
  decimals: "0x313ce567",
  totalSupply: "0x18160ddd",
  balanceOf: "0x70a08231",
  owner: "0x8da5cb5b",
  supportsInterface: "0x01ffc9a7",
  ownerOf: "0x6352211e",
  tokenURI: "0xc87b56dd",
};

const stages = {
  1: { label: "ERC20" },
  2: { label: "ERC721" },
  3: { label: "Onchain ERC721" },
};

const server = http.createServer(async (req, res) => {
  const url = new URL(req.url, `http://${req.headers.host}`);

  try {
    if (req.method === "OPTIONS") {
      sendJson(res, 204, {});
      return;
    }

    if (req.method === "POST" && url.pathname === "/api/verify-submission") {
      const body = await readJsonBody(req);
      const result = await verifySubmission(body);
      sendJson(res, result.ok ? 200 : 400, result);
      return;
    }

    if (req.method === "GET" && url.pathname === "/api/submissions") {
      const student = normalizeAddress(url.searchParams.get("student") || "");
      const submissions = readSubmissions().filter(
        (submission) => !student || submission.student.toLowerCase() === student.toLowerCase(),
      );
      sendJson(res, 200, { ok: true, submissions });
      return;
    }

    serveStatic(url, res);
  } catch (error) {
    sendJson(res, 500, { ok: false, reason: error.message || "Server error" });
  }
});

server.listen(port, "127.0.0.1", () => {
  console.log(`Pokemon Growth Gacha frontend running at http://127.0.0.1:${port}`);
});

async function verifySubmission(body) {
  const rpcUrl = process.env.SEPOLIA_RPC_URL;
  if (!rpcUrl) {
    return fail("SEPOLIA_RPC_URL is not set on the frontend server process.", body);
  }

  const student = normalizeAddress(body.student);
  const contractAddress = normalizeAddress(body.contractAddress);
  const stage = Number(body.stage);
  const tokenId = body.tokenId === undefined || body.tokenId === "" ? 0n : BigInt(body.tokenId);
  const txHash = typeof body.txHash === "string" ? body.txHash.trim() : "";

  if (!student) {
    return fail("Student wallet address is invalid.", body);
  }
  if (!contractAddress) {
    return fail("Submitted contract address is invalid.", body);
  }
  if (!stages[stage]) {
    return fail("Stage must be 1, 2, or 3.", body);
  }

  const existing = readSubmissions();
  if (
    stage > 1 &&
    !existing.some(
      (submission) =>
        submission.status === "passed" &&
        submission.student.toLowerCase() === student.toLowerCase() &&
        submission.stage === stage - 1,
    )
  ) {
    return fail(`Stage ${stage - 1} must be completed before submitting stage ${stage}.`, body);
  }
  const duplicate = existing.find(
    (submission) =>
      submission.status === "passed" && submission.contractAddress.toLowerCase() === contractAddress.toLowerCase(),
  );
  if (duplicate) {
    return fail(`This contract was already used by ${duplicate.student}.`, body);
  }

  const chainId = await rpc(rpcUrl, "eth_chainId", []);
  if (chainId !== "0xaa36a7") {
    return fail(`RPC is connected to chain ${chainId}, not Sepolia 0xaa36a7.`, body);
  }

  const code = await rpc(rpcUrl, "eth_getCode", [contractAddress, "latest"]);
  if (!code || code === "0x") {
    return fail("No contract bytecode was found at this address on Sepolia.", body);
  }

  const ownership = await verifyOwnership(rpcUrl, student, contractAddress, txHash);
  if (!ownership.ok) {
    return fail(ownership.reason, body);
  }

  let checks;
  try {
    if (stage === 1) {
      checks = await verifyErc20(rpcUrl, student, contractAddress);
    } else if (stage === 2) {
      checks = await verifyErc721(rpcUrl, student, contractAddress, tokenId, false);
    } else {
      checks = await verifyErc721(rpcUrl, student, contractAddress, tokenId, true);
    }
  } catch (error) {
    return fail(error.message || "Verification checks failed.", body);
  }

  if (!checks.ok) {
    return fail(checks.reason, body, checks.checks);
  }

  const record = {
    id: `${Date.now()}-${Math.random().toString(16).slice(2)}`,
    status: "passed",
    student,
    stage,
    stageLabel: stages[stage].label,
    contractAddress,
    txHash,
    tokenId: tokenId.toString(),
    checks: checks.checks,
    ownership: ownership.method,
    createdAt: new Date().toISOString(),
  };
  appendSubmission(record);

  return {
    ok: true,
    message: `${stages[stage].label} challenge passed.`,
    submission: record,
    nextAction:
      "Verifier can now call LearningQuest.completeStage(student, stage, contractAddress) to update on-chain progress.",
  };
}

async function verifyOwnership(rpcUrl, student, contractAddress, txHash) {
  const owner = await safeCall(rpcUrl, contractAddress, selectors.owner);
  if (owner.ok) {
    const ownerAddress = decodeAddress(owner.value);
    if (ownerAddress && ownerAddress.toLowerCase() === student.toLowerCase()) {
      return { ok: true, method: "owner()" };
    }
  }

  if (txHash) {
    const [transaction, receipt] = await Promise.all([
      rpc(rpcUrl, "eth_getTransactionByHash", [txHash]),
      rpc(rpcUrl, "eth_getTransactionReceipt", [txHash]),
    ]);
    if (!transaction || !receipt) {
      return { ok: false, reason: "Deployment transaction was not found on Sepolia." };
    }
    if (!receipt.contractAddress || receipt.contractAddress.toLowerCase() !== contractAddress.toLowerCase()) {
      return { ok: false, reason: "Deployment transaction does not create the submitted contract address." };
    }
    if (!transaction.from || transaction.from.toLowerCase() !== student.toLowerCase()) {
      return { ok: false, reason: "Deployment transaction sender does not match the student wallet." };
    }
    return { ok: true, method: "deployment transaction sender" };
  }

  return {
    ok: false,
    reason: "Could not prove ownership. Add owner() to the template or submit the deployment transaction hash.",
  };
}

async function verifyErc20(rpcUrl, student, contractAddress) {
  const checks = [];
  const name = decodeString(await requiredCall(rpcUrl, contractAddress, selectors.name, "name()"));
  checks.push(`name(): ${name}`);
  const symbol = decodeString(await requiredCall(rpcUrl, contractAddress, selectors.symbol, "symbol()"));
  checks.push(`symbol(): ${symbol}`);
  const decimals = decodeUint(await requiredCall(rpcUrl, contractAddress, selectors.decimals, "decimals()"));
  checks.push(`decimals(): ${decimals}`);
  const totalSupply = decodeUint(await requiredCall(rpcUrl, contractAddress, selectors.totalSupply, "totalSupply()"));
  checks.push(`totalSupply(): ${totalSupply}`);
  const balance = decodeUint(
    await requiredCall(rpcUrl, contractAddress, selectors.balanceOf + encodeAddress(student), "balanceOf(student)"),
  );
  checks.push(`balanceOf(student): ${balance}`);

  if (!name || !symbol) {
    return { ok: false, reason: "ERC20 name and symbol must be non-empty.", checks };
  }
  if (decimals > 30n) {
    return { ok: false, reason: "ERC20 decimals looks invalid.", checks };
  }
  if (totalSupply === 0n) {
    return { ok: false, reason: "ERC20 totalSupply must be greater than zero.", checks };
  }
  if (balance === 0n) {
    return { ok: false, reason: "Student wallet must hold some of the submitted ERC20 token.", checks };
  }
  return { ok: true, checks };
}

async function verifyErc721(rpcUrl, student, contractAddress, tokenId, requireOnchainMetadata) {
  const checks = [];
  const supportsErc721 = decodeBool(
    await requiredCall(
      rpcUrl,
      contractAddress,
      selectors.supportsInterface + encodeBytes4("0x80ac58cd"),
      "supportsInterface(ERC721)",
    ),
  );
  checks.push(`supportsInterface(ERC721): ${supportsErc721}`);
  if (!supportsErc721) {
    return { ok: false, reason: "Contract does not report ERC721 support through ERC165.", checks };
  }

  const name = decodeString(await requiredCall(rpcUrl, contractAddress, selectors.name, "name()"));
  checks.push(`name(): ${name}`);
  const symbol = decodeString(await requiredCall(rpcUrl, contractAddress, selectors.symbol, "symbol()"));
  checks.push(`symbol(): ${symbol}`);
  const owner = decodeAddress(
    await requiredCall(rpcUrl, contractAddress, selectors.ownerOf + encodeUint(tokenId), `ownerOf(${tokenId})`),
  );
  checks.push(`ownerOf(${tokenId}): ${owner}`);
  const tokenUri = decodeString(
    await requiredCall(rpcUrl, contractAddress, selectors.tokenURI + encodeUint(tokenId), `tokenURI(${tokenId})`),
  );
  checks.push(`tokenURI(${tokenId}): ${tokenUri.slice(0, 96)}${tokenUri.length > 96 ? "..." : ""}`);

  if (!name || !symbol) {
    return { ok: false, reason: "ERC721 name and symbol must be non-empty.", checks };
  }
  if (!owner || owner.toLowerCase() !== student.toLowerCase()) {
    return { ok: false, reason: `Student must own token ${tokenId}.`, checks };
  }
  if (!tokenUri) {
    return { ok: false, reason: "tokenURI must be non-empty.", checks };
  }
  if (requireOnchainMetadata) {
    const image = readOnchainImageFromTokenUri(tokenUri);
    checks.push(`onchain image: ${image.slice(0, 48)}...`);
    if (!image.startsWith("data:image/svg+xml;base64,")) {
      return { ok: false, reason: "Onchain ERC721 image must be an SVG data URI.", checks };
    }
  }
  return { ok: true, checks };
}

function readOnchainImageFromTokenUri(tokenUri) {
  const prefix = "data:application/json;base64,";
  if (!tokenUri.startsWith(prefix)) {
    throw new Error("Onchain ERC721 tokenURI must be a base64 JSON data URI.");
  }
  const json = JSON.parse(Buffer.from(tokenUri.slice(prefix.length), "base64").toString("utf8"));
  return typeof json.image === "string" ? json.image : "";
}

async function requiredCall(rpcUrl, to, data, label) {
  const result = await safeCall(rpcUrl, to, data);
  if (!result.ok) {
    throw new Error(`Required check failed: ${label}.`);
  }
  return result.value;
}

async function safeCall(rpcUrl, to, data) {
  try {
    const value = await rpc(rpcUrl, "eth_call", [{ to, data }, "latest"]);
    if (!value || value === "0x") {
      return { ok: false };
    }
    return { ok: true, value };
  } catch {
    return { ok: false };
  }
}

async function rpc(rpcUrl, method, params) {
  const response = await fetch(rpcUrl, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ jsonrpc: "2.0", id: Date.now(), method, params }),
  });
  const json = await response.json();
  if (json.error) {
    throw new Error(json.error.message || `RPC ${method} failed`);
  }
  return json.result;
}

function decodeString(data) {
  const hex = strip0x(data);
  const offset = Number.parseInt(hex.slice(0, 64), 16) * 2;
  const length = Number.parseInt(hex.slice(offset, offset + 64), 16) * 2;
  return Buffer.from(hex.slice(offset + 64, offset + 64 + length), "hex").toString("utf8");
}

function decodeUint(data) {
  return BigInt(data);
}

function decodeBool(data) {
  return BigInt(data) === 1n;
}

function decodeAddress(data) {
  const hex = strip0x(data);
  if (hex.length < 64) {
    return "";
  }
  return `0x${hex.slice(-40)}`;
}

function encodeAddress(address) {
  return strip0x(address).padStart(64, "0");
}

function encodeUint(value) {
  return BigInt(value).toString(16).padStart(64, "0");
}

function encodeBytes4(value) {
  return strip0x(value).padEnd(64, "0");
}

function strip0x(value) {
  return String(value).startsWith("0x") ? String(value).slice(2) : String(value);
}

function normalizeAddress(value) {
  const address = typeof value === "string" ? value.trim() : "";
  return /^0x[a-fA-F0-9]{40}$/.test(address) ? address : "";
}

function fail(reason, body, checks = []) {
  const record = {
    id: `${Date.now()}-${Math.random().toString(16).slice(2)}`,
    status: "failed",
    student: normalizeAddress(body?.student) || String(body?.student || ""),
    stage: Number(body?.stage || 0),
    stageLabel: stages[Number(body?.stage || 0)]?.label || "Unknown",
    contractAddress: normalizeAddress(body?.contractAddress) || String(body?.contractAddress || ""),
    txHash: typeof body?.txHash === "string" ? body.txHash.trim() : "",
    tokenId: String(body?.tokenId || "0"),
    reason,
    checks,
    createdAt: new Date().toISOString(),
  };
  appendSubmission(record);
  return { ok: false, reason, submission: record };
}

function readSubmissions() {
  try {
    return JSON.parse(fs.readFileSync(submissionsPath, "utf8"));
  } catch {
    return [];
  }
}

function appendSubmission(record) {
  fs.mkdirSync(dataDir, { recursive: true });
  const submissions = readSubmissions();
  submissions.unshift(record);
  fs.writeFileSync(submissionsPath, `${JSON.stringify(submissions.slice(0, 500), null, 2)}\n`);
}

function readJsonBody(req) {
  return new Promise((resolve, reject) => {
    let body = "";
    req.on("data", (chunk) => {
      body += chunk;
      if (body.length > 100_000) {
        reject(new Error("Request body is too large."));
      }
    });
    req.on("end", () => {
      try {
        resolve(body ? JSON.parse(body) : {});
      } catch {
        reject(new Error("Request body must be JSON."));
      }
    });
  });
}

function sendJson(res, statusCode, payload) {
  res.writeHead(statusCode, {
    "Content-Type": "application/json; charset=utf-8",
    "Cache-Control": "no-store",
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers": "content-type",
    "Access-Control-Allow-Methods": "GET,POST,OPTIONS",
  });
  if (statusCode === 204) {
    res.end();
    return;
  }
  res.end(JSON.stringify(payload));
}

function serveStatic(url, res) {
  const requestedPath = url.pathname === "/" ? "/index.html" : url.pathname;
  const safePath = path
    .normalize(decodeURIComponent(requestedPath))
    .replace(/^(\.\.[/\\])+/, "")
    .replace(/^[/\\]+/, "");
  const filePath = path.join(root, safePath);

  if (!filePath.startsWith(root)) {
    res.writeHead(403);
    res.end("Forbidden");
    return;
  }

  fs.readFile(filePath, (error, content) => {
    if (error) {
      res.writeHead(404);
      res.end("Not found");
      return;
    }

    res.writeHead(200, {
      "Content-Type": types[path.extname(filePath)] || "application/octet-stream",
      "Cache-Control": "no-store",
      "Access-Control-Allow-Origin": "*",
    });
    res.end(content);
  });
}

function loadEnvFile(filePath) {
  try {
    const content = fs.readFileSync(filePath, "utf8");
    for (const line of content.split(/\r?\n/)) {
      const trimmed = line.trim();
      if (!trimmed || trimmed.startsWith("#") || !trimmed.includes("=")) {
        continue;
      }
      const [key, ...parts] = trimmed.split("=");
      if (!process.env[key]) {
        process.env[key] = parts.join("=").replace(/^["']|["']$/g, "");
      }
    }
  } catch {
    // The .env file is optional for local static frontend use.
  }
}
