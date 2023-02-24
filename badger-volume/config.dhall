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
        { slot = 10529622
        , hash = "b8e3eb3ed62997dfe39d780a8b57c57dc2a17c6776d05d662a5b17d0ce65c25f"
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
    , deafultChangeAddr = "addr_test1vrjsaysql0jlc68su2z7k4hd6g457jmqw9js7slv3e9maxqt7h0cl"
    }
, secrets =
    { secretFile = "/mnt/teddyswap/secret.json"
    , keyPass    = "password"
    }
, loggingConfig =
    { rootLogLevel   = LogLevel.Info
    , fileHandlers   = [fileHandlers "/dev/null" LogLevel.Info]
    , levelOverrides = [] : List { _1 : Text, _2 : LogLevel }
    }
}