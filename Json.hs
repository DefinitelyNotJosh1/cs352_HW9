-- Authors: Joshua Krasnogorov and Stephen Libby
-- Assignment 9: JSON in Haskell
-- due date: 3/31/2025

{-# OPTIONS_GHC -Wno-unrecognised-pragmas #-}
{-# HLINT ignore "Use camelCase" #-}

module Json where

-- In this assignment we're going to work with JSON data.
-- Ultimately, our goal is to convert JSON to XML, but we'll get there.
-- Baby Steps!
--
-- JSON: JavaScript Object Notation
-- Json as a very common way of representing data on the web.
-- It's lightweight and easy to use,
-- and most languages (including rust) have support for reading and writing JSON.
-- We're going to be making our own library for working with JSON.
-- There are 3 reasons for this.
--  1. This is a good chance to work with recursive data structures.
--  2. The Rust version of JSON is a bit more complicated then what I want to work with
--  3. We want to convert this to XML.
--  4. The Json crate is external, and I don't have to have to deal with that.
-- If you're curious, we're leaving out Short and Array.
--
--  JSON objects have the form
--  {
--      key1 : value1,
--      key2 : value2,
--      key3 : value3
--  }
--  The keys are all normal variable names, but the values can be any of
--  Number, Boolean, String, Null, or Object.
--
--  As an example, we might use JSON to represent a car at a repair shop:
--  {
--      make : "Ford",
--      model : null,
--      weight : 32,
--      running : false,
--      wheel : { position : 1, inflated : true }
--      wheel : { position : 2, inflated : true }
--      wheel : { position : 3, inflated : true }
--      wheel : { position : 4, inflated : true }
--   }
--
-- We can give a formal grammar for a JSON object as follows.
-- JSON = String 
--      | Number 
--      | true 
--      | false 
--      | null
--      | { (ID : JSON)* }
--
-- Or, we can look at the Haskell definition.
-- Most of the cases here are really easy.
-- The only complicated one is JSONObject.
-- A JSONObject has a list of key,value pairs.
-- The keys are just string (the identifiers),
-- but the values could be any type of JSON, even another JSONObject.
--
-- Note: We've seen Clone before.
-- It just lets us call .clone() if we need a copy of the JSON object.
-- The PartialEq is similar.  It lets us use == and != with JSON objects.
-- the #[derive(...)]  is a clever bit of rust.
-- It turns out that some Traits (java interfaces) are so predictable
-- that we can automatically generate them for most types.
-- The  #[derive(...)] automatically writes the code for the PartialEq and Clone traits.

data JSON = JSONString String
          | JSONNumber Int
          | JSONTrue
          | JSONFalse
          | JSONNull
          | JSONObject [(String,JSON)]
 deriving(Show, Eq, Ord)


-- Problem 1:
-- Write a function to create the car JSON object from before.
--  {
--      make : "Ford",
--      model : null,
--      weight : 32,
--      running : false,
--      wheel : { position : 1, inflated : true }
--      wheel : { position : 2, inflated : true }
--      wheel : { position : 3, inflated : true }
--      wheel : { position : 4, inflated : true }
--   }
-- We are making this exact object, nSot a general car JSON object.
make_car :: JSON
make_car = JSONObject [("make", JSONString "Ford"),
                       ("model", JSONNull),
                       ("weight", JSONNumber 32),
                       ("running", JSONFalse),
                       ("wheel", JSONObject [("position", JSONNumber 1), ("inflated", JSONTrue)]),
                       ("wheel", JSONObject [("position", JSONNumber 2), ("inflated", JSONTrue)]),
                       ("wheel", JSONObject [("position", JSONNumber 3), ("inflated", JSONTrue)]),
                       ("wheel", JSONObject [("position", JSONNumber 4), ("inflated", JSONTrue)])]

-- Problem 2:
-- write a function to find a value in the JSON object matching the given key.
-- If no object exists, just return Nothing.
find_one :: JSON -> String -> Maybe JSON
find_one json key = case json of
    JSONObject pairs -> 
        let directMatch = foldr (\(k,v) acc -> if k == key then Just v else acc) Nothing pairs
        in case directMatch of
            Just v  -> Just v
            Nothing -> foldr (\(_,v) acc -> case find_one v key of
                            Just found -> Just found
                            Nothing -> acc) Nothing pairs
    _ -> Nothing

-- Problem 3:
-- Write a function to find all of the values that match a key.
-- You should return the values as a list
find :: JSON -> String -> [JSON]
find json key = case json of
    JSONObject pairs -> 
        let directMatches = foldr (\(k,v) acc -> if k == key then v:acc else acc) [] pairs
            nestedMatches = concatMap (\(_,v) -> find v key) pairs
        in directMatches ++ nestedMatches
    _ -> []

-- Problem 4:
-- Write a function to convert a JSON object to a string.
-- We want the string to look nice, so we want to tab in when
-- we're printing an inner object.
-- For example json_string(*make_car()) should return
-- {
--   make : "Ford",
--   model : null,
--   weight : 32,
--   running : false,
--   wheel : { 
--     position : 1,
--     inflated : true 
--   }
--   wheel : { 
--     position : 2, 
--     inflated : true 
--   }
--   wheel : { 
--     position : 3, 
--     inflated : true 
--   }
--   wheel : { 
--     position : 4, 
--     inflated : true 
--   }
-- }
--
-- for this to get full credit you need
--  * string should be surrounded by quotes
--  * object should use the C style for braces (left brace is on the same line)
--  * you need to indent each nested object. You should indent 2 spaces each time.
--
-- You might find the replicate function helpful.
json_string :: JSON -> Int -> String
json_string js i = replicate i ' ' ++ json_to_string js i
    where json_to_string (JSONString s) _ = "\"" ++ s ++ "\""
          json_to_string (JSONNumber n) _ = show n
          json_to_string JSONTrue _ = "true"
          json_to_string JSONFalse _ = "false"
          json_to_string JSONNull _ = "null"
          json_to_string (JSONObject x) i = 
            "{\n" ++ 
            (case x of
                [] -> ""
                _  -> concatMap (\(k,v) -> replicate (i+2) ' ' ++ k ++ " : " ++ json_to_string v (i+2) ++ ",\n") (init x) ++
                    let (k,v) = last x in replicate (i+2) ' ' ++ k ++ " : " ++ json_to_string v (i+2) ++ "\n"                 ) ++ 
            replicate i ' ' ++ "}"
          

-- problem 5:
-- Ok, we're finally at the last step.
-- This is going to be a lot like problem 4, but this time our string
-- is going to be formatted as XML.
--
-- As a review XML is a tag based language.
-- Everything is surrounded by tags, with an open tag and a closing tag.
-- For example, we might represent blue being a color as
-- <color>blue</color>
--
-- We do run into a bit of a snag here, because the root object in JSON
-- doesn't have a name.
-- To deal with this, we'll call the root object "Object".
-- So, our car example would look like this.
-- <Object>
--   <make>"Ford"</make>
--   <model>null</model>
--   <weight>32</weight>
--   <running>false</weight>
--   <wheel>
--     <position>1</position>
--     <inflated>true</inflated>
--   </wheel>
--   <wheel>
--     <position>2</position>
--     <inflated>true</inflated>
--   </wheel>
--   <wheel>
--     <position>3</position>
--     <inflated>true</inflated>
--   </wheel>
--   <wheel>
--     <position>4</position>
--     <inflated>true</inflated>
--   </wheel>
-- </Object>
--
-- Notice this time that Strings, Numbers, booleans, nulls are all on their own line,
-- but nested objects are on new lines and indented.
--
-- I've given you a helper function to deal with the root object.
to_xml :: JSON -> String
to_xml json = "<Object>" ++ json_to_xml json 2 ++ "</Object>"

json_to_xml :: JSON -> Int -> String
json_to_xml js i = json_to_xml js i
    where json_to_xml (JSONString s) _ = "\"" ++ s ++ "\""
          json_to_xml (JSONNumber n) _ = show n
          json_to_xml JSONTrue _ = "true"
          json_to_xml JSONFalse _ = "false"
          json_to_xml JSONNull _ = "null"
          json_to_xml (JSONObject x) i = "\n" ++
            (case x of
                [] -> ""
                _  -> concatMap (\(k,v) -> replicate i ' ' ++ "<" ++ k ++ ">" ++ json_to_xml v (i+2) ++ "<\\" ++ k ++ ">" ++ "\n") (init x)) ++ replicate (i-2) ' '

