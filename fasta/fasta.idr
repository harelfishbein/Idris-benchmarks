module Main

import System
import Data.Floats

alu : String
alu = "GGCCGGGCGCGGTGGCTCACGCCTGTAATCCCAGCACTTTGGGAGGCCGAGGCGGGCGGATCACCTGAGG\
    \TCAGGAGTTCGAGACCAGCCTGGCCAACATGGTGAAACCCCGTCTCTACTAAAAATACAAAAATTAGCCGGG\
    \CGTGGTGGCGCGCGCCTGTAATCCCAGCTACTCGGGAGGCTGAGGCAGGAGAATCGCTTGAACCCGGGAGGC\
    \GGAGGTTGCAGTGAGCCGAGATCGCGCCACTGCACTCCAGCCTGGGCGACAGAGCGAGACTCCGTCTCAAAAA"

iub : List (Char, Float)
iub = [('a',0.27),('c',0.12),('g',0.12),('t',0.27),('B',0.02)
      ,('D',0.02),('H',0.02),('K',0.02),('M',0.02),('N',0.02)
      ,('R',0.02),('S',0.02),('V',0.02),('W',0.02),('Y',0.02)]

homosapiens : List (Char, Float)
homosapiens = [('a',0.3029549426680),('c',0.1979883004921)
              ,('g',0.1975473066391),('t',0.3015094502008)]


takeRepeat : Nat -> String -> String
takeRepeat n s = if n > m
                 then s ++ takeRepeat (n-m) s
                 else pack $ take n $ unpack s
  where
    m = length s

splitAt' : Nat -> String -> (String, String)
splitAt' n s = let s' = unpack s in (pack $ take n s', pack $ drop n s')

writeAlu : String -> String -> IO ()
writeAlu name s0 = putStrLn name $> go s0
  where
    go "" = return ()
    go s  = let (h,t) = splitAt' 60 s in putStrLn h $> go t

replicate : Nat -> Char -> String
replicate Z       c = ""
replicate (S n) c = singleton c <+> replicate n c

inits : List a -> List a -> List (List a)
inits xs []     = [xs]
inits xs (h::t) = let xs' = xs ++ [h] in xs :: inits xs' t

scanl : (f : acc -> a -> acc) -> acc -> (l : List a) -> List acc
scanl f acc l = map (foldl f acc) $ inits [] l

accum : (Char,Float) -> (Char,Float) -> (Char,Float)
accum (_,p) (c,q) = (c,p+q)

instance Cast Nat Float where
  cast = cast . cast . cast

instance Cast Float Nat where
  cast = fromInteger . cast . cast . floor


make : String -> Nat -> List (Char, Float) -> Nat -> IO Nat
make name n0 tbl seed0 = do
    putStrLn name
    make' n0 Z seed0 ""
  where
    modulus : Nat
    modulus = 139968

    fill : List (Char,Float) -> Nat -> List String
    fill ((c,p) :: cps) j =
      let k = min modulus (cast (cast modulus * p + 1))
      in replicate (k - j) c :: fill cps k
    fill _ _ = []

    lookupTable : String
    lookupTable = Foldable.concat (fill (drop 1 $ scanl accum ('a',0) tbl) 0)

    make' : Nat -> Nat -> Nat -> String -> IO Nat
    make' Z     col seed buf = when (col > 0) (putStrLn buf) $> return seed
    make' (S n) col seed buf = do
      print (S n)
      let newseed  = modNat (seed * 3877 + 39573) modulus
      print newseed
      let nextchar = strIndex lookupTable (cast newseed)
      print nextchar
      if col+1 >= 60
        then putStrLn buf $> make' n Z newseed (singleton nextchar)
        else make' n (S col) newseed (strCons nextchar buf)


main : IO ()
main = do
    (_ :: n :: _) <- getArgs
    writeAlu ">ONE Homo sapiens alu" (takeRepeat (fromInteger (cast n)*2) alu)
    nseed <- make ">TWO IUB ambiguity codes" (fromInteger (cast n)*3) iub 42
    make ">THREE Homo sapiens frequency" (fromInteger (cast n)*5) homosapiens nseed
    return ()