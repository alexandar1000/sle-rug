module Syntax

extend lang::std::Layout;
extend lang::std::Id;

/*
 * Concrete syntax of QL
 */

start syntax Form 
  = "form" Id "{" Question* "}"; 

// TODO: question, computed question, block, if-then-else, if-then
syntax Question
  = Str Id ":" Type
  | Str Id ":" Type "=" Expr
  | "{" Question* "}"
  | "if" "(" Expr ")" Question !>> "else" // !>>: can not be followed by "else"
  | "if" "(" Expr ")" Question "else" Question
  ; 

// TODO: +, -, *, /, &&, ||, !, >, <, <=, >=, ==, !=, literals (bool, int, str)
// Think about disambiguation using priorities and associativity
// and use C/Java style precedence rules (look it up on the internet)
syntax Expr 
  = Id \ "true" \ "false" // true/false are reserved keywords.
  | Bool // 0
  | Int
  | Str // Not in examples, but mentioned on course page
  | "(" Expr ")" // In examples, but mentioned nowhere
  | right "!" Expr // 1
  > left (Expr "*" Expr // 2
  | Expr "/" Expr)
  > left (Expr "+" Expr // 3
  | Expr "-" Expr)
  > left (Expr "\>" Expr // 4
  | Expr "\<" Expr
  | Expr "\<=" Expr
  | Expr "\>=" Expr)
  > left (Expr "==" Expr // 5
  | Expr "!=" Expr)
  > left Expr "&&" Expr // 6
  > left Expr "||" Expr // 7
  ;
  
syntax Type
  = "boolean"
  | "integer"
  | "string"
  ;
  
lexical Str = [\"] ![\"]* [\"];

lexical Int = [0-9]+;

lexical Bool = "true" | "false";


