let FeePolicy = < Strict | Balance >
let CollateralPolicy = < Ignore | Cover >

let LogLevel = < Info | Error | Warn | Debug >
let format = "$time - $loggername - $prio - $msg" : Text
let fileHandlers = \(path : Text) -> \(level : LogLevel) -> {_1 = path, _2 = level, _3 = format}
let levelOverride = \(component : Text) -> \(level : LogLevel) -> {_1 = component, _2 = level}
in
{ mainnetMode = False
, ledgerSyncConfig =
    { nodeSocketPath = "/home/rjlacanlaled/cardano-preview/db/node.socket"
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
    { storePath       = "./log_ledger"
    , createIfMissing = True
    }
, nodeConfigPath = "/home/rjlacanlaled/cardano-preview/config.json"
, pstoreConfig =
    { storePath       = "./log_pstore"
    , createIfMissing = True
    }
, backlogConfig =
    { orderLifetime        = 9000
    , orderExecTime        = 4500
    , suspendedPropability = 50
    }
, backlogStoreConfig =
    { storePath       = "./log_backlog"
    , createIfMissing = True
    }
-- , txsInsRefs =
--     { swapRef = "ab2aa12fa353fb6c1fe22c9bb796bddf8a3d2117ad993ae6e5a4d18cf1804e34#0"
--     , depositRef = "67b95c91e8a59db1241ecf0d268536397c62478a4fb35dac50803996e7ed7f56#0"
--     , redeemRef = "a67a9c3023a61a1a9e3d17c118234d095d6e8da90fcb8be9b5a9cc532b8f6b75#0"
--     , poolRef = "19c83363f0291bbf0b3e62e2948b527e94ec0a2df5b4e2a51de85d1158632b7a#0"
--     }
-- , txsInsRefs =
--     { swapRef = "b2f79375bf73234bb988cfdb911c78ac4e9b5470197e828d507babfdcca08d16#2"
--     , depositRef = "b2f79375bf73234bb988cfdb911c78ac4e9b5470197e828d507babfdcca08d16#3"
--     , redeemRef = "b2f79375bf73234bb988cfdb911c78ac4e9b5470197e828d507babfdcca08d16#4"
--     , poolRef = "b2f79375bf73234bb988cfdb911c78ac4e9b5470197e828d507babfdcca08d16#1"
--     }
, explorerConfig =
    { explorerUri = "https://explorer.spectrum.fi/"
    }
, txSubmitConfig =
    { nodeSocketPath = "/home/rjlacanlaled/cardano-preview/db/node.socket"
    }
, txAssemblyConfig =
    { feePolicy         = FeePolicy.Balance
    , collateralPolicy  = CollateralPolicy.Cover
    , deafultChangeAddr = "addr_test1vqmpcp00dyg8he742mf59jjn8ggzmngasay5y4f7883cewgy4lr7x"
    }
, secrets =
    { secretFile = "/home/rjlacanlaled/spectrum/cardano-dex-backend/amm-executor/resources/secret.json"
    , keyPass    = "mypass"
    }
, loggingConfig =
    { rootLogLevel   = LogLevel.Info
    , fileHandlers   = [fileHandlers "./logs" LogLevel.Info]
    , levelOverrides = [] : List { _1 : Text, _2 : LogLevel }
    }
}