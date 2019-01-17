module AST

/*
 * Abstract Syntax for QL
 *
 */

data AForm(loc src = |tmp:///|)
  = form(str name, list[AQuestion] questions); 

data AQuestion(loc src = |tmp:///|)
  = question(str lbl, str id, AType questionType)
  | computed(str lbl, str id, AType questionType, AExpr computedExpr)
  | block(list[AQuestion] questions)
  | ifThen(AExpr guard, AQuestion question)
  | ifThenElse(AExpr guard, AQuestion ifQuestion, AQuestion elseQuestion); 

data AExpr(loc src = |tmp:///|)
  = ref(str name)
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
  | equal(AExpr lhs, AExpr rhs)
  | neq(AExpr lhs, AExpr rhs)
  | and(AExpr lhs, AExpr rhs)
  | or(AExpr lhs, AExpr rhs);

data AType(loc src = |tmp:///|)
  = booleanType()
  | integerType()
  | stringType()
  | unknownType();
