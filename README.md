# TeddySwap Badger

# Running the 🧸 TeddySwap Badger 🍯 🦡

This section describes how to run a TeddySwap Badger (transaction batcher) in the Cardano Preview Testnet.


## Prerequisites

- Knowledge on how to build, install and run the [cardano-node](https://github.com/input-output-hk/cardano-node), you can learn more from the **Cardano Developer Portal** (https://developers.cardano.org/docs/get-started/installing-cardano-node).

- Fully synced `cardano-node` on the **preview** testnet
- Knowledge how to operate [Docker](https://docker.io) containers.

## Badger Wallet

First, you will need a `cardano-cli` generated private key text envelope. *If you already have one please skip this step*. 

> *You can also generate a private key text envelope derived from a BIP39 mnemonic seed using `cardano-addresses` but it will not be convered in this document. Please see https://github.com/input-output-hk/cardano-addresses for more information.*

```sh
cardano-cli address key-gen \
--verification-key-file payment.vkey \
--signing-key-file payment.skey
```

Generate a **Cardano** wallet address:

```sh
cardano-cli address build \
--payment-verification-key-file payment.vkey \
--out-file payment.addr \
--testnet-magic 2
```

> Please make sure your wallet address contains some amount of ADA in it to process transactions, 100 ADA should do!

Next is to move everything into one directory, for example:

```sh
badger-volume
├── payment.addr
├── payment.skey
└── payment.vkey
```

Once that is set, run the wallet secret/cypher generator via `docker`

```sh
docker run -v ${PATH_TO_BADGER_VOLUME}:/testWallet spectrumlabs/spectrum-wallet-helper:0.0.1.0 /testWallet/secret.json /testWallet/payment.skey YOUR_PASSWORD
```

Where `$(pwd)` points to the directory of your `badger-volume` or the directory that contains the `cardano-cli` keys.

If succesful you should see a new file has been created `secret.json`.

Your `badger-volume` directory should now look like this:

```sh
badger-volume/
├── payment.addr
├── payment.skey
├── payment.vkey
└── secret.json
```

Now we are ready to run the **Badger** 🦡, Let's go!

## Running the Badger

We create a **Badger** config file named `config.dhall` inside the `badger-volume` directory:

```haskell config.dhall
let FeePolicy = < Strict | Balance >
let CollateralPolicy = < Ignore | Cover >
let Network = < Mainnet | Preview >

let LogLevel = < Info | Error | Warn | Debug >
let format = "$time - $loggername - $prio - $msg" : Text
let fileHandlers = \(path : Text) -> \(level : LogLevel) -> {_1 = path, _2 = level, _3 = format}
let levelOverride = \(component : Text) -> \(level : LogLevel) -> {_1 = component, _2 = level}
in
{ mainnetMode = False
, nodeSocketConfig =
    { nodeSocketPath = "/ipc/node.socket"
    , maxInFlight    = 256
    }
, eventSourceConfig =
    { startAt =
        { slot = 32045163
        , hash = "825568a8f7272fa8662c5a1fee156fe5dfb932ae8a47c8526b737399c9b3e836"
        }
    }
, networkConfig =
    { cardanoNetworkId = 2
    }
, ledgerStoreConfig =
    { storePath       = "/data/amm-executor"
    , createIfMissing = True
    }
, nodeConfigPath = "/config/cardano/preview/config.json"
, pstoreConfig =
    { storePath       = "/data/psStore"
    , createIfMissing = True
    }
, backlogConfig =
    { orderLifetime        = 4500
    , orderExecTime        = 1500
    , suspendedPropability = 0
    }
, backlogStoreConfig =
    { storePath       = "/data/backlogStore"
    , createIfMissing = True
    }
, utxoStoreConfig =
    { utxoStorePath   = "/data/utxoStore"
    , createIfMissing = True
    }
, txsInsRefs =
    { swapRef = "81bdfd89f3c8ff1a23dbe70af2db399ad0ed028b36a41974662a2cf8cda3c7c3#0"
    , depositRef = "77186dc10826227acd5e4a48e636bd3b11d5f39cc051d794540a7125903e157c#0"
    , redeemRef = "2266866d4d85cd582a34d27638a6eeb885cc4fb96fee230c86720e1f3f9eb0a0#0"
    , poolV1Ref = "64747d26baba95016a42c078360a431bb74d603f3f2582eb1b77d5dcfd53f128#0"
    , poolV2Ref = "64747d26baba95016a42c078360a431bb74d603f3f2582eb1b77d5dcfd53f128#0"
    }
, scriptsConfig =
    { swapScriptPath    = "/scripts/swap.uplc"
    , depositScriptPath = "/scripts/deposit.uplc"
    , redeemScriptPath  = "/scripts/redeem.uplc"
    , poolV1ScriptPath  = "/scripts/pool.uplc"
    , poolV2ScriptPath  = "/scripts/pool.uplc"
    }
, explorerConfig =
    { explorerUri = "https://80-hallowed-priority-28uow9.us1.demeter.run"
    , network = Network.Preview
    }
, txAssemblyConfig =
    { feePolicy         = FeePolicy.Strict
    , collateralPolicy  = CollateralPolicy.Cover
    , deafultChangeAddr = "<your cardano wallet address>"
    }
, secrets =
    { secretFile = "/keys/secret.json"
    , keyPass    = "<your key password>"
    }
, loggingConfig =
    { rootLogLevel   = LogLevel.Debug
    , fileHandlers   = [fileHandlers "/dev/stdout" LogLevel.Debug]
    , levelOverrides = [] : List { _1 : Text, _2 : LogLevel }
    }
, unsafeEval =
    { unsafeTxFee = +320000
    , exUnits = 165000000
    , exMem = 530000
    }
}
```

Change `<your cardano wallet address>` to your newly generated cardano wallet address:

```haskell
, txAssemblyConfig =
    { feePolicy         = FeePolicy.Balance
    , collateralPolicy  = CollateralPolicy.Cover
    , deafultChangeAddr = "<your cardano wallet address>"
    }
```

Make sure you updated `keyPass` to your secret.json keypass.

```haskell
, secrets =
    { secretFile = "/keys/secret.json"
    , keyPass    = "<your key password>"
    }
```

Your `badger-volume` directory should now look like this:

```sh
badger-volume/
├── config.dhall
├── payment.addr
├── payment.skey
├── payment.vkey
└── secret.json
```


Now we can start the badger with the following code:

> Make sure your `cardano-node` is running, connected to Preview testnet and fully-synced!

> Replace `/absolute/path/to/cardano.socket` to the path of your `cardano-node` socket file

```sh
docker run -d --restart --name teddyswap-dex-backend \
  -v $(pwd)/config.dhall:/config/batcher.dhall \
  -v /absolute/path/to/cardano.socket:/ipc/cardano.socket \
  -v $(pwd)/keys/secret.json:/keys/secret.json \
  -e CONFIG_PATH=/config/batcher.dhall \
  --restart on-failure \
  clarkteddyswap/teddy-badger:6c8a8c7b589c2817dae53a08dc4d3413f4d24ff4
```

Where `$(pwd)` points to the directory of your `badger-volume`.

if succesful, You can then check the logs using the container id:
```sh
docker logs -f --tail 10 teddyswap-dex-backend
```

Congratulations 🎊, your **TeddySwap Badger** 🦡 should now be running and will pick up order transactions soon, rewards will be sent to your defined cardano wallet address!


## Running with docker-compose

Please see [DOCKER_COMPOSE.md](./DOCKER_COMPOSE.md)
