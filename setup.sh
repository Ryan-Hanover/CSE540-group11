#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$REPO_ROOT"

RPC_URL="http://127.0.0.1:8545"
IPFS_API="http://127.0.0.1:5001/api/v0/version"

# Deterministic ganache keys (from --wallet.deterministic). Account 0 is the
# authority (Issuer/Verifier owner); account 1 is the voter.
AUTH_KEY="0x4f3edf983ac636a65a842ce7c78d9aa706d3b113bce9c46f30d7d21715b23b1d"
VOTER_KEY="0x6cbed15c793ce57650b9877cf6fa156fbef513c4e6134f022a85b1ffdd59b2a1"
AUTH_ADDR="0x90F8bf6A479f320ead074411a4B0e7944Ea8c9C1"
VOTER_ADDR="0xFFcf8FDEE72ac11b5c542428B35EEF5769C409f0"

say()  { printf '\n\033[1;34m[setup]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[warn]\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31m[error]\033[0m %s\n' "$*" >&2; exit 1; }

need() {
  command -v "$1" >/dev/null 2>&1 || die "Missing required command: $1. $2"
}

say "Checking system prerequisites"
need python3 "Install Python 3.10+ (e.g. sudo apt install python3 python3-venv)."
need node    "Install Node.js 18+ (e.g. sudo apt install nodejs npm)."
need npm     "Install npm (usually bundled with node)."
need ipfs    "Install Kubo IPFS from https://dist.ipfs.tech/ (see README)."
need curl    "Install curl (sudo apt install curl)."

say "Ensuring Python virtualenv at repo root"
if [ ! -x "$REPO_ROOT/bin/python" ]; then
  python3 -m venv "$REPO_ROOT"
fi
PY="$REPO_ROOT/bin/python"
PIP="$REPO_ROOT/bin/pip"

say "Installing Python packages (web3, eth_abi, requests, py-solc-x)"
"$PIP" install --quiet --upgrade pip
"$PIP" install --quiet web3 eth_abi requests py-solc-x

say "Installing Solidity compiler 0.8.30 via py-solc-x"
"$PY" - <<'PY'
import solcx
from packaging.version import Version
target = Version("0.8.30")
if target not in solcx.get_installed_solc_versions():
    solcx.install_solc(str(target))
print("solc", target, "ready")
PY

say "Installing Node packages in tools/ (ganache, @openzeppelin/contracts 5.0.2)"
( cd "$REPO_ROOT/tools" && npm install --no-audit --no-fund --loglevel=error )

if [ ! -d "$HOME/.ipfs" ]; then
  say "Initialising IPFS repo (first run only)"
  ipfs init >/dev/null
fi

if curl -s --max-time 2 -X POST "$IPFS_API" >/dev/null 2>&1; then
  say "IPFS daemon already running on :5001"
else
  say "Starting IPFS daemon in background -> tools/.ipfs.log"
  nohup ipfs daemon >"$REPO_ROOT/tools/.ipfs.log" 2>&1 &
  disown || true
  for i in 1 2 3 4 5 6 7 8 9 10; do
    sleep 1
    if curl -s --max-time 2 -X POST "$IPFS_API" >/dev/null 2>&1; then
      break
    fi
    [ "$i" = "10" ] && die "IPFS daemon did not become ready; see tools/.ipfs.log"
  done
fi

GANACHE_OK=$(curl -s --max-time 2 -X POST -H 'Content-Type: application/json' \
    --data '{"jsonrpc":"2.0","method":"eth_chainId","id":1}' "$RPC_URL" 2>/dev/null || true)
if echo "$GANACHE_OK" | grep -q '"result"'; then
  say "Dev chain already reachable on :8545"
else
  say "Starting ganache in background -> tools/.ganache.log"
  nohup "$REPO_ROOT/tools/node_modules/.bin/ganache" \
      --chain.chainId 1337 \
      --wallet.deterministic \
      --miner.blockTime 0 \
      --logging.quiet \
      >"$REPO_ROOT/tools/.ganache.log" 2>&1 &
  disown || true
  for i in 1 2 3 4 5 6 7 8 9 10; do
    sleep 1
    GANACHE_OK=$(curl -s --max-time 2 -X POST -H 'Content-Type: application/json' \
        --data '{"jsonrpc":"2.0","method":"eth_chainId","id":1}' "$RPC_URL" 2>/dev/null || true)
    if echo "$GANACHE_OK" | grep -q '"result"'; then
      break
    fi
    [ "$i" = "10" ] && die "ganache did not become ready; see tools/.ganache.log"
  done
fi

say "Compiling and deploying contracts"
"$PY" "$REPO_ROOT/tools/deploy.py" \
  --rpc "$RPC_URL" \
  --authority-key "$AUTH_KEY" \
  --voter-key     "$VOTER_KEY"

DEPLOYED="$REPO_ROOT/tools/deployed.json"
DID_ADDR=$("$PY" -c "import json;print(json.load(open('$DEPLOYED'))['didRegistry'])")
ISS_ADDR=$("$PY" -c "import json;print(json.load(open('$DEPLOYED'))['issuer'])")
VER_ADDR=$("$PY" -c "import json;print(json.load(open('$DEPLOYED'))['verifier'])")

cat <<EOF

-------------------------------------------------------------------
 All setup. Values for terminal UI.
-------------------------------------------------------------------
 RPC URL              : $RPC_URL
 DIDRegistry address  : $DID_ADDR
 Issuer address       : $ISS_ADDR
 Verifier address     : $VER_ADDR

 Authority (Issuer/Verifier owner)
   address            : $AUTH_ADDR
   private key        : $AUTH_KEY

 Voter
   address            : $VOTER_ADDR
   private key        : $VOTER_KEY

 Next steps
   source bin/activate              # or use bin/python directly
   python terminal_ui/voter_ui.py      # option 1 then 2 then 3
   python terminal_ui/issuer_ui.py     # option 1
   python terminal_ui/verifier_ui.py   # option 1  -> expect ALLOW

 Logs
   IPFS   : tools/.ipfs.log
   chain  : tools/.ganache.log
-------------------------------------------------------------------
EOF
