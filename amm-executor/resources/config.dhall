let FeePolicy = < Strict | Balance >
let CollateralPolicy = < Ignore | Cover >

let LogLevel = < Info | Error | Warn | Debug >
let format = "$time - $loggername - $prio - $msg" : Text
let fileHandlers = \(path : Text) -> \(level : LogLevel) -> {_1 = path, _2 = level, _3 = format}
let levelOverride = \(component : Text) -> \(level : LogLevel) -> {_1 = component, _2 = level}
in
{ mainnetMode = False
, ledgerSyncConfig =
    { nodeSocketPath = "/mnt/CardanoTestnet/ipc/node.socket"
    , maxInFlight    = 256
    }
, eventSourceConfig =
    { startAt =
        { slot = 3208507
        , hash = "017432b8c8d530396b6171ba85298c02a553c5214f5fa98d47a986f92d9e2c2f"
        }
    }
, networkConfig = 
    { cardanoNetworkId = 2
    }
, ledgerStoreConfig =
    { storePath       = "./ledgerStore"
    , createIfMissing = True
    }
, nodeConfigPath = "/mnt/CardanoTestnet/config.json"
, pstoreConfig =
    { storePath       = "./pStore"
    , createIfMissing = True
    }
, backlogConfig =
    { orderLifetime        = 10
    , orderExecTime        = 10
    , suspendedPropability = 5
    }
, backlogStoreConfig =
    { storePath       = "./backlogStore"
    , createIfMissing = True
    }
, explorerConfig =
    { explorerUri = "https://explorer.spectrum.fi"
    }
, txSubmitConfig =
    { nodeSocketPath = "/mnt/CardanoTestnet/ipc/node.socket"
    }
, txAssemblyConfig =
    { feePolicy         = FeePolicy.Balance
    , collateralPolicy  = CollateralPolicy.Cover
    , deafultChangeAddr = "addr_test1vqth7nmwalquyp4n9vednffe3rfffwluyupp8guddwzkv5cwercpv"
    }
, secrets =
    { secretFile = "secret"
    , keyPass    = "test1234"
    }
, loggingConfig =
    { rootLogLevel   = LogLevel.Info
    , fileHandlers   = [fileHandlers "logs/amm-executor.log" LogLevel.Info]
    , levelOverrides = [] : List { _1 : Text, _2 : LogLevel }
    }
}