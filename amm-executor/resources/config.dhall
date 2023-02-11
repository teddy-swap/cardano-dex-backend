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
    { storePath       = "./log_ledger"
    , createIfMissing = True
    }
, nodeConfigPath = "/config/workspace/repo/cardano/preview/config.json"
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
, explorerConfig =
    { explorerUri = "https://explorer.spectrum.fi/"
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
    { secretFile = "secret"
    , keyPass    = "test1234"
    }
, loggingConfig =
    { rootLogLevel   = LogLevel.Info
    , fileHandlers   = [fileHandlers "/dev/null" LogLevel.Info]
    , levelOverrides = [] : List { _1 : Text, _2 : LogLevel }
    }
}