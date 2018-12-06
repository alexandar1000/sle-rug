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
  = question(str q, str id, AType ansType)
  | computed(str q, str id, AType ansType, AExpr expr)
  | block(list[AQuestion] questions)
  | ifThen(AExpr expr, AQuestion question)
  | ifThenElse(AExpr expr, AQuestion question, AQuestion question)
  ; 

data AExpr(loc src = |tmp:///|)
  = ref(str name)
  | \true()
  | \false()
  | integer(int intValue)
  | string(str stringValue)
  | brackets(AExpr expr)
  | not(AExpr expr)
  | mul(AExpr l, AExpr r)
  | div(AExpr l, AExpr r)
  | add(AExpr l, AExpr r)
  | sub(AExpr l, AExpr r)
  | gt(AExpr l, AExpr r)
  | lt(AExpr l, AExpr r)
  | leq(AExpr l, AExpr r)
  | geq(AExpr l, AExpr r)
  | eq(AExpr l, AExpr r)
  | neq(AExpr l, AExpr r)
  | and(AExpr l, AExpr r)
  | or(AExpr l, AExpr r)
  ;

data AType(loc src = |tmp:///|)
  = booleanType()
  | integerType()
  | stringType()
  ;
