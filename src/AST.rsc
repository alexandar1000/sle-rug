module AST

/*
 * Define Abstract Syntax for QL
 *
 * - complete the following data types
 * - make sure there is an almost one-to-one correspondence with the grammar
 */

data AForm(loc src = |tmp:///|)
  = form(str name, list[AQuestion] questions); 

data AQuestion(loc src = |tmp:///|)
  = question(str lbl, str id, AType questionType)
  | computed(str lbl, str id, AType questionType, AExpr computedExpr)
  | block(list[AQuestion] questions)
  | ifThen(AExpr guardExpr, AQuestion question)
  | ifThenElse(AExpr guardExpr, AQuestion question, AQuestion question)
  ; 

data AExpr(loc src = |tmp:///|)
  = ref(str name)
  | \true()
  | \false()
  | boolean(bool boolValue)
  | integer(int intValue)
  | string(str stringValue)
  | brackets(AExpr expr)
  | not(AExpr expr)
  | mul(AExpr lhs, AExpr rhs)
  | div(AExpr lhs, AExpr rhs)
  | add(AExpr lhs, AExpr rhs)
  | sub(AExpr lhs, AExpr rhs)
  | gt(AExpr lhs, AExpr rhs)
  | lt(AExpr lhs, AExpr rhs)
  | geq(AExpr lhs, AExpr rhs)
  | leq(AExpr lhs, AExpr rhs)
  | eq(AExpr lhs, AExpr rhs)
  | neq(AExpr lhs, AExpr rhs)
  | and(AExpr lhs, AExpr rhs)
  | or(AExpr lhs, AExpr rhs)
  ;

data AType(loc src = |tmp:///|)
  = booleanType()
  | integerType()
  | stringType()
  | unknownType()
  ;
