import Json

main :: IO ()
main = do print car
          printWeight (find_one car "weight")
          mapM_ printPosition (find car "position")
          putStrLn (json_string car 0)
          putStrLn ("\n" ++ to_xml car)
 where car = make_car

printWeight :: Maybe JSON -> IO ()
printWeight (Just (JSONNumber n)) = putStrLn "Correct!"
printWeight _                     = putStrLn "found the wrong thing"

printPosition :: JSON -> IO ()
printPosition (JSONNumber n) = print n
printPosition _              = putStrLn "found the wrong thing"

