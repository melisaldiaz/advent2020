{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE ScopedTypeVariables #-}

module DayFour where

import Control.Applicative ((<|>))
import Control.Monad (guard, replicateM)
import Data.Attoparsec.Text (Parser)
import qualified Data.Attoparsec.Text as A
import Data.Char (isSpace)
import Data.List ((\\), foldl')
import Data.Map.Strict (Map)
import qualified Data.Map.Strict as Map
import Data.Maybe (catMaybes)
import Data.Text (Text)
import qualified Data.Text as Text

countValid :: forall a. (a -> Bool) -> [a] -> Int
countValid predicate input =
  foldl' f 0 input
  where
    f :: Int -> a -> Int
    f acc a
      | predicate a = acc + 1
      | otherwise = acc

hasRequiredFields :: Text -> Bool
hasRequiredFields document =
  case A.parseOnly parseFields document of
    Left e -> False
    Right fs ->
      case fields \\ fs of
        [] -> True
        [a] -> case a of
          "cid" -> True
          _ -> False
        _ -> False

------------- First part parsers

parseFields :: Parser [Text]
parseFields =
  A.sepBy parseField (parseValue >> A.skipSpace)

parseValue :: Parser Text
parseValue = do
  _ <- A.char ':'
  val <- A.takeWhile (\c -> not $ isSpace c)
  pure val

parseField :: Parser Text
parseField = A.choice $ fmap A.string fields

fields :: [Text]
fields =
  "cid" : requiredFields

requiredFields :: [Text]
requiredFields =
  [ "byr",
    "iyr",
    "eyr",
    "hgt",
    "hcl",
    "ecl",
    "pid"
  ]

------------- Second part parsers

puzzleAnswer :: Int
puzzleAnswer = length $ docsToPassports $ documentsFromRows puzzleInput

parseFieldAndValue :: Parser (Text, Text)
parseFieldAndValue = do
  a <- parseField
  b <- parseValue
  pure (a, b)

parseAllFields :: Parser [(Text, Text)]
parseAllFields =
  A.sepBy parseFieldAndValue A.skipSpace

documentFromRow :: Text -> Maybe (Map Text Text)
documentFromRow t =
  fmap Map.fromList $ runParser parseAllFields t

documentsFromRows :: [Text] -> [Map Text Text]
documentsFromRows t =
  catMaybes $ fmap documentFromRow t

docsToPassports :: [Map Text Text] -> [Passport]
docsToPassports docs =
  catMaybes $ fmap passportFromMap docs

passportFromMap :: Map Text Text -> Maybe Passport
passportFromMap m = do
  a <- runParser parseByr =<< Map.lookup "byr" m
  b <- runParser parseIyr =<< Map.lookup "iyr" m
  c <- runParser parseEyr =<< Map.lookup "eyr" m
  d <- runParser parseHgt =<< Map.lookup "hgt" m
  e <- runParser parseHcl =<< Map.lookup "hcl" m
  f <- runParser parseEcl =<< Map.lookup "ecl" m
  g <- runParser parsePid =<< Map.lookup "pid" m
  pure $ Passport {byr = a, iyr = b, eyr = c, hgt = d, hcl = e, ecl = f, pid = g}

data Passport
  = Passport
      { byr :: Int,
        iyr :: Int,
        eyr :: Int,
        hgt :: Int,
        hcl :: Int,
        ecl :: Text,
        pid :: [Int]
      }
  deriving (Show)

runParser :: Parser a -> Text -> Maybe a
runParser fa t =
  case A.parseOnly fa t of
    Left _ -> Nothing
    Right a -> Just a

-------------- Specific parsers

parseByr :: Parser Int
parseByr = do
  n <- A.decimal
  guard (n >= 1920 && n <= 2002)
  pure n

parseIyr :: Parser Int
parseIyr = do
  n <- A.decimal
  guard (n >= 2010 && n <= 2020)
  pure n

parseEyr :: Parser Int
parseEyr = do
  n <- A.decimal
  guard (n >= 2020 && n <= 2030)
  pure n

parseHgt :: Parser Int
parseHgt = do
  n <- A.decimal
  unit <- A.string "cm" <|> A.string "in"
  case unit of
    "cm" -> guard (n >= 150 && n <= 193)
    "in" -> guard (n >= 59 && n <= 76)
  pure n

parseHcl :: Parser Int
parseHcl = do
  _ <- A.char '#'
  A.hexadecimal

parseEcl :: Parser Text
parseEcl = A.choice $ fmap A.string eyeColors

parsePid :: Parser [Int]
parsePid = do
  ns <- replicateM 9 parseDigitInt
  A.endOfInput
  pure ns

parseDigitInt :: Parser Int
parseDigitInt = do
  d <- A.digit
  case charToInt d of
    Nothing -> fail "parseDigitInt"
    Just x -> pure x

eyeColors :: [Text]
eyeColors =
  ["amb", "blu", "brn", "gry", "grn", "hzl", "oth"]

charToInt :: Char -> Maybe Int
charToInt =
  \case
    '0' -> Just 0
    '1' -> Just 1
    '2' -> Just 2
    '3' -> Just 3
    '4' -> Just 4
    '5' -> Just 5
    '6' -> Just 6
    '7' -> Just 7
    '8' -> Just 8
    '9' -> Just 9
    _ -> Nothing

---------------------------------------------------------------------------

-- Parsers used to prepare the input for the more specific parsers above.

parsePassport :: Parser Text
parsePassport = do
  xs <- A.manyTill' A.anyChar (A.endOfLine >> (A.endOfLine <|> A.endOfInput))
  case xs of
    [] -> fail "Failed to parse passports"
    _ -> pure $ Text.pack $ fmap (\c -> if c == '\n' then ' ' else c) xs

parsePassports :: Parser [Text]
parsePassports =
  A.many1 parsePassport

rawInput :: Text
rawInput = "ecl:hzl byr:1926 iyr:2010\npid:221225902 cid:61 hgt:186cm eyr:2021 hcl:#7d3b0c\n\nhcl:#efcc98 hgt:178 pid:433543520\neyr:2020 byr:1926\necl:blu cid:92\niyr:2010\n\niyr:2018\neyr:2026\nbyr:1946 ecl:brn\nhcl:#b6652a hgt:158cm\npid:822320101\n\niyr:2010\nhgt:138 ecl:grn pid:21019503 eyr:1937 byr:2008 hcl:z\n\nbyr:2018 hcl:z eyr:1990 ecl:#d06796 iyr:2019\nhgt:176in cid:75 pid:153cm\n\nbyr:1994\nhcl:#ceb3a1 hgt:176cm cid:80 pid:665071929 eyr:2024 iyr:2020 ecl:grn\n\ncid:280 byr:1955 ecl:blu hgt:155cm hcl:#733820\neyr:2013 iyr:2011 pid:2346820632\n\nhcl:#4a5917 hgt:61cm\npid:4772651050\niyr:2026 ecl:brn byr:2015 eyr:2026\n\niyr:2019 hcl:#a97842 hgt:182cm eyr:2024 ecl:gry pid:917294399 byr:1974\n\necl:#9c635c pid:830491851 hgt:175cm cid:141\niyr:2010\nhcl:z\nbyr:2026 eyr:1998\n\nbyr:1927 iyr:2011 pid:055176954 ecl:gry hcl:#7d3b0c eyr:2025 hgt:166cm\n\nhcl:#733820 byr:2008 ecl:utc eyr:1920 pid:159cm hgt:66cm iyr:2030\n\npid:027609878\neyr:2022 iyr:2012\nbyr:1960 hgt:157cm\nhcl:#b6652a\ncid:117\necl:grn\n\niyr:2025 pid:7190749793 ecl:grn byr:1984 hgt:71in hcl:c41681\ncid:259 eyr:1928\n\neyr:2029 pid:141655389 cid:52 hcl:#cfa07d iyr:2019\necl:blu hgt:69in byr:1938\n\neyr:2020 hgt:166cm\necl:gry\npid:611660309 iyr:2011\nhcl:#623a2f byr:1943\n\nhgt:190cm eyr:2022 byr:2000 cid:210 pid:728418346 hcl:#a97842 ecl:xry iyr:2015\n\nbyr:1973 eyr:2028 iyr:2012\nhcl:#ff0ec8 pid:740554599 ecl:amb cid:58 hgt:155cm\n\niyr:2016 pid:922938570 ecl:oth hcl:#fffffd hgt:154cm eyr:2021 byr:1966\n\necl:amb\nbyr:1929\nhcl:#c3bbea pid:511876219\niyr:2019\nhgt:191cm\neyr:2026\n\necl:utc hgt:155cm pid:#9f0a41 iyr:2012 hcl:#bd4141\nbyr:1998 eyr:2020\n\necl:grn hgt:173cm cid:321 pid:851120816 byr:1968 hcl:#a97842 eyr:2027\niyr:2014\n\nhgt:155cm hcl:#f40d77 pid:038224056 byr:1953 ecl:brn iyr:2014\neyr:2022\n\npid:181869721\niyr:2011 hgt:151cm hcl:#733820 cid:110 ecl:blu\nbyr:1931 eyr:2024\n\nbyr:1948\nhcl:#888785\nhgt:74in\ncid:112 ecl:hzl pid:921761213 eyr:2028\niyr:2015\n\necl:gry\nbyr:1931\npid:600127430 hcl:#341e13 eyr:2027\niyr:2013 hgt:173cm\n\nhgt:178cm pid:530791289 hcl:#6b5442\neyr:2022 byr:1979 iyr:2014 ecl:hzl\n\npid:412193170 hcl:#cfa07d hgt:186cm iyr:2012 cid:284 eyr:2020 byr:1967\necl:grn\n\nhcl:#6b5442\niyr:2015 pid:808448466 ecl:blu eyr:2022 hgt:159cm byr:1969\n\neyr:2020\niyr:2019 hgt:170cm pid:8964201562 hcl:#6b5442 byr:1947 ecl:amb\n\neyr:2029 ecl:hzl hcl:#866857 byr:1961\niyr:2017\n\necl:#3456ba eyr:2013 iyr:2020 pid:378280953\nhcl:z hgt:174cm\n\nhgt:172cm\ncid:202 ecl:oth eyr:2021 byr:1980\niyr:2012\nhcl:#cfa07d pid:605707698\n\ncid:281 hgt:161cm iyr:2017 pid:122936432 hcl:#602927 byr:1981 ecl:gry eyr:2021\n\nbyr:1959 hgt:193cm pid:083900241 iyr:2020 eyr:2037 hcl:#623a2f\necl:hzl\n\niyr:2030 hgt:153cm eyr:2022 hcl:#efcc98 cid:131\nbyr:2016 ecl:hzl pid:64053944\n\nhgt:172cm eyr:2025\nhcl:#866857\nbyr:1938 ecl:dne\npid:192cm iyr:2014\n\npid:016297574 cid:152 iyr:2015\neyr:2024 hcl:#341e13 byr:1965 hgt:175cm\necl:oth\n\npid:604330171 cid:125 byr:1974 hgt:160cm iyr:2014\neyr:2022 ecl:oth hcl:#6b5442\n\npid:59747275\nbyr:2027\nhgt:145\nhcl:1fd71f iyr:1944 eyr:2037 ecl:brn\n\niyr:2010\neyr:2021 byr:1953\npid:7098774146 ecl:brn hcl:98737d hgt:158cm\n\nhcl:#602927 eyr:2039 pid:#81a5a1 iyr:2012 cid:67 byr:1951\necl:#6551f5 hgt:76cm\n\nhgt:170cm ecl:oth\ncid:235 eyr:2022\nbyr:1929 iyr:2019\nhcl:#341e13 pid:797557745\n\niyr:2011\nhcl:#733820\neyr:2022 pid:830183476 ecl:blu byr:1976 cid:157 hgt:75in\n\nhgt:164cm ecl:amb pid:653425455 hcl:#623a2f byr:1977 eyr:2020\niyr:2013\n\nbyr:2009 eyr:1953 hgt:178cm pid:#5d02f0\nhcl:#a97842 iyr:2016\necl:amb\n\npid:009643210 eyr:2036 ecl:zzz\ncid:97 hcl:32e540 byr:2005 hgt:187cm iyr:2021\n\npid:155cm\niyr:2022 byr:2024 eyr:2031 ecl:amb cid:79\nhcl:#cfa07d hgt:69cm\n\ncid:176 ecl:oth\npid:688645779 byr:1933 eyr:2026 hgt:69cm\niyr:2016 hcl:#888785\n\nhcl:#888785\neyr:2027\niyr:2020 pid:802243213 ecl:brn\nhgt:179cm byr:1976\n\nhcl:#6cad3e hgt:164cm byr:1982 iyr:2020\necl:gry\npid:142160687 eyr:2023\n\nhcl:#18171d\nhgt:153cm\niyr:2014 ecl:hzl cid:231 pid:167809118 byr:1997 eyr:2028\n\nbyr:1940\necl:hzl iyr:2016 cid:67 hcl:#c800da\npid:563956960 eyr:2021\nhgt:189cm\n\npid:133094996 eyr:2032 hgt:60cm hcl:#623a2f byr:2030 ecl:dne iyr:2023\n\npid:65195409 hcl:d0d492\niyr:1956\nbyr:2019 ecl:#bb043f eyr:2031 hgt:167in\n\niyr:2016 byr:2006 ecl:#35d62f eyr:2029\nhgt:186cm\nhcl:1d8307\n\neyr:1935 iyr:1960 pid:346667344 ecl:grn hgt:170cm hcl:cfcc36\n\necl:oth byr:1979 pid:165581192\nhgt:177cm\nhcl:#c0946f\niyr:2011\n\niyr:2011 eyr:2030 pid:250840477\nbyr:1934 cid:174 hgt:179cm hcl:#866857\necl:blu\n\nhgt:157cm hcl:#7d3b0c eyr:2027 pid:979510046\necl:oth\n\niyr:2025\nhgt:69\necl:grt byr:1935\neyr:1928 pid:168cm\ncid:271 hcl:z\n\npid:998166233\niyr:2020 hgt:166cm ecl:amb byr:1995 hcl:#fffffd\n\nhcl:#ceb3a1 ecl:amb\niyr:2019\neyr:2024 hgt:184cm byr:1980 pid:839215481\ncid:146\n\nbyr:1967\npid:444303019 ecl:oth hgt:150cm eyr:2024\n\neyr:2023 byr:1960 iyr:2010\ncid:236 hcl:#733820 pid:900635506\nhgt:69in\necl:hzl\n\neyr:2029 pid:969574247\nhgt:150cm byr:1967\niyr:2010 ecl:blu\n\npid:575879605 iyr:2010\necl:hzl\nbyr:1963\nhgt:151cm\nhcl:#c0946f cid:277\n\nbyr:1998 pid:621374275\necl:brn hcl:z iyr:2029\neyr:2024\nhgt:68cm\n\npid:365407169 ecl:amb hcl:#87f433 iyr:2011 eyr:2021 byr:1987\nhgt:175cm cid:201\n\nhgt:175cm iyr:2020\necl:gry\neyr:2029 pid:806927384 cid:59\nbyr:1932 hcl:#888785\n\npid:589898274 cid:113 hcl:z hgt:184cm eyr:2000\necl:lzr iyr:2016 byr:2016\n\necl:#2bafbb\neyr:2038 iyr:2027\nhcl:#fffffd\nhgt:174 byr:2007\npid:093750113\n\neyr:2022 hgt:59in\nhcl:#ceb3a1\npid:159921662 ecl:gry\nbyr:1948 iyr:2014\ncid:50\n\nhgt:190cm\niyr:2014 pid:480507618 hcl:#fffffd byr:1945 eyr:2029\n\nbyr:1951 hgt:152cm ecl:brn iyr:2016 eyr:2029 cid:179 pid:027575942\nhcl:#fffffd\n\ncid:198 pid:728480773 eyr:2028 hgt:153cm iyr:2018\nhcl:#888785 ecl:amb byr:1983\n\nbyr:1968 hcl:#c0946f ecl:grn eyr:2027\niyr:2013 pid:269749807\ncid:227\nhgt:178cm\n\neyr:2024 hgt:185cm ecl:oth\nhcl:#448ace byr:1987 iyr:2018 pid:454243136\n\nbyr:1930 ecl:grn iyr:2018 hgt:158cm\nhcl:#341e13 eyr:2021\n\neyr:2024 cid:194 pid:425431271\nhgt:169cm ecl:grn byr:1973\niyr:2014 hcl:#fffffd\n\necl:grn cid:110 iyr:2013 hcl:#18171d\nhgt:155cm eyr:2024 byr:1962 pid:522435225\n\nbyr:1934 ecl:hzl hgt:152cm iyr:2018\neyr:2024 pid:079740520\n\necl:grn eyr:2023 hcl:c3f119 pid:468039715 iyr:2013 hgt:150cm byr:1955\n\npid:809357582 eyr:2025 byr:1958\nhcl:#6b5442 iyr:2013\nhgt:161cm ecl:hzl\n\nhcl:#b6652a pid:068979430 byr:1960 iyr:2010 ecl:grn hgt:159cm eyr:2021\n\ncid:105 pid:495292692 byr:1965\nhcl:#ceb3a1 hgt:160cm ecl:amb\niyr:2020\n\niyr:2010\neyr:2024 byr:1941 ecl:grn hcl:#b35770 hgt:171cm cid:132 pid:975699036\n\npid:767448421 hgt:186cm hcl:#733820\nbyr:1972 iyr:2020 eyr:2026 ecl:grn\n\npid:036236909 iyr:2012\nhgt:181cm hcl:#888785\neyr:2026\necl:hzl byr:1936\n\nhgt:173cm\nbyr:1923 ecl:blu\neyr:2026 pid:570818321\nhcl:#733820 iyr:2016\ncid:59\n\npid:2711059768\nbyr:2024\ncid:139 ecl:blu hcl:z hgt:60cm\n\neyr:2025\npid:671193016\nbyr:1950 hcl:#6b4b25 iyr:2017 hgt:158cm ecl:blu\n\nhgt:175cm iyr:2015 ecl:amb\nbyr:1984 eyr:2026 pid:342782894\ncid:140\n\niyr:2019 eyr:2027 byr:1972\npid:196266458\nhgt:158cm hcl:#7d3b0c cid:69\n\npid:604018034 iyr:2016 ecl:brn eyr:2028 hgt:172cm hcl:#6b5442 byr:1922\ncid:238\n\neyr:2024 ecl:gry byr:1970 pid:356551266 cid:340 hgt:162cm iyr:2013\n\necl:amb\nhgt:151cm hcl:#18171d byr:1921 pid:187276410 eyr:2030 iyr:2015\n\neyr:2030 pid:056372924 hcl:#d236d9 hgt:156cm\niyr:2014 ecl:blu\n\niyr:2014 eyr:2028 byr:1991\nhcl:#b6652a pid:119231378 hgt:155cm ecl:blu\ncid:77\n\nhcl:#341e13\neyr:2027\niyr:2012 ecl:grn hgt:152cm pid:405955710 byr:1970\n\niyr:2013 hgt:180cm eyr:1978 ecl:amb byr:1929 pid:3198111997 hcl:z\n\npid:32872520 ecl:#8a0dd4 iyr:1955 eyr:2036\nbyr:2027 cid:133 hcl:z hgt:184in\n\nhgt:152cm pid:402361044\nhcl:#efcc98 eyr:2029 ecl:grn iyr:2014\nbyr:1960\n\nbyr:1972 eyr:2026 pid:411187543 iyr:2014\nhgt:184cm cid:211 hcl:#866857 ecl:brn\n\necl:brn\nhcl:#efcc98\npid:311916712\nbyr:1957 hgt:151cm eyr:2020 iyr:2020\n\niyr:1968\nhcl:a28220\npid:#ed250d cid:240 eyr:2031\nhgt:181cm ecl:xry\n\necl:grn byr:1946 hgt:172cm iyr:2010 hcl:#b6652a pid:372011640 eyr:2026\n\necl:brn\neyr:2026 byr:1980 hcl:#c0946f\nhgt:151cm pid:153076317 iyr:2012\n\nbyr:1966 pid:852999809 ecl:oth\nhgt:163cm\niyr:2014 eyr:2029 hcl:#341e13\n\necl:blu\nbyr:1959 hgt:191cm pid:195095631 iyr:2016 hcl:#ceb3a1 eyr:2028\n\nbyr:2001 ecl:gry hcl:#888785 iyr:2018 hgt:177cm pid:576714115\n\niyr:2017\nbyr:1949\necl:blu hgt:186cm cid:289 pid:859016371\nhcl:#ceb3a1 eyr:2021\n\nbyr:1999 hcl:#b6652a eyr:2023\nhgt:175cm\necl:gry iyr:2013 cid:165 pid:194927609\n\nhgt:70in eyr:2027 ecl:brn iyr:2012 pid:162238378 hcl:#ceb3a1 byr:1986\n\nhgt:63in ecl:xry\nbyr:2011 iyr:2024\nhcl:5337b0\n\nhcl:#341e13 eyr:2029\nhgt:184cm ecl:amb iyr:2012\nbyr:1970\n\nbyr:1920 pid:472914751\neyr:2028\nhgt:187cm hcl:#cfa07d cid:290 ecl:gry\n\nbyr:1948 ecl:gry eyr:2025 hgt:151cm cid:276 hcl:#6b5442 pid:937979267\niyr:2016\n\nbyr:1934\npid:626915978 hcl:#623a2f hgt:167cm ecl:gry\niyr:2020 eyr:2023\n\nbyr:1949\nhgt:68in eyr:2027 iyr:2019 hcl:#733820 ecl:brn cid:237\npid:057797826\n\npid:155cm\nhgt:68cm ecl:lzr hcl:z cid:344 eyr:2028 iyr:2020 byr:2017\n\nbyr:1959\nhcl:#341e13 eyr:2022\niyr:2019 pid:728703569\nhgt:167cm\necl:oth\n\necl:grn\neyr:2024 byr:1999\npid:566956828\niyr:2015 cid:293 hcl:#602927 hgt:192cm\n\nbyr:1939\necl:xry pid:929512270 hgt:66in iyr:1939 eyr:2030 hcl:#efcc98\n\neyr:2026\niyr:2014\npid:176cm hcl:#fffffd\necl:gry\nhgt:151cm byr:1933\ncid:256\n\necl:oth eyr:2025 iyr:2017 hgt:159cm pid:055267863 cid:55 byr:2001 hcl:#cfa07d\n\neyr:2029 byr:1954 ecl:hzl cid:123 iyr:2020 hgt:192cm hcl:#866857\npid:225593536\n\npid:320274514 cid:289 byr:1963\neyr:1942\necl:gmt hcl:z hgt:167in iyr:2022\n\nbyr:2013\necl:gmt\niyr:2011\nhcl:#733820 pid:#e7962f\nhgt:178cm eyr:2029\n\npid:154cm ecl:hzl\neyr:2035 byr:2023 cid:104 iyr:2026\n\neyr:2024 ecl:hzl hcl:#7d3b0c iyr:2010\npid:105864164\nbyr:1955\nhgt:163cm\n\neyr:2021 hgt:151cm\niyr:2017 hcl:#c0946f\necl:amb\ncid:150\npid:296798563\nbyr:1953\n\niyr:2012\nbyr:1990 hcl:#341e13\npid:189449931 eyr:2024 hgt:64in\n\nhcl:z cid:79 byr:2028\neyr:2028 pid:886152432\necl:#ce0596 hgt:178cm\niyr:2029\n\necl:brn\niyr:2019 hgt:151cm\nhcl:#341e13\nbyr:1969\npid:468846056\neyr:2022\n\necl:grn hgt:157cm iyr:2012\neyr:2020\nhcl:#b6652a cid:338\nbyr:1954 pid:153867580\n\niyr:2011\neyr:2027\nbyr:1935\nhgt:151cm\necl:blu pid:802665934 cid:276 hcl:#623a2f\n\nhcl:#efcc98 eyr:2026 ecl:amb\niyr:2014 pid:320160032\nhgt:157cm\nbyr:1976\n\neyr:2021 cid:172\niyr:2012 ecl:oth hgt:187cm\npid:432856831 byr:2001 hcl:#733820\n\neyr:2028 ecl:amb hcl:#efcc98\niyr:2020 byr:1954 hgt:153cm\n\nbyr:1930 ecl:brn hcl:#fffffd\npid:458840035 hgt:178cm eyr:2021\niyr:2011 cid:336\n\npid:216876576 hcl:#341e13\neyr:2028 iyr:2018 hgt:177cm byr:1938\necl:brn cid:214\n\nbyr:2029 eyr:1987\nhgt:75cm pid:193cm hcl:#b6652a cid:246 iyr:2028\n\necl:hzl hgt:151cm hcl:#7d3b0c\neyr:2030 pid:910999919\niyr:2019 byr:1956\n\nbyr:1950\ncid:95 iyr:2013 ecl:grn\neyr:2020 hcl:#623a2f\npid:603817559 hgt:159cm\n\npid:913791667\niyr:2018 byr:1959 hcl:#a97842 hgt:179cm eyr:2029 ecl:gry\n\nhgt:71in\necl:blu eyr:2028\nhcl:#18171d byr:1937 iyr:2011 pid:951572571\n\nhcl:#b6652a iyr:2015 hgt:170cm ecl:blu cid:292\nbyr:1977 pid:475457579 eyr:2020\n\necl:amb eyr:2029\npid:530769382 iyr:2018 cid:53\nhgt:63in\nbyr:1954 hcl:#07de91\n\nhcl:#cfa07d hgt:185cm\nbyr:1929 iyr:2011\neyr:2027\n\niyr:2019 ecl:oth byr:2023 hcl:#341e13 pid:879919037\neyr:2030 hgt:174cm\n\nhcl:z hgt:182cm ecl:grn iyr:2010 eyr:2020 pid:2063425865\ncid:182\nbyr:2019\n\nbyr:1930 hgt:185cm pid:412694897 eyr:2025 ecl:brn iyr:2020\nhcl:#a97842\n\nhgt:150cm byr:1955 eyr:2020 cid:149 pid:597600808\nhcl:#ceb3a1\necl:hzl\n\npid:209568495\neyr:2026 byr:1928 hcl:#341e13 hgt:183cm ecl:brn iyr:2011\n\npid:723789670 ecl:blu iyr:2013 byr:1933\ncid:239 hcl:#7d3b0c eyr:2026 hgt:151cm\n\nbyr:1978 eyr:2027 hgt:164cm\npid:009071063\nhcl:#602927 iyr:2014 ecl:blu\n\nhcl:#18171d ecl:grn hgt:154cm cid:154 iyr:2016\nbyr:1952 pid:730027149 eyr:2024\n\neyr:2025 hcl:#888785 iyr:2013 cid:90\nbyr:1975 ecl:grn\npid:619198428 hgt:161cm\n\necl:gry iyr:2013 pid:795604673 cid:198 byr:1962\nhcl:#6b5442 hgt:64in eyr:2021\n\nhcl:#ceb3a1 ecl:oth iyr:2015\neyr:2021 pid:920586799 cid:302 hgt:60in\nbyr:1964\n\neyr:2021 ecl:gry iyr:2019\nhcl:#6b5442 hgt:192cm\nbyr:1996\npid:692698177\n\necl:grn pid:141369492 byr:1956 eyr:2028 hcl:#6b5442 hgt:190cm iyr:2014\n\nhcl:#6b5442\necl:grn iyr:2020 hgt:153cm\npid:312738382 eyr:2028\nbyr:1985\n\nbyr:1979\neyr:2021 ecl:gry hgt:175cm pid:787676021 cid:81 hcl:#b6652a iyr:2012\n\ncid:80 hgt:188cm byr:1964 pid:105773060 iyr:2014 hcl:#733820 ecl:gry eyr:2028\n\nbyr:1960 pid:251870522 iyr:2018 hgt:168cm ecl:blu hcl:#c0946f eyr:2026\n\ncid:270\npid:#5661f0 hgt:182in\necl:dne\nbyr:1930\nhcl:z iyr:2026\n\nhcl:#888785 byr:1954 pid:170544716 eyr:2028 hgt:162cm cid:244\niyr:2014\necl:grn\n\niyr:2017\nhgt:69in\necl:hzl\npid:544135985 hcl:#ceb3a1 eyr:2020\n\nhcl:92d4a1 iyr:2018 pid:178cm\ncid:347\nhgt:97 eyr:2017\necl:gmt byr:2004\n\necl:oth iyr:2018 hcl:#fffffd byr:1999 pid:853396129\ncid:119 eyr:2026 hgt:178cm\n\nhgt:69in\nhcl:#fffffd eyr:2026 byr:1922\niyr:2010 ecl:oth pid:664840386\n\nhgt:178cm\nbyr:2000\niyr:2013 hcl:#cfa07d\neyr:2028 pid:842454291\necl:amb\n\necl:hzl\nhcl:#733820 pid:316835287 byr:1998\neyr:2024\niyr:2015 hgt:165cm\n\npid:684064750 byr:1928 ecl:gry iyr:2015 cid:343\nhgt:189cm\nhcl:#4c6cb4 eyr:2020\n\nbyr:1923 hcl:#a97842 eyr:2024 ecl:gry\npid:095911913\nhgt:185cm iyr:2010\n\necl:hzl\nbyr:1996\neyr:2023\nhgt:177cm\nhcl:#b6652a pid:011541746\niyr:2011\n\nhcl:#efcc98\niyr:2014 ecl:oth byr:1942 pid:730960830\nhgt:183cm\neyr:2025\n\nbyr:1939 eyr:2029 ecl:amb hcl:#fffffd\nhgt:188cm pid:732730418 iyr:2013 cid:313\n\nhgt:164cm cid:217 byr:1985 hcl:#888785 eyr:2020\niyr:2014 ecl:oth\npid:071172789\n\neyr:2024 pid:215897274 ecl:#c67898\nbyr:1972 hcl:#866857 iyr:2010 hgt:170cm cid:310\n\necl:hzl pid:030118892 byr:1941 hgt:158cm hcl:#b6652a\neyr:2029 iyr:2012\n\necl:gry hcl:#c0946f hgt:166cm pid:604313781\nbyr:1924 eyr:2023 iyr:2020\n\nhcl:#602927 hgt:168cm eyr:2027 ecl:brn\npid:764635418 byr:1968 iyr:2010\n\npid:157933284\necl:grn\neyr:2030 byr:2000\nhgt:81 hcl:z\n\nhcl:#ec24d1\npid:647881680 byr:1922\nhgt:178cm iyr:2020 ecl:amb eyr:2021 cid:94\n\necl:hzl byr:1971 iyr:2018 pid:975690657 eyr:2027\nhgt:192in\ncid:202 hcl:#c0946f\n\npid:678999378\nhgt:61in\nbyr:1981 hcl:#cfa07d eyr:2029 iyr:2014\necl:oth\n\neyr:2022 iyr:2012 ecl:grn pid:883419125\nhcl:#ceb3a1\ncid:136 hgt:75in\nbyr:1952\n\niyr:2018 hgt:185cm\nbyr:1985 pid:119464380 eyr:2028 hcl:#623a2f ecl:gry\n\neyr:2025 hcl:#ceb3a1 byr:1953\ncid:277 hgt:164cm iyr:2010 pid:574253234\n\ncid:252 ecl:amb pid:594663323\nhgt:75in hcl:#cfa07d iyr:2019\neyr:2026 byr:1964\n\niyr:2026 hcl:z pid:60117235 ecl:lzr\nbyr:2016 hgt:156in eyr:1994\n\npid:448392350\neyr:2022 hcl:#a97842\nhgt:157cm\necl:hzl\niyr:2018 byr:1973\n\necl:brn\nbyr:1951\neyr:2028\nhcl:#7d3b0c iyr:2018 hgt:164cm\n\nhgt:156cm\nbyr:1963\niyr:2014 eyr:2020 ecl:blu hcl:#ceb3a1\npid:#a87d16\n\npid:447170366 ecl:blu hcl:#888785\niyr:2012 cid:236\nhgt:167cm\neyr:2022 byr:1942\n\nhcl:#623a2f\neyr:2020 iyr:2017 cid:128 ecl:amb pid:279550425\nbyr:1983 hgt:154cm\n\nbyr:2014 eyr:2034 hgt:176in hcl:z\necl:#d4e521\npid:3629053477 cid:177\niyr:1970\n\npid:30370825 byr:1966 eyr:2026\niyr:2026 hcl:#866857\ncid:346 ecl:#f7c189\n\niyr:2010 pid:271066119 eyr:2023 hcl:#efcc98 hgt:179cm byr:1956\n\nbyr:1966 hgt:156cm pid:977897485 cid:287 iyr:2011 hcl:#b6652a ecl:amb eyr:2029\n\ncid:211 ecl:gmt byr:2017\nhcl:z eyr:2029 hgt:180in iyr:2021 pid:81920053\n\nbyr:2019\npid:5229927737 hcl:75b4f1 hgt:146 iyr:2026 ecl:#92cf7d eyr:2032\n\neyr:2027 pid:604671573\necl:hzl\nhgt:189cm byr:1979\nhcl:#efcc98 iyr:2020\n\niyr:2018 cid:192\neyr:2029 ecl:grn\npid:653764645 hgt:179cm\nhcl:#341e13 byr:1927\n\nbyr:2012\niyr:2015\nhcl:#b6652a\npid:168500059 eyr:2038 cid:234 hgt:191cm ecl:zzz\n\necl:gry hcl:#623a2f byr:1925\niyr:2016\neyr:2028 cid:157\nhgt:154cm\npid:196280865\n\ncid:319 pid:928322396 ecl:gry\nbyr:1949\neyr:2028\nhcl:#341e13 hgt:171cm\niyr:2018\n\nbyr:2023\niyr:1953 hgt:154cm ecl:dne\nhcl:#888785\npid:066246061 eyr:1983\n\nhcl:z\niyr:2016 byr:1986 ecl:utc\nhgt:179cm eyr:2019 pid:583251408\n\necl:amb iyr:2014 pid:499004360\nbyr:1927 eyr:2021 hgt:193cm hcl:#ceb3a1\n\npid:631303194 ecl:gry\nhcl:#18171d cid:216 iyr:2019\neyr:2024 hgt:178cm\n\nhcl:#341e13 cid:201\nbyr:1949 iyr:2019 ecl:gry pid:372356205\neyr:2024\n\nhcl:#18171d\npid:867489359\nhgt:185cm\niyr:2020 ecl:amb\neyr:2030\nbyr:1955\n\nbyr:1991\necl:brn eyr:2025 hgt:184cm iyr:2016 pid:202216365\n\necl:xry pid:#524139 hgt:151cm hcl:z eyr:2031 byr:2030 iyr:2005\n\nbyr:1971 hgt:178cm ecl:amb hcl:#ceb3a1\niyr:2010\neyr:2026 pid:396974525\n\niyr:2014\nhgt:177cm pid:928522073\neyr:2022\necl:hzl\nhcl:#c0946f byr:1983\n\nhgt:167cm hcl:#ceb3a1 iyr:2014\npid:172415447\neyr:2020 byr:1956\n\niyr:2011 hgt:188cm byr:1947 eyr:2020 pid:667108134 ecl:amb hcl:#44a86b\n\ncid:302 ecl:brn pid:292483175 hgt:154cm\nbyr:1997\neyr:2026\niyr:2014 hcl:#623a2f\n\nhgt:171cm\niyr:2014 hcl:z ecl:hzl pid:321513523 eyr:2027 cid:146\nbyr:2001\n\neyr:1956 ecl:dne hgt:75cm hcl:82e1fa\niyr:2030 byr:2027\n\neyr:2020\niyr:2011 pid:656669479 ecl:oth hgt:151cm hcl:#efcc98 byr:1981\n\niyr:2013\nbyr:1934\npid:142890410 hgt:62in\neyr:2022\nhcl:#87cca4\necl:hzl\n\npid:006232726\nhgt:173cm ecl:hzl cid:110\neyr:2026 hcl:#866857 iyr:2017 byr:1992\n\ncid:208\niyr:2014 ecl:brn eyr:2024 byr:1935 hgt:187cm\nhcl:#b6652a\npid:770836724\n\niyr:2014 cid:144 hgt:169cm\neyr:2022\necl:oth\npid:117575716 hcl:#fffffd byr:1926\n\nbyr:1971 ecl:brn\nhcl:#733820 eyr:1942 iyr:2013\npid:606274259 hgt:163cm cid:196\n\nbyr:1964\npid:997828217 eyr:2029 iyr:2017 ecl:blu hcl:#341e13\nhgt:158cm\n\npid:568202531 hcl:#efcc98 hgt:154cm eyr:2029 iyr:2010\nbyr:1946\necl:blu\n\niyr:2011\npid:619355919\nbyr:1955\necl:brn hcl:#888785 eyr:2030 hgt:155cm\n\necl:hzl pid:367152545\nhgt:162cm\ncid:221 hcl:#866857\neyr:2024\nbyr:1997 iyr:2019\n\nhgt:157in\ncid:268 hcl:32371d byr:2020\necl:zzz pid:1081234390\n\necl:hzl eyr:2026\nbyr:1969 pid:850482906 cid:166 hcl:#602927 hgt:60in\niyr:2019\n\nhcl:#c0946f\nhgt:176cm\necl:brn eyr:2026 iyr:2018 cid:172 byr:1986 pid:172963254\n\necl:grn iyr:2016\nhgt:187cm\nbyr:1983\nhcl:#efcc98\npid:722084344 eyr:2025\n\necl:oth hcl:#341e13 pid:130312766 hgt:171cm iyr:2018 byr:1927 eyr:2024\n\nbyr:2021 hgt:152cm hcl:74dda6\neyr:1984 cid:216\niyr:2018 pid:95283942\n\nhcl:#b6652a pid:924778815 iyr:2017 ecl:gry\neyr:2035\nhgt:68cm\n\niyr:2010\nhcl:#efcc98 ecl:brn eyr:2020 pid:801894599 hgt:163cm byr:1959\n\npid:798701070 eyr:2030\nhcl:#866857 ecl:hzl hgt:169cm byr:1994 cid:219 iyr:2010\n\npid:#e9b41b\nhcl:#341e13 byr:1970\niyr:2014\necl:oth cid:266 hgt:68cm eyr:2023\n\nbyr:1931 pid:929960843 hgt:187cm hcl:#6b5442 cid:52 iyr:2010 eyr:2024 ecl:brn\n\niyr:2017 byr:1974\necl:hzl cid:243 pid:66053995 hgt:147 eyr:1920 hcl:z\n\niyr:2012 byr:1962 ecl:brn pid:773399437 hcl:#341e13\neyr:2026\n\npid:738442771 hgt:186cm eyr:2027 hcl:#efcc98 iyr:2013\necl:brn byr:1928\n\npid:855794198\necl:oth\nhgt:67in\ncid:81\niyr:2011 hcl:#b6652a eyr:2020\nbyr:1921\n\nhcl:176abf hgt:161in\nbyr:2002 iyr:2016 eyr:2027 pid:639047770 ecl:brn\ncid:178\n\npid:335686451\nhcl:#86c240 iyr:2017 hgt:190cm byr:1968 ecl:amb\n\nhgt:150cm\nhcl:094a87 ecl:#09c463 eyr:1926 pid:537511570 byr:2009\niyr:1998\n\nhgt:74in\npid:927963411\neyr:2026 ecl:gry cid:323 iyr:2012 hcl:#fffffd byr:1959\n\niyr:2018 byr:1978\nhcl:#ff1829 eyr:2023\npid:823129853 ecl:hzl\nhgt:65in\n\npid:189cm\necl:#00391e hgt:72cm hcl:11050f\nbyr:2029\neyr:1994\niyr:1935\ncid:186\n\necl:grn byr:1942 pid:217290710 hgt:181cm eyr:2021 hcl:#7d3b0c iyr:2019 cid:320\n\nbyr:1983 iyr:2013 cid:122 hcl:#ceb3a1 eyr:2030 hgt:59in ecl:grn pid:946451564\n\necl:amb\ncid:236 hgt:184cm\nhcl:#cfa07d iyr:2017 pid:934730535 eyr:2021 byr:2002\n\nbyr:1950 ecl:hzl eyr:2030 hcl:#623a2f pid:742249321\nhgt:158cm iyr:2018\n\nbyr:1946 eyr:2021 hcl:#a97842 pid:204671558 ecl:grn\niyr:2010 hgt:187cm\n\nhcl:#b6652a pid:528124882 hgt:162cm byr:1924 ecl:amb iyr:2027 cid:157\neyr:2028\n\nhgt:180cm iyr:2013 byr:1926 pid:232265934 hcl:#602927 ecl:oth\n\nbyr:1984 ecl:brn\niyr:2016 pid:756596443 eyr:2030 hcl:#7d3b0c hgt:183cm\n\nhgt:185cm\nhcl:#fffffd byr:1991 eyr:2023 iyr:2014\necl:amb\npid:759105859\n\ncid:82 iyr:2012 hgt:160cm eyr:2022 pid:593798464 ecl:gry hcl:#4e7571 byr:1983\n\npid:478427550\niyr:2010\necl:amb byr:1969 hgt:68in cid:94 eyr:2021 hcl:#866857\n\necl:amb iyr:2019 byr:1986 hgt:170cm\nhcl:#c0946f\npid:779205106 eyr:2027\n\necl:brn eyr:2025 byr:1925\nhcl:#7d3b0c hgt:76in pid:576353079 iyr:2010\n\nhgt:175cm hcl:4bf5ae ecl:amb\neyr:2029 pid:173cm cid:329\niyr:1952 byr:1972\n\necl:grn\neyr:2030\niyr:2015 hcl:#c0946f\nbyr:1989\nhgt:178cm\npid:287209519\n\npid:834505198 byr:1985 ecl:gry eyr:2024\ncid:295 hgt:169cm iyr:2017\n\nhgt:170cm\npid:054644831 eyr:2023 iyr:1949 ecl:amb\nhcl:#888785\nbyr:1955\n\nhgt:171cm\npid:947263309 iyr:2015 byr:1944 eyr:2027 ecl:grn cid:79 hcl:#341e13\n\neyr:1982\ncid:147\niyr:2015\nhgt:70cm hcl:a77c10 ecl:zzz byr:2007\npid:161cm\n\necl:gry byr:1933\nhcl:#c0946f pid:483275512 iyr:2012 eyr:2025 hgt:161cm\n\neyr:1985 hgt:176cm hcl:7b6ddc iyr:2012 cid:326 byr:1973 pid:929418396 ecl:gmt\n\necl:gry\nbyr:1971\nhgt:184cm\neyr:2027 hcl:#3adf2c iyr:2017 cid:210\npid:693561862\n\neyr:2021 pid:779298835 byr:1921 hgt:193cm ecl:amb\niyr:2016 hcl:#ceb3a1\n\nhcl:4a1444\nbyr:2019 iyr:2024 hgt:182in\ncid:87 ecl:#122264\npid:181cm\neyr:1927\n\ncid:267 ecl:amb eyr:2020 byr:2000\nhcl:#18171d iyr:2012 hgt:190cm pid:18525759\n\necl:oth byr:1988\niyr:2019 pid:660570833\nhcl:#866857 hgt:176cm\n\neyr:2030 hcl:#866857\nbyr:1967 cid:316 pid:560346474 iyr:2015\nhgt:160cm\necl:gry\n\necl:hzl\niyr:2014 hgt:164cm hcl:#733820 eyr:2025\npid:106302413 byr:1920\n\niyr:2016 pid:515066491\necl:grn eyr:2026 hgt:179cm hcl:#b6652a byr:1982\n\necl:#7de6a0\niyr:2004 eyr:1955 hgt:154cm cid:138 byr:2004\npid:758934555\nhcl:a21980\n\npid:#2a21e0 ecl:#1b9b27 hgt:165in\nbyr:1998 iyr:2014 eyr:2032\n\neyr:2021 hgt:184cm pid:431054313 hcl:#ceb3a1 cid:109 byr:1977 ecl:blu\niyr:2011\n\npid:006339126 hgt:177cm\ncid:188 hcl:#a97842\niyr:1959\necl:xry\n\nbyr:2000\necl:hzl eyr:2029\niyr:2011 hcl:#866857 hgt:74in"

puzzleInput :: [Text]
puzzleInput =
  [ "ecl:hzl byr:1926 iyr:2010 pid:221225902 cid:61 hgt:186cm eyr:2021 hcl:#7d3b0c",
    "hcl:#efcc98 hgt:178 pid:433543520 eyr:2020 byr:1926 ecl:blu cid:92 iyr:2010",
    "iyr:2018 eyr:2026 byr:1946 ecl:brn hcl:#b6652a hgt:158cm pid:822320101",
    "iyr:2010 hgt:138 ecl:grn pid:21019503 eyr:1937 byr:2008 hcl:z",
    "byr:2018 hcl:z eyr:1990 ecl:#d06796 iyr:2019 hgt:176in cid:75 pid:153cm",
    "byr:1994 hcl:#ceb3a1 hgt:176cm cid:80 pid:665071929 eyr:2024 iyr:2020 ecl:grn",
    "cid:280 byr:1955 ecl:blu hgt:155cm hcl:#733820 eyr:2013 iyr:2011 pid:2346820632",
    "hcl:#4a5917 hgt:61cm pid:4772651050 iyr:2026 ecl:brn byr:2015 eyr:2026",
    "iyr:2019 hcl:#a97842 hgt:182cm eyr:2024 ecl:gry pid:917294399 byr:1974",
    "ecl:#9c635c pid:830491851 hgt:175cm cid:141 iyr:2010 hcl:z byr:2026 eyr:1998",
    "byr:1927 iyr:2011 pid:055176954 ecl:gry hcl:#7d3b0c eyr:2025 hgt:166cm",
    "hcl:#733820 byr:2008 ecl:utc eyr:1920 pid:159cm hgt:66cm iyr:2030",
    "pid:027609878 eyr:2022 iyr:2012 byr:1960 hgt:157cm hcl:#b6652a cid:117 ecl:grn",
    "iyr:2025 pid:7190749793 ecl:grn byr:1984 hgt:71in hcl:c41681 cid:259 eyr:1928",
    "eyr:2029 pid:141655389 cid:52 hcl:#cfa07d iyr:2019 ecl:blu hgt:69in byr:1938",
    "eyr:2020 hgt:166cm ecl:gry pid:611660309 iyr:2011 hcl:#623a2f byr:1943",
    "hgt:190cm eyr:2022 byr:2000 cid:210 pid:728418346 hcl:#a97842 ecl:xry iyr:2015",
    "byr:1973 eyr:2028 iyr:2012 hcl:#ff0ec8 pid:740554599 ecl:amb cid:58 hgt:155cm",
    "iyr:2016 pid:922938570 ecl:oth hcl:#fffffd hgt:154cm eyr:2021 byr:1966",
    "ecl:amb byr:1929 hcl:#c3bbea pid:511876219 iyr:2019 hgt:191cm eyr:2026",
    "ecl:utc hgt:155cm pid:#9f0a41 iyr:2012 hcl:#bd4141 byr:1998 eyr:2020",
    "ecl:grn hgt:173cm cid:321 pid:851120816 byr:1968 hcl:#a97842 eyr:2027 iyr:2014",
    "hgt:155cm hcl:#f40d77 pid:038224056 byr:1953 ecl:brn iyr:2014 eyr:2022",
    "pid:181869721 iyr:2011 hgt:151cm hcl:#733820 cid:110 ecl:blu byr:1931 eyr:2024",
    "byr:1948 hcl:#888785 hgt:74in cid:112 ecl:hzl pid:921761213 eyr:2028 iyr:2015",
    "ecl:gry byr:1931 pid:600127430 hcl:#341e13 eyr:2027 iyr:2013 hgt:173cm",
    "hgt:178cm pid:530791289 hcl:#6b5442 eyr:2022 byr:1979 iyr:2014 ecl:hzl",
    "pid:412193170 hcl:#cfa07d hgt:186cm iyr:2012 cid:284 eyr:2020 byr:1967 ecl:grn",
    "hcl:#6b5442 iyr:2015 pid:808448466 ecl:blu eyr:2022 hgt:159cm byr:1969",
    "eyr:2020 iyr:2019 hgt:170cm pid:8964201562 hcl:#6b5442 byr:1947 ecl:amb",
    "eyr:2029 ecl:hzl hcl:#866857 byr:1961 iyr:2017",
    "ecl:#3456ba eyr:2013 iyr:2020 pid:378280953 hcl:z hgt:174cm",
    "hgt:172cm cid:202 ecl:oth eyr:2021 byr:1980 iyr:2012 hcl:#cfa07d pid:605707698",
    "cid:281 hgt:161cm iyr:2017 pid:122936432 hcl:#602927 byr:1981 ecl:gry eyr:2021",
    "byr:1959 hgt:193cm pid:083900241 iyr:2020 eyr:2037 hcl:#623a2f ecl:hzl",
    "iyr:2030 hgt:153cm eyr:2022 hcl:#efcc98 cid:131 byr:2016 ecl:hzl pid:64053944",
    "hgt:172cm eyr:2025 hcl:#866857 byr:1938 ecl:dne pid:192cm iyr:2014",
    "pid:016297574 cid:152 iyr:2015 eyr:2024 hcl:#341e13 byr:1965 hgt:175cm ecl:oth",
    "pid:604330171 cid:125 byr:1974 hgt:160cm iyr:2014 eyr:2022 ecl:oth hcl:#6b5442",
    "pid:59747275 byr:2027 hgt:145 hcl:1fd71f iyr:1944 eyr:2037 ecl:brn",
    "iyr:2010 eyr:2021 byr:1953 pid:7098774146 ecl:brn hcl:98737d hgt:158cm",
    "hcl:#602927 eyr:2039 pid:#81a5a1 iyr:2012 cid:67 byr:1951 ecl:#6551f5 hgt:76cm",
    "hgt:170cm ecl:oth cid:235 eyr:2022 byr:1929 iyr:2019 hcl:#341e13 pid:797557745",
    "iyr:2011 hcl:#733820 eyr:2022 pid:830183476 ecl:blu byr:1976 cid:157 hgt:75in",
    "hgt:164cm ecl:amb pid:653425455 hcl:#623a2f byr:1977 eyr:2020 iyr:2013",
    "byr:2009 eyr:1953 hgt:178cm pid:#5d02f0 hcl:#a97842 iyr:2016 ecl:amb",
    "pid:009643210 eyr:2036 ecl:zzz cid:97 hcl:32e540 byr:2005 hgt:187cm iyr:2021",
    "pid:155cm iyr:2022 byr:2024 eyr:2031 ecl:amb cid:79 hcl:#cfa07d hgt:69cm",
    "cid:176 ecl:oth pid:688645779 byr:1933 eyr:2026 hgt:69cm iyr:2016 hcl:#888785",
    "hcl:#888785 eyr:2027 iyr:2020 pid:802243213 ecl:brn hgt:179cm byr:1976",
    "hcl:#6cad3e hgt:164cm byr:1982 iyr:2020 ecl:gry pid:142160687 eyr:2023",
    "hcl:#18171d hgt:153cm iyr:2014 ecl:hzl cid:231 pid:167809118 byr:1997 eyr:2028",
    "byr:1940 ecl:hzl iyr:2016 cid:67 hcl:#c800da pid:563956960 eyr:2021 hgt:189cm",
    "pid:133094996 eyr:2032 hgt:60cm hcl:#623a2f byr:2030 ecl:dne iyr:2023",
    "pid:65195409 hcl:d0d492 iyr:1956 byr:2019 ecl:#bb043f eyr:2031 hgt:167in",
    "iyr:2016 byr:2006 ecl:#35d62f eyr:2029 hgt:186cm hcl:1d8307",
    "eyr:1935 iyr:1960 pid:346667344 ecl:grn hgt:170cm hcl:cfcc36",
    "ecl:oth byr:1979 pid:165581192 hgt:177cm hcl:#c0946f iyr:2011",
    "iyr:2011 eyr:2030 pid:250840477 byr:1934 cid:174 hgt:179cm hcl:#866857 ecl:blu",
    "hgt:157cm hcl:#7d3b0c eyr:2027 pid:979510046 ecl:oth",
    "iyr:2025 hgt:69 ecl:grt byr:1935 eyr:1928 pid:168cm cid:271 hcl:z",
    "pid:998166233 iyr:2020 hgt:166cm ecl:amb byr:1995 hcl:#fffffd",
    "hcl:#ceb3a1 ecl:amb iyr:2019 eyr:2024 hgt:184cm byr:1980 pid:839215481 cid:146",
    "byr:1967 pid:444303019 ecl:oth hgt:150cm eyr:2024",
    "eyr:2023 byr:1960 iyr:2010 cid:236 hcl:#733820 pid:900635506 hgt:69in ecl:hzl",
    "eyr:2029 pid:969574247 hgt:150cm byr:1967 iyr:2010 ecl:blu",
    "pid:575879605 iyr:2010 ecl:hzl byr:1963 hgt:151cm hcl:#c0946f cid:277",
    "byr:1998 pid:621374275 ecl:brn hcl:z iyr:2029 eyr:2024 hgt:68cm",
    "pid:365407169 ecl:amb hcl:#87f433 iyr:2011 eyr:2021 byr:1987 hgt:175cm cid:201",
    "hgt:175cm iyr:2020 ecl:gry eyr:2029 pid:806927384 cid:59 byr:1932 hcl:#888785",
    "pid:589898274 cid:113 hcl:z hgt:184cm eyr:2000 ecl:lzr iyr:2016 byr:2016",
    "ecl:#2bafbb eyr:2038 iyr:2027 hcl:#fffffd hgt:174 byr:2007 pid:093750113",
    "eyr:2022 hgt:59in hcl:#ceb3a1 pid:159921662 ecl:gry byr:1948 iyr:2014 cid:50",
    "hgt:190cm iyr:2014 pid:480507618 hcl:#fffffd byr:1945 eyr:2029",
    "byr:1951 hgt:152cm ecl:brn iyr:2016 eyr:2029 cid:179 pid:027575942 hcl:#fffffd",
    "cid:198 pid:728480773 eyr:2028 hgt:153cm iyr:2018 hcl:#888785 ecl:amb byr:1983",
    "byr:1968 hcl:#c0946f ecl:grn eyr:2027 iyr:2013 pid:269749807 cid:227 hgt:178cm",
    "eyr:2024 hgt:185cm ecl:oth hcl:#448ace byr:1987 iyr:2018 pid:454243136",
    "byr:1930 ecl:grn iyr:2018 hgt:158cm hcl:#341e13 eyr:2021",
    "eyr:2024 cid:194 pid:425431271 hgt:169cm ecl:grn byr:1973 iyr:2014 hcl:#fffffd",
    "ecl:grn cid:110 iyr:2013 hcl:#18171d hgt:155cm eyr:2024 byr:1962 pid:522435225",
    "byr:1934 ecl:hzl hgt:152cm iyr:2018 eyr:2024 pid:079740520",
    "ecl:grn eyr:2023 hcl:c3f119 pid:468039715 iyr:2013 hgt:150cm byr:1955",
    "pid:809357582 eyr:2025 byr:1958 hcl:#6b5442 iyr:2013 hgt:161cm ecl:hzl",
    "hcl:#b6652a pid:068979430 byr:1960 iyr:2010 ecl:grn hgt:159cm eyr:2021",
    "cid:105 pid:495292692 byr:1965 hcl:#ceb3a1 hgt:160cm ecl:amb iyr:2020",
    "iyr:2010 eyr:2024 byr:1941 ecl:grn hcl:#b35770 hgt:171cm cid:132 pid:975699036",
    "pid:767448421 hgt:186cm hcl:#733820 byr:1972 iyr:2020 eyr:2026 ecl:grn",
    "pid:036236909 iyr:2012 hgt:181cm hcl:#888785 eyr:2026 ecl:hzl byr:1936",
    "hgt:173cm byr:1923 ecl:blu eyr:2026 pid:570818321 hcl:#733820 iyr:2016 cid:59",
    "pid:2711059768 byr:2024 cid:139 ecl:blu hcl:z hgt:60cm",
    "eyr:2025 pid:671193016 byr:1950 hcl:#6b4b25 iyr:2017 hgt:158cm ecl:blu",
    "hgt:175cm iyr:2015 ecl:amb byr:1984 eyr:2026 pid:342782894 cid:140",
    "iyr:2019 eyr:2027 byr:1972 pid:196266458 hgt:158cm hcl:#7d3b0c cid:69",
    "pid:604018034 iyr:2016 ecl:brn eyr:2028 hgt:172cm hcl:#6b5442 byr:1922 cid:238",
    "eyr:2024 ecl:gry byr:1970 pid:356551266 cid:340 hgt:162cm iyr:2013",
    "ecl:amb hgt:151cm hcl:#18171d byr:1921 pid:187276410 eyr:2030 iyr:2015",
    "eyr:2030 pid:056372924 hcl:#d236d9 hgt:156cm iyr:2014 ecl:blu",
    "iyr:2014 eyr:2028 byr:1991 hcl:#b6652a pid:119231378 hgt:155cm ecl:blu cid:77",
    "hcl:#341e13 eyr:2027 iyr:2012 ecl:grn hgt:152cm pid:405955710 byr:1970",
    "iyr:2013 hgt:180cm eyr:1978 ecl:amb byr:1929 pid:3198111997 hcl:z",
    "pid:32872520 ecl:#8a0dd4 iyr:1955 eyr:2036 byr:2027 cid:133 hcl:z hgt:184in",
    "hgt:152cm pid:402361044 hcl:#efcc98 eyr:2029 ecl:grn iyr:2014 byr:1960",
    "byr:1972 eyr:2026 pid:411187543 iyr:2014 hgt:184cm cid:211 hcl:#866857 ecl:brn",
    "ecl:brn hcl:#efcc98 pid:311916712 byr:1957 hgt:151cm eyr:2020 iyr:2020",
    "iyr:1968 hcl:a28220 pid:#ed250d cid:240 eyr:2031 hgt:181cm ecl:xry",
    "ecl:grn byr:1946 hgt:172cm iyr:2010 hcl:#b6652a pid:372011640 eyr:2026",
    "ecl:brn eyr:2026 byr:1980 hcl:#c0946f hgt:151cm pid:153076317 iyr:2012",
    "byr:1966 pid:852999809 ecl:oth hgt:163cm iyr:2014 eyr:2029 hcl:#341e13",
    "ecl:blu byr:1959 hgt:191cm pid:195095631 iyr:2016 hcl:#ceb3a1 eyr:2028",
    "byr:2001 ecl:gry hcl:#888785 iyr:2018 hgt:177cm pid:576714115",
    "iyr:2017 byr:1949 ecl:blu hgt:186cm cid:289 pid:859016371 hcl:#ceb3a1 eyr:2021",
    "byr:1999 hcl:#b6652a eyr:2023 hgt:175cm ecl:gry iyr:2013 cid:165 pid:194927609",
    "hgt:70in eyr:2027 ecl:brn iyr:2012 pid:162238378 hcl:#ceb3a1 byr:1986",
    "hgt:63in ecl:xry byr:2011 iyr:2024 hcl:5337b0",
    "hcl:#341e13 eyr:2029 hgt:184cm ecl:amb iyr:2012 byr:1970",
    "byr:1920 pid:472914751 eyr:2028 hgt:187cm hcl:#cfa07d cid:290 ecl:gry",
    "byr:1948 ecl:gry eyr:2025 hgt:151cm cid:276 hcl:#6b5442 pid:937979267 iyr:2016",
    "byr:1934 pid:626915978 hcl:#623a2f hgt:167cm ecl:gry iyr:2020 eyr:2023",
    "byr:1949 hgt:68in eyr:2027 iyr:2019 hcl:#733820 ecl:brn cid:237 pid:057797826",
    "pid:155cm hgt:68cm ecl:lzr hcl:z cid:344 eyr:2028 iyr:2020 byr:2017",
    "byr:1959 hcl:#341e13 eyr:2022 iyr:2019 pid:728703569 hgt:167cm ecl:oth",
    "ecl:grn eyr:2024 byr:1999 pid:566956828 iyr:2015 cid:293 hcl:#602927 hgt:192cm",
    "byr:1939 ecl:xry pid:929512270 hgt:66in iyr:1939 eyr:2030 hcl:#efcc98",
    "eyr:2026 iyr:2014 pid:176cm hcl:#fffffd ecl:gry hgt:151cm byr:1933 cid:256",
    "ecl:oth eyr:2025 iyr:2017 hgt:159cm pid:055267863 cid:55 byr:2001 hcl:#cfa07d",
    "eyr:2029 byr:1954 ecl:hzl cid:123 iyr:2020 hgt:192cm hcl:#866857 pid:225593536",
    "pid:320274514 cid:289 byr:1963 eyr:1942 ecl:gmt hcl:z hgt:167in iyr:2022",
    "byr:2013 ecl:gmt iyr:2011 hcl:#733820 pid:#e7962f hgt:178cm eyr:2029",
    "pid:154cm ecl:hzl eyr:2035 byr:2023 cid:104 iyr:2026",
    "eyr:2024 ecl:hzl hcl:#7d3b0c iyr:2010 pid:105864164 byr:1955 hgt:163cm",
    "eyr:2021 hgt:151cm iyr:2017 hcl:#c0946f ecl:amb cid:150 pid:296798563 byr:1953",
    "iyr:2012 byr:1990 hcl:#341e13 pid:189449931 eyr:2024 hgt:64in",
    "hcl:z cid:79 byr:2028 eyr:2028 pid:886152432 ecl:#ce0596 hgt:178cm iyr:2029",
    "ecl:brn iyr:2019 hgt:151cm hcl:#341e13 byr:1969 pid:468846056 eyr:2022",
    "ecl:grn hgt:157cm iyr:2012 eyr:2020 hcl:#b6652a cid:338 byr:1954 pid:153867580",
    "iyr:2011 eyr:2027 byr:1935 hgt:151cm ecl:blu pid:802665934 cid:276 hcl:#623a2f",
    "hcl:#efcc98 eyr:2026 ecl:amb iyr:2014 pid:320160032 hgt:157cm byr:1976",
    "eyr:2021 cid:172 iyr:2012 ecl:oth hgt:187cm pid:432856831 byr:2001 hcl:#733820",
    "eyr:2028 ecl:amb hcl:#efcc98 iyr:2020 byr:1954 hgt:153cm",
    "byr:1930 ecl:brn hcl:#fffffd pid:458840035 hgt:178cm eyr:2021 iyr:2011 cid:336",
    "pid:216876576 hcl:#341e13 eyr:2028 iyr:2018 hgt:177cm byr:1938 ecl:brn cid:214",
    "byr:2029 eyr:1987 hgt:75cm pid:193cm hcl:#b6652a cid:246 iyr:2028",
    "ecl:hzl hgt:151cm hcl:#7d3b0c eyr:2030 pid:910999919 iyr:2019 byr:1956",
    "byr:1950 cid:95 iyr:2013 ecl:grn eyr:2020 hcl:#623a2f pid:603817559 hgt:159cm",
    "pid:913791667 iyr:2018 byr:1959 hcl:#a97842 hgt:179cm eyr:2029 ecl:gry",
    "hgt:71in ecl:blu eyr:2028 hcl:#18171d byr:1937 iyr:2011 pid:951572571",
    "hcl:#b6652a iyr:2015 hgt:170cm ecl:blu cid:292 byr:1977 pid:475457579 eyr:2020",
    "ecl:amb eyr:2029 pid:530769382 iyr:2018 cid:53 hgt:63in byr:1954 hcl:#07de91",
    "hcl:#cfa07d hgt:185cm byr:1929 iyr:2011 eyr:2027",
    "iyr:2019 ecl:oth byr:2023 hcl:#341e13 pid:879919037 eyr:2030 hgt:174cm",
    "hcl:z hgt:182cm ecl:grn iyr:2010 eyr:2020 pid:2063425865 cid:182 byr:2019",
    "byr:1930 hgt:185cm pid:412694897 eyr:2025 ecl:brn iyr:2020 hcl:#a97842",
    "hgt:150cm byr:1955 eyr:2020 cid:149 pid:597600808 hcl:#ceb3a1 ecl:hzl",
    "pid:209568495 eyr:2026 byr:1928 hcl:#341e13 hgt:183cm ecl:brn iyr:2011",
    "pid:723789670 ecl:blu iyr:2013 byr:1933 cid:239 hcl:#7d3b0c eyr:2026 hgt:151cm",
    "byr:1978 eyr:2027 hgt:164cm pid:009071063 hcl:#602927 iyr:2014 ecl:blu",
    "hcl:#18171d ecl:grn hgt:154cm cid:154 iyr:2016 byr:1952 pid:730027149 eyr:2024",
    "eyr:2025 hcl:#888785 iyr:2013 cid:90 byr:1975 ecl:grn pid:619198428 hgt:161cm",
    "ecl:gry iyr:2013 pid:795604673 cid:198 byr:1962 hcl:#6b5442 hgt:64in eyr:2021",
    "hcl:#ceb3a1 ecl:oth iyr:2015 eyr:2021 pid:920586799 cid:302 hgt:60in byr:1964",
    "eyr:2021 ecl:gry iyr:2019 hcl:#6b5442 hgt:192cm byr:1996 pid:692698177",
    "ecl:grn pid:141369492 byr:1956 eyr:2028 hcl:#6b5442 hgt:190cm iyr:2014",
    "hcl:#6b5442 ecl:grn iyr:2020 hgt:153cm pid:312738382 eyr:2028 byr:1985",
    "byr:1979 eyr:2021 ecl:gry hgt:175cm pid:787676021 cid:81 hcl:#b6652a iyr:2012",
    "cid:80 hgt:188cm byr:1964 pid:105773060 iyr:2014 hcl:#733820 ecl:gry eyr:2028",
    "byr:1960 pid:251870522 iyr:2018 hgt:168cm ecl:blu hcl:#c0946f eyr:2026",
    "cid:270 pid:#5661f0 hgt:182in ecl:dne byr:1930 hcl:z iyr:2026",
    "hcl:#888785 byr:1954 pid:170544716 eyr:2028 hgt:162cm cid:244 iyr:2014 ecl:grn",
    "iyr:2017 hgt:69in ecl:hzl pid:544135985 hcl:#ceb3a1 eyr:2020",
    "hcl:92d4a1 iyr:2018 pid:178cm cid:347 hgt:97 eyr:2017 ecl:gmt byr:2004",
    "ecl:oth iyr:2018 hcl:#fffffd byr:1999 pid:853396129 cid:119 eyr:2026 hgt:178cm",
    "hgt:69in hcl:#fffffd eyr:2026 byr:1922 iyr:2010 ecl:oth pid:664840386",
    "hgt:178cm byr:2000 iyr:2013 hcl:#cfa07d eyr:2028 pid:842454291 ecl:amb",
    "ecl:hzl hcl:#733820 pid:316835287 byr:1998 eyr:2024 iyr:2015 hgt:165cm",
    "pid:684064750 byr:1928 ecl:gry iyr:2015 cid:343 hgt:189cm hcl:#4c6cb4 eyr:2020",
    "byr:1923 hcl:#a97842 eyr:2024 ecl:gry pid:095911913 hgt:185cm iyr:2010",
    "ecl:hzl byr:1996 eyr:2023 hgt:177cm hcl:#b6652a pid:011541746 iyr:2011",
    "hcl:#efcc98 iyr:2014 ecl:oth byr:1942 pid:730960830 hgt:183cm eyr:2025",
    "byr:1939 eyr:2029 ecl:amb hcl:#fffffd hgt:188cm pid:732730418 iyr:2013 cid:313",
    "hgt:164cm cid:217 byr:1985 hcl:#888785 eyr:2020 iyr:2014 ecl:oth pid:071172789",
    "eyr:2024 pid:215897274 ecl:#c67898 byr:1972 hcl:#866857 iyr:2010 hgt:170cm cid:310",
    "ecl:hzl pid:030118892 byr:1941 hgt:158cm hcl:#b6652a eyr:2029 iyr:2012",
    "ecl:gry hcl:#c0946f hgt:166cm pid:604313781 byr:1924 eyr:2023 iyr:2020",
    "hcl:#602927 hgt:168cm eyr:2027 ecl:brn pid:764635418 byr:1968 iyr:2010",
    "pid:157933284 ecl:grn eyr:2030 byr:2000 hgt:81 hcl:z",
    "hcl:#ec24d1 pid:647881680 byr:1922 hgt:178cm iyr:2020 ecl:amb eyr:2021 cid:94",
    "ecl:hzl byr:1971 iyr:2018 pid:975690657 eyr:2027 hgt:192in cid:202 hcl:#c0946f",
    "pid:678999378 hgt:61in byr:1981 hcl:#cfa07d eyr:2029 iyr:2014 ecl:oth",
    "eyr:2022 iyr:2012 ecl:grn pid:883419125 hcl:#ceb3a1 cid:136 hgt:75in byr:1952",
    "iyr:2018 hgt:185cm byr:1985 pid:119464380 eyr:2028 hcl:#623a2f ecl:gry",
    "eyr:2025 hcl:#ceb3a1 byr:1953 cid:277 hgt:164cm iyr:2010 pid:574253234",
    "cid:252 ecl:amb pid:594663323 hgt:75in hcl:#cfa07d iyr:2019 eyr:2026 byr:1964",
    "iyr:2026 hcl:z pid:60117235 ecl:lzr byr:2016 hgt:156in eyr:1994",
    "pid:448392350 eyr:2022 hcl:#a97842 hgt:157cm ecl:hzl iyr:2018 byr:1973",
    "ecl:brn byr:1951 eyr:2028 hcl:#7d3b0c iyr:2018 hgt:164cm",
    "hgt:156cm byr:1963 iyr:2014 eyr:2020 ecl:blu hcl:#ceb3a1 pid:#a87d16",
    "pid:447170366 ecl:blu hcl:#888785 iyr:2012 cid:236 hgt:167cm eyr:2022 byr:1942",
    "hcl:#623a2f eyr:2020 iyr:2017 cid:128 ecl:amb pid:279550425 byr:1983 hgt:154cm",
    "byr:2014 eyr:2034 hgt:176in hcl:z ecl:#d4e521 pid:3629053477 cid:177 iyr:1970",
    "pid:30370825 byr:1966 eyr:2026 iyr:2026 hcl:#866857 cid:346 ecl:#f7c189",
    "iyr:2010 pid:271066119 eyr:2023 hcl:#efcc98 hgt:179cm byr:1956",
    "byr:1966 hgt:156cm pid:977897485 cid:287 iyr:2011 hcl:#b6652a ecl:amb eyr:2029",
    "cid:211 ecl:gmt byr:2017 hcl:z eyr:2029 hgt:180in iyr:2021 pid:81920053",
    "byr:2019 pid:5229927737 hcl:75b4f1 hgt:146 iyr:2026 ecl:#92cf7d eyr:2032",
    "eyr:2027 pid:604671573 ecl:hzl hgt:189cm byr:1979 hcl:#efcc98 iyr:2020",
    "iyr:2018 cid:192 eyr:2029 ecl:grn pid:653764645 hgt:179cm hcl:#341e13 byr:1927",
    "byr:2012 iyr:2015 hcl:#b6652a pid:168500059 eyr:2038 cid:234 hgt:191cm ecl:zzz",
    "ecl:gry hcl:#623a2f byr:1925 iyr:2016 eyr:2028 cid:157 hgt:154cm pid:196280865",
    "cid:319 pid:928322396 ecl:gry byr:1949 eyr:2028 hcl:#341e13 hgt:171cm iyr:2018",
    "byr:2023 iyr:1953 hgt:154cm ecl:dne hcl:#888785 pid:066246061 eyr:1983",
    "hcl:z iyr:2016 byr:1986 ecl:utc hgt:179cm eyr:2019 pid:583251408",
    "ecl:amb iyr:2014 pid:499004360 byr:1927 eyr:2021 hgt:193cm hcl:#ceb3a1",
    "pid:631303194 ecl:gry hcl:#18171d cid:216 iyr:2019 eyr:2024 hgt:178cm",
    "hcl:#341e13 cid:201 byr:1949 iyr:2019 ecl:gry pid:372356205 eyr:2024",
    "hcl:#18171d pid:867489359 hgt:185cm iyr:2020 ecl:amb eyr:2030 byr:1955",
    "byr:1991 ecl:brn eyr:2025 hgt:184cm iyr:2016 pid:202216365",
    "ecl:xry pid:#524139 hgt:151cm hcl:z eyr:2031 byr:2030 iyr:2005",
    "byr:1971 hgt:178cm ecl:amb hcl:#ceb3a1 iyr:2010 eyr:2026 pid:396974525",
    "iyr:2014 hgt:177cm pid:928522073 eyr:2022 ecl:hzl hcl:#c0946f byr:1983",
    "hgt:167cm hcl:#ceb3a1 iyr:2014 pid:172415447 eyr:2020 byr:1956",
    "iyr:2011 hgt:188cm byr:1947 eyr:2020 pid:667108134 ecl:amb hcl:#44a86b",
    "cid:302 ecl:brn pid:292483175 hgt:154cm byr:1997 eyr:2026 iyr:2014 hcl:#623a2f",
    "hgt:171cm iyr:2014 hcl:z ecl:hzl pid:321513523 eyr:2027 cid:146 byr:2001",
    "eyr:1956 ecl:dne hgt:75cm hcl:82e1fa iyr:2030 byr:2027",
    "eyr:2020 iyr:2011 pid:656669479 ecl:oth hgt:151cm hcl:#efcc98 byr:1981",
    "iyr:2013 byr:1934 pid:142890410 hgt:62in eyr:2022 hcl:#87cca4 ecl:hzl",
    "pid:006232726 hgt:173cm ecl:hzl cid:110 eyr:2026 hcl:#866857 iyr:2017 byr:1992",
    "cid:208 iyr:2014 ecl:brn eyr:2024 byr:1935 hgt:187cm hcl:#b6652a pid:770836724",
    "iyr:2014 cid:144 hgt:169cm eyr:2022 ecl:oth pid:117575716 hcl:#fffffd byr:1926",
    "byr:1971 ecl:brn hcl:#733820 eyr:1942 iyr:2013 pid:606274259 hgt:163cm cid:196",
    "byr:1964 pid:997828217 eyr:2029 iyr:2017 ecl:blu hcl:#341e13 hgt:158cm",
    "pid:568202531 hcl:#efcc98 hgt:154cm eyr:2029 iyr:2010 byr:1946 ecl:blu",
    "iyr:2011 pid:619355919 byr:1955 ecl:brn hcl:#888785 eyr:2030 hgt:155cm",
    "ecl:hzl pid:367152545 hgt:162cm cid:221 hcl:#866857 eyr:2024 byr:1997 iyr:2019",
    "hgt:157in cid:268 hcl:32371d byr:2020 ecl:zzz pid:1081234390",
    "ecl:hzl eyr:2026 byr:1969 pid:850482906 cid:166 hcl:#602927 hgt:60in iyr:2019",
    "hcl:#c0946f hgt:176cm ecl:brn eyr:2026 iyr:2018 cid:172 byr:1986 pid:172963254",
    "ecl:grn iyr:2016 hgt:187cm byr:1983 hcl:#efcc98 pid:722084344 eyr:2025",
    "ecl:oth hcl:#341e13 pid:130312766 hgt:171cm iyr:2018 byr:1927 eyr:2024",
    "byr:2021 hgt:152cm hcl:74dda6 eyr:1984 cid:216 iyr:2018 pid:95283942",
    "hcl:#b6652a pid:924778815 iyr:2017 ecl:gry eyr:2035 hgt:68cm",
    "iyr:2010 hcl:#efcc98 ecl:brn eyr:2020 pid:801894599 hgt:163cm byr:1959",
    "pid:798701070 eyr:2030 hcl:#866857 ecl:hzl hgt:169cm byr:1994 cid:219 iyr:2010",
    "pid:#e9b41b hcl:#341e13 byr:1970 iyr:2014 ecl:oth cid:266 hgt:68cm eyr:2023",
    "byr:1931 pid:929960843 hgt:187cm hcl:#6b5442 cid:52 iyr:2010 eyr:2024 ecl:brn",
    "iyr:2017 byr:1974 ecl:hzl cid:243 pid:66053995 hgt:147 eyr:1920 hcl:z",
    "iyr:2012 byr:1962 ecl:brn pid:773399437 hcl:#341e13 eyr:2026",
    "pid:738442771 hgt:186cm eyr:2027 hcl:#efcc98 iyr:2013 ecl:brn byr:1928",
    "pid:855794198 ecl:oth hgt:67in cid:81 iyr:2011 hcl:#b6652a eyr:2020 byr:1921",
    "hcl:176abf hgt:161in byr:2002 iyr:2016 eyr:2027 pid:639047770 ecl:brn cid:178",
    "pid:335686451 hcl:#86c240 iyr:2017 hgt:190cm byr:1968 ecl:amb",
    "hgt:150cm hcl:094a87 ecl:#09c463 eyr:1926 pid:537511570 byr:2009 iyr:1998",
    "hgt:74in pid:927963411 eyr:2026 ecl:gry cid:323 iyr:2012 hcl:#fffffd byr:1959",
    "iyr:2018 byr:1978 hcl:#ff1829 eyr:2023 pid:823129853 ecl:hzl hgt:65in",
    "pid:189cm ecl:#00391e hgt:72cm hcl:11050f byr:2029 eyr:1994 iyr:1935 cid:186",
    "ecl:grn byr:1942 pid:217290710 hgt:181cm eyr:2021 hcl:#7d3b0c iyr:2019 cid:320",
    "byr:1983 iyr:2013 cid:122 hcl:#ceb3a1 eyr:2030 hgt:59in ecl:grn pid:946451564",
    "ecl:amb cid:236 hgt:184cm hcl:#cfa07d iyr:2017 pid:934730535 eyr:2021 byr:2002",
    "byr:1950 ecl:hzl eyr:2030 hcl:#623a2f pid:742249321 hgt:158cm iyr:2018",
    "byr:1946 eyr:2021 hcl:#a97842 pid:204671558 ecl:grn iyr:2010 hgt:187cm",
    "hcl:#b6652a pid:528124882 hgt:162cm byr:1924 ecl:amb iyr:2027 cid:157 eyr:2028",
    "hgt:180cm iyr:2013 byr:1926 pid:232265934 hcl:#602927 ecl:oth",
    "byr:1984 ecl:brn iyr:2016 pid:756596443 eyr:2030 hcl:#7d3b0c hgt:183cm",
    "hgt:185cm hcl:#fffffd byr:1991 eyr:2023 iyr:2014 ecl:amb pid:759105859",
    "cid:82 iyr:2012 hgt:160cm eyr:2022 pid:593798464 ecl:gry hcl:#4e7571 byr:1983",
    "pid:478427550 iyr:2010 ecl:amb byr:1969 hgt:68in cid:94 eyr:2021 hcl:#866857",
    "ecl:amb iyr:2019 byr:1986 hgt:170cm hcl:#c0946f pid:779205106 eyr:2027",
    "ecl:brn eyr:2025 byr:1925 hcl:#7d3b0c hgt:76in pid:576353079 iyr:2010",
    "hgt:175cm hcl:4bf5ae ecl:amb eyr:2029 pid:173cm cid:329 iyr:1952 byr:1972",
    "ecl:grn eyr:2030 iyr:2015 hcl:#c0946f byr:1989 hgt:178cm pid:287209519",
    "pid:834505198 byr:1985 ecl:gry eyr:2024 cid:295 hgt:169cm iyr:2017",
    "hgt:170cm pid:054644831 eyr:2023 iyr:1949 ecl:amb hcl:#888785 byr:1955",
    "hgt:171cm pid:947263309 iyr:2015 byr:1944 eyr:2027 ecl:grn cid:79 hcl:#341e13",
    "eyr:1982 cid:147 iyr:2015 hgt:70cm hcl:a77c10 ecl:zzz byr:2007 pid:161cm",
    "ecl:gry byr:1933 hcl:#c0946f pid:483275512 iyr:2012 eyr:2025 hgt:161cm",
    "eyr:1985 hgt:176cm hcl:7b6ddc iyr:2012 cid:326 byr:1973 pid:929418396 ecl:gmt",
    "ecl:gry byr:1971 hgt:184cm eyr:2027 hcl:#3adf2c iyr:2017 cid:210 pid:693561862",
    "eyr:2021 pid:779298835 byr:1921 hgt:193cm ecl:amb iyr:2016 hcl:#ceb3a1",
    "hcl:4a1444 byr:2019 iyr:2024 hgt:182in cid:87 ecl:#122264 pid:181cm eyr:1927",
    "cid:267 ecl:amb eyr:2020 byr:2000 hcl:#18171d iyr:2012 hgt:190cm pid:18525759",
    "ecl:oth byr:1988 iyr:2019 pid:660570833 hcl:#866857 hgt:176cm",
    "eyr:2030 hcl:#866857 byr:1967 cid:316 pid:560346474 iyr:2015 hgt:160cm ecl:gry",
    "ecl:hzl iyr:2014 hgt:164cm hcl:#733820 eyr:2025 pid:106302413 byr:1920",
    "iyr:2016 pid:515066491 ecl:grn eyr:2026 hgt:179cm hcl:#b6652a byr:1982",
    "ecl:#7de6a0 iyr:2004 eyr:1955 hgt:154cm cid:138 byr:2004 pid:758934555 hcl:a21980",
    "pid:#2a21e0 ecl:#1b9b27 hgt:165in byr:1998 iyr:2014 eyr:2032",
    "eyr:2021 hgt:184cm pid:431054313 hcl:#ceb3a1 cid:109 byr:1977 ecl:blu iyr:2011",
    "pid:006339126 hgt:177cm cid:188 hcl:#a97842 iyr:1959 ecl:xry"
  ]
