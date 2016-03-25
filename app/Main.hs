module Main where

import Control.Monad (void)
import Control.Applicative ((<|>))
import Data.Maybe (fromMaybe)
import Data.Monoid ((<>))
import Options.Applicative
import System.IO
import System.IO.Temp (withSystemTempFile)
import System.Posix.Env (getEnv)
import System.Posix.IO ()
import System.Process (CreateProcess(..), StdStream(..), createProcess, proc, waitForProcess)

desc :: String
desc = "Edit stdin using an editor before sending to stdout."

opts :: ParserInfo ()
opts = info (helper <*> pure ()) (fullDesc <> progDesc desc)

withTTY :: CreateProcess -> IO ()
withTTY cp = do
  stdin' <- openFile "/dev/tty" ReadMode
  stdout' <- openFile "/dev/tty" WriteMode
  (_, _, _, p) <- createProcess cp { std_in = UseHandle stdin', std_out = UseHandle stdout' }
  waitForProcess p
  hClose stdin'
  hClose stdout'

getEditor :: IO String
getEditor = choose <$> getEnv "EDITOR" <*> getEnv "VISUAL"
  where choose a b = fromMaybe "nano" $ a <|> b

toTemp :: Handle -> IO ()
toTemp h = do
  c <- hGetContents stdin
  hPutStr h c
  hFlush h
  hSeek h AbsoluteSeek 0

fromTemp :: Handle -> IO ()
fromTemp h = do
  c <- hGetContents h
  putStr c

editTemp :: FilePath -> Handle -> IO ()
editTemp t h = do
  toTemp h
  cmd <- getEditor
  withTTY $ proc cmd [t]
  fromTemp h

main :: IO ()
main = do
  execParser opts
  withSystemTempFile "editpipe.text" editTemp
