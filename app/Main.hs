{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE GADTs #-}

module Main where

import qualified Data.Vector.Storable as S
import qualified Data.Vector.Unboxed as V
import Codec.Picture.Png
import Codec.Picture.Types
import Data.Functor
import System.Environment
import System.IO.Posix.MMap

import Data.Image.Qoi.Format
import Data.Image.Qoi.Decoder
import Data.Image.Qoi.Pixel

toImage :: Header -> SomePixels -> DynamicImage
toImage Header { .. } (Pixels3 pixels) = ImageRGB8 $ generateImage f (fromIntegral hWidth) (fromIntegral hHeight)
  where
    f x y = let Pixel3 r g b = pixels V.! (y * fromIntegral hWidth + x)
             in PixelRGB8 r g b
toImage Header { .. } (Pixels4 pixels) = ImageRGBA8 $ generateImage f (fromIntegral hWidth) (fromIntegral hHeight)
  where
    f x y = let Pixel4 r g b a = pixels V.! (y * fromIntegral hWidth + x)
             in PixelRGBA8 r g b a

main :: IO ()
main = getArgs >>=
  \case ["decode", inFile] -> do
           bs <- unsafeMMapFile inFile
           case decodeQoi bs of
                Just (header, pixels) -> do print header
                                            case pixels of
                                                 Pixels3 pixels' -> print $ V.length pixels'
                                                 Pixels4 pixels' -> print $ V.length pixels'
                Nothing -> putStrLn "Unable to decode"
        ["decode", inFile, outFile] -> do
           bs <- unsafeMMapFile inFile
           case decodeQoi bs of
                Nothing -> putStrLn "Unable to decode"
                Just (header, pixels) -> void $ writeDynamicPng outFile $ toImage header pixels
        _ -> putStrLn "Wrong usage"
