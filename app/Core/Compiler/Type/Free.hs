module Core.Compiler.Type.Free where
  import Core.TypeChecking.Type.AST
  import Data.List (union, (\\))
  class Free a where
    free :: a -> [String]
  
  instance Free TypedStatement where
    free (Assignment (name :@ _) e) = free e \\ [name]
    free (Modified n e) = free e \\ free n
    free (If c t e) = free c `union` free t `union` free e
    free (Sequence ss) = free ss
    free (Expression e)  = free e
    free (Return e) = free e
    free (Enum _ _) = []

  instance Free TypedExpression where
    free (FunctionCall n xs _) = free n `union` free xs
    free (Lambda args body) = free body \\ args'
      where args' = map (\(x :@ _) -> x) args
    free (Variable s) = [s]
    free (Literal _) = []
    free (BinaryOp s x y) = free x `union` free y
    free (UnaryOp s x) = free x
    free (List xs) = free xs
    free (Index e i) = free e `union` free i
    free (Structure fields) = free $ map snd fields
    free (Object e _) = free e
    free (Ternary c t e) = free c `union` free t `union` free e
    free (Reference c) = free c
    free (Unreference c) = free c
    free (Match e cases) = free e `union` c
      where c = concatMap (\(x,y) -> free y \\ free x) cases
    free (Constructor _) =[]

  instance Free TypedPattern where
    free (VarP x _) = [x]
    free (LitP _) = []
    free WilP = []
    free (AppP _ xs) = free xs

  instance (Free a, Free b) => Free (a, b) where
    free (x, y) = free x `union` free y

  instance Free a => Free [a] where
    free = foldr (union . free) []