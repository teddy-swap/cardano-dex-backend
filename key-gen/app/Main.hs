module Main where

import qualified Cardano.Api as C
import           WalletAPI.TrustStore (importTrustStoreFromCardano, SecretFile (SecretFile), KeyPass (KeyPass))
import           System.Environment (getArgs)
import qualified Data.Text   as T

main ::  IO ()
main = do
    args <- getArgs
    let secretPath = args !! 0
        skeyPath   = args !! 1
        pass       = T.pack $ args !! 2
    putStrLn $ "secretPath" ++ secretPath
    putStrLn $ "skeyPath" ++ skeyPath
    putStrLn $ "pass" ++ (args !! 2)
    importTrustStoreFromCardano @_ @C.PaymentKey C.AsPaymentKey (SecretFile secretPath) skeyPath (KeyPass pass)
    pure ()