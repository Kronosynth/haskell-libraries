module Memory
( memoizeInfinite
, memoizeLimited
, memCall
, eraseMemory
, changeLimit ) where

import qualified Data.Map as M

data Unary a b = Inf (a -> b) (M.Map a b)
               | Fin (a -> b) [(a,b)] Int

instance (Show a, Show b) => Show (Unary a b) where
  show (Inf _ memory) = "Inf{" ++ show memory ++ "}"
  show (Fin _ memory limit) =
    "Fin{" ++ show memory ++ ":" ++ show limit ++ "}"

memoizeInfinite :: (a -> b) -> Unary a b
memoizeInfinite fn = Inf fn M.empty

memoizeLimited  :: (a -> b) -> Int -> Unary a b
memoizeLimited  fn = Fin fn []

memCall :: Ord a => Unary a b -> a -> (b, Unary a b)
memCall (Inf fn memory) arg =
  case M.lookup arg memory of
    Just n  -> (n,    Inf fn memory)
    Nothing -> (eval, Inf fn (M.insert arg eval memory))
  where eval = fn arg
memCall (Fin fn memory limit) arg =
  case search arg memory of
    Just (n, searched) -> (n,    Fin fn ((arg,n) : searched)  limit)
    Nothing            -> (eval, Fin fn ((arg,eval) : forget) limit)
  where search :: Eq a => a -> [(a,b)] -> Maybe (b, [(a,b)])
        search _ [] = Nothing
        search a ((x,y) : xs)
          | a == x    = Just (y,xs)
          | otherwise = case search a xs of
                          Just (m,rest) -> Just (m,(x,y):rest)
                          Nothing       -> Nothing
        eval = fn arg
        forget
          | length memory >= limit = init memory
          | otherwise              = memory

eraseMemory :: Unary a b -> Unary a b
eraseMemory (Inf fn _)       = Inf fn M.empty
eraseMemory (Fin fn _ limit) = Fin fn [] limit

changeLimit :: Unary a b -> Int -> Unary a b
changeLimit (Fin fn memory _) newlimit =
  Fin fn (take newlimit memory) newlimit
changeLimit _ _ = error "Cannot change limit on an infinite \
                        \memoized function."
