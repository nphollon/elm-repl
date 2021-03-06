{-# LANGUAGE OverloadedStrings #-}
module Completion (complete) where

import Control.Monad.State (get)
import qualified Data.ByteString.Char8 as BS
import qualified Data.Trie as Trie
import System.Console.Haskeline.Completion (Completion(Completion), CompletionFunc, completeWord)

import qualified Environment as Env
import qualified Eval.Command as Eval


complete :: CompletionFunc Eval.Command
complete =
    completeWord Nothing " \t" lookupCompletions


lookupCompletions :: String -> Eval.Command [Completion]
lookupCompletions string =
    do  env <- get
        let defs = adjustDefs (Env.defs env)
        return (completions string defs)
    where
      adjustDefs defs =
          Trie.unionL cmds $
          Trie.delete Env.firstVar $
          Trie.delete Env.lastVar defs

      cmds =
          Trie.fromList
              [ (":exit", "")
              , (":reset", "")
              , (":help", "")
              , (":flags", "")
              ]


completions :: String -> Trie.Trie a  -> [Completion]
completions string =
    Trie.lookupBy go (BS.pack string)
  where
    go :: Maybe a -> Trie.Trie a -> [Completion]
    go isElem suffixesTrie =
        maybeCurrent ++ suffixCompletions
      where
        maybeCurrent =
            case isElem of
              Nothing -> []
              Just _  -> [ Completion string string True ]

        suffixCompletions =
            map (suffixCompletion . BS.unpack) (Trie.keys suffixesTrie)

        suffixCompletion suffix =
            let full = string ++ suffix in
            Completion full full False
