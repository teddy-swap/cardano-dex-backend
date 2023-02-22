# TeddySwap Badger

# Running the 🧸 TeddySwap Badger 🦡

This section describes how to run a TeddySwap Badger (transaction badger) in the Cardano Preview Testnet.


## Prerequisites

- Knowledge on how to build, install and run the [cardano-node](https://github.com/input-output-hk/cardano-node), you can learn more from the **Cardano Developer Portal** (https://developers.cardano.org/docs/get-started/installing-cardano-node), which I also wrote a few year ago 😉.

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

Next is to move everything into one directory, for example:

```sh
badger-volume
├── payment.addr
├── payment.skey
└── payment.vkey
```

Once that is set, run the wallet secret generator via `docker`

```sh
docker run -v $(pwd):/mnt/teddyswap clarkteddyswap/teddy-badger-keygen:74028e5b73601f2bd3ee4048997720799fd11a47
```

Where `$(pwd)` points to the directory of your `badger-volume` or the directoy that contains the `cardano-cli` keys.

If succesfull you should see a new file has been created `secret.json`.

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

First we need to download `cardano-node` **Preview Testnet config files**:

Assuming you are inside the `badger-volume` directory:
```sh
mkdir -p ./cardano/preview/ && cd  ./cardano/preview/ && \
curl https://book.world.dev.cardano.org/environments/preview/config.json --output config.json && \
curl https://book.world.dev.cardano.org/environments/preview/byron-genesis.json --output byron-genesis.json && \
curl https://book.world.dev.cardano.org/environments/preview/shelley-genesis.json --output shelley-genesis.json && \
curl https://book.world.dev.cardano.org/environments/preview/alonzo-genesis.json --output alonzo-genesis.json && cd ../../
```

The `badger-volume` directory should now look like this:

```
badger-volume/
├── cardano
│   └── preview
│       ├── alonzo-genesis.json
│       ├── byron-genesis.json
│       ├── config.json
│       └── shelley-genesis.json
├── payment.addr
├── payment.skey
├── payment.vkey
└── secret.json
```

Finally, we create a **Badger** config file named `config.dhall` inside the `badger-volume` directory:

```haskell config.dhall
let FeePolicy = < Strict | Balance >
let CollateralPolicy = < Ignore | Cover >

let LogLevel = < Info | Error | Warn | Debug >
let format = "$time - $loggername - $prio - $msg" : Text
let fileHandlers = \(path : Text) -> \(level : LogLevel) -> {_1 = path, _2 = level, _3 = format}
let levelOverride = \(component : Text) -> \(level : LogLevel) -> {_1 = component, _2 = level}
in
{ mainnetMode = False
, ledgerSyncConfig =
    { nodeSocketPath = "/ipc/node.socket"
    , maxInFlight    = 256
    }
, eventSourceConfig =
    { startAt =
        { slot = 9113273
        , hash = "427d8bf518d376d53627dd83302a000213454642e97d2eeddc19cdcc89abfe8b"
        }
    }
, networkConfig =
    { cardanoNetworkId = 2
    }
, ledgerStoreConfig =
    { storePath       = "/mnt/teddyswap/log_ledger"
    , createIfMissing = True
    }
, nodeConfigPath = "/mnt/teddyswap/cardano/preview/config.json"
, txsInsRefs = 
    { swapRef  = "ab2aa12fa353fb6c1fe22c9bb796bddf8a3d2117ad993ae6e5a4d18cf1804e34#0"
    , depositRef = "cb735015dff0039f59e16b7f1b2f4fe3d62a9a3b28e4dcc91e1828eff6788b4e#0"
    , redeemRef  = "a67a9c3023a61a1a9e3d17c118234d095d6e8da90fcb8be9b5a9cc532b8f6b75#0"
    , poolRef   = "19c83363f0291bbf0b3e62e2948b527e94ec0a2df5b4e2a51de85d1158632b7a#0"
    }
, pstoreConfig =
    { storePath       = "/mnt/teddyswap/log_pstore"
    , createIfMissing = True
    }
, backlogConfig =
    { orderLifetime        = 9000
    , orderExecTime        = 4500
    , suspendedPropability = 50
    }
, backlogStoreConfig =
    { storePath       = "/mnt/teddyswap/log_backlog"
    , createIfMissing = True
    }
, explorerConfig =
    { explorerUri = "https://8081-parallel-guidance-uagipf.us1.demeter.run/"
    }
, txSubmitConfig =
    { nodeSocketPath = "/ipc/node.socket"
    }
, txAssemblyConfig =
    { feePolicy         = FeePolicy.Balance
    , collateralPolicy  = CollateralPolicy.Cover
    , deafultChangeAddr = "addr_test1vqth7nmwalquyp4n9vednffe3rfffwluyupp8guddwzkv5cwercpv"
    }
, secrets =
    { secretFile = "/mnt/teddyswap/secret"
    , keyPass    = "password"
    }
, loggingConfig =
    { rootLogLevel   = LogLevel.Info
    , fileHandlers   = [fileHandlers "/dev/null" LogLevel.Info]
    , levelOverrides = [] : List { _1 : Text, _2 : LogLevel }
    }
}
```

Change `addr_test1vqth7nmwalquyp4n9vednffe3rfffwluyupp8guddwzkv5cwercpv` to your newly generated cardano wallet address:

```haskell
, txAssemblyConfig =
    { feePolicy         = FeePolicy.Balance
    , collateralPolicy  = CollateralPolicy.Cover
    , deafultChangeAddr = "addr_test1vqth7nmwalquyp4n9vednffe3rfffwluyupp8guddwzkv5cwercpv"
    }
```

Your `badger-volume` directory should now look like this:

```sh
badger-volume/
├── cardano
│   └── preview
│       ├── alonzo-genesis.json
│       ├── byron-genesis.json
│       ├── config.json
│       └── shelley-genesis.json
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
docker run -v $(pwd):/mnt/teddyswap -v /absolute/path/to/cardano.socket:/ipc/node.socket clarkteddyswap/teddy-swap-badger:1649714b3794f8001f1de46cb37fc5e7ff0b2c84
```

Where `$(pwd)` points to the directory of your `badger-volume` or the directoy that contains the `cardano-cli` keys.

Congratulations 🎊, your **TeddySwap Badger** 🦡 should now be running and will pick up order transactions soon, rewards will be sent to your defined cardano wallet address!
