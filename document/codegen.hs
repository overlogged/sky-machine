import Data.Char
import Data.List
import Text.Printf

f::Int->Int
f x
        | x==0 = 0
        | x>=ord 'a'&&x<=ord 'z' = x-ord 'a'+1
        | x>=ord 'A'&&x<=ord 'Z' = x-ord 'A'+27
        | x==ord '\n' = 66
        | otherwise = sum $ map (\(c,i)->if x==ord c then i else 0) (zip "$()=>\\ ." [53..60])
        
invf::Int->Int
invf t = head [x|x<-[0..255],f x ==t]

s = 
    let strs= [" ",
                "$id =\\x.x","(\\xx.xx) a",
                "id yyy",
                "$true=\\a.\\b.a",
                "$false=\\a.\\b.b",
                "true",
                "$zero=\\f.\\x.x",
                "$one=\\f.\\x.f x",
                "$two=\\f.\\x.f (f x)",
                "$succ=\\n.\\f.\\x.f ((n f) x)",
                "$two=succ one","$three=succ two"
            ] in sequence_ $ (map putStr ["parameter count = ",(show (length strs)),";\n","wire [7:0] string [0:count-1][0:max_size-1];\n"]) ++ map (\(index,tstr)->let str=tstr++"\n" in sequence_ $ map putStr $ ["/*",tstr,"*/\n"] ++ [printf "assign string[%d][%d] = 8'd%d;\n" index (fst t::Int) (f (ord (snd t))::Int) ::String | t<-zip [0..] str] ++ [printf "assign string[%d][%d] = 8'd0;\n" index (length str)]) (zip ([0..]::[Int]) strs)

t = sequence_ $ map (\(i,x)->putStrLn $ (printf "\tassign string[%d] = 8'd%d;" (i::Int) x::String)) $ zip [0..] (map (f.ord) "$id =\\x.x\n")

{- [0,255]->[0,63] -}
showc s = map (\x->chr $ head [c|c<-[0..255],f c==x]) s