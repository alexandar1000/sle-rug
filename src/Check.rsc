module Check

import AST;
import Resolve;
import Message; // see standard library
import Set;


data Type
  = tint()
  | tbool()
  | tstr()
  | tunknown();

// the type environment consisting of defined questions in the form 
alias TEnv = rel[loc def, str name, str label, Type \type];

//resolve the AType to the abovemntioned Type
Type resolveType(booleanType()) = tbool();
Type resolveType(integerType()) = tint();
Type resolveType(stringType()) = tstr();
default Type resolveType(AType _) = tunknown();


// To avoid recursively traversing the form, use the `visit` construct
// or deep match (e.g., `for (/question(...) := f) {...}` ) 
TEnv collect(AForm f) {
   return { <q.src, q.id, q.lbl, resolveType(q.questionType)> | /AQuestion q := f.questions, q has id }; 
}

// returns a set which is a union of errors end messages for questions and expressions respectivey 
set[Message] check(AForm f, TEnv tenv, UseDef useDef) {
	//TODO: check if qst <- f.questions should be /AQuestion qst := f
	return union({check(q, tenv, useDef) | /AQuestion q := f.questions, q has id})
			+ union({check(exp, tenv, useDef) | /AExpr exp := f}) ; 
}

// - produce an error if there are declared questions with the same name but different types.
// - duplicate labels should trigger a warning 
// - the declared type computed questions should match the type of the expression.
set[Message] check(AQuestion q, TEnv tenv, UseDef useDef) {
  return { error("A question with the same name <q.id>, but a different type already exists", q.src) | q has id, size(tenv[_, q.id, _]) > 1 } //tenv[_, q.id, _] will not return duplicate types, so if there are different types, the set returned will be of size greater than 1
  			+ { warning("A label with the same text <q.lbl> exists", q.src) | q has lbl, size((tenv<2, 0>)[q.lbl]) > 1 } //since src is the relation *key*, the set returned in tenv<2, 0> will contain all of the unique values of the label  
  			+ { error("The declared type of the computed question <q.id> should match the type of the expression", q.src) | q has computedExpr, resolveType(q.questionType) != typeOf(q.computedExpr, tenv, useDef) }; 
}

// Check operand compatibility with operators.
// E.g. for an addition node add(lhs, rhs), 
//   the requirement is that typeOf(lhs) == typeOf(rhs) == tint()
set[Message] check(AExpr e, TEnv tenv, UseDef useDef) {
  set[Message] msgs = {};
  baseErr = "Incompatible type used. The operator ";
  
  switch (e) {
    case ref(str x, src = loc u):
      msgs += { error("Undeclared question", u) | useDef[u] == {} };
      
    case not(AExpr expr, src = loc u):
      msgs += { error(baseErr + "(!) expects an operand of the type boolean.", u) | typeOf(expr, tenv, useDef) != tbool()};

    case mul(AExpr lhs, AExpr rhs, src = loc u):
      msgs += { error(baseErr + "`*` expects operands of the type integer.", u) | !(typeOf(lhs, tenv, useDef) == tint() && typeOf(rhs, tenv, useDef) == tint()) };

    case div(AExpr lhs, AExpr rhs, src = loc u):
      msgs += { error(baseErr + "`/` expects operands of the type integer.", u) | !(typeOf(lhs, tenv, useDef) == tint() && typeOf(rhs, tenv, useDef) == tint()) };

    case add(AExpr lhs, AExpr rhs, src = loc u):
      msgs += { error(baseErr + "`+` expects operands of the type integer.", u) | !(typeOf(lhs, tenv, useDef) == tint() && typeOf(rhs, tenv, useDef) == tint()) };

    case sub(AExpr lhs, AExpr rhs, src = loc u):
      msgs += { error(baseErr + "`-` expects operands of the type integer.", u) | !(typeOf(lhs, tenv, useDef) == tint() && typeOf(rhs, tenv, useDef) == tint()) };

    case gt(AExpr lhs, AExpr rhs, src = loc u):
      msgs += { error(baseErr + "`\>` expects operands of the type integer.", u) | !(typeOf(lhs, tenv, useDef) == tint() && typeOf(rhs, tenv, useDef) == tint()) };

    case lt(AExpr lhs, AExpr rhs, src = loc u):
      msgs += { error(baseErr + "`\<` expects operands of the type integer.", u) | !(typeOf(lhs, tenv, useDef) == tint() && typeOf(rhs, tenv, useDef) == tint()) };

    case geq(AExpr lhs, AExpr rhs, src = loc u):
      msgs += { error(baseErr + "`\>=` expects operands of the type integer.", u) | !(typeOf(lhs, tenv, useDef) == tint() && typeOf(rhs, tenv, useDef) == tint()) };

    case equal(AExpr lhs, AExpr rhs, src = loc u):
      msgs += { error(baseErr + "`==` expects operands of the same type.", u) | !(typeOf(lhs, tenv, useDef) == typeOf(rhs, tenv, useDef)) };

    case neq(AExpr lhs, AExpr rhs, src = loc u):
      msgs += { error(baseErr + "`!=` expects operands of the same type.", u) | !(typeOf(lhs, tenv, useDef) == typeOf(rhs, tenv, useDef)) };

    case and(AExpr lhs, AExpr rhs, src = loc u):
      msgs += { error(baseErr + "`&&` expects operands of the type boolean.", u) | !(typeOf(lhs, tenv, useDef) == tbool() && typeOf(rhs, tenv, useDef) == tbool()) };

    case geq(AExpr lhs, AExpr rhs, src = loc u):
      msgs += { error(baseErr + "`||` expects operands of the type boolean.", u) | !(typeOf(lhs, tenv, useDef) == tbool() && typeOf(rhs, tenv, useDef) == tbool()) };
  }
  
  return msgs; 
}

Type typeOf(AExpr e, TEnv tenv, UseDef useDef) {
  switch (e) {
    case ref(str name, src = loc u):  
      if (<u, loc d> <- useDef, <d, name, _, Type t> <- tenv) {
        return t;
      }
    case boolean(_): return tbool();
    case integer(_): return tint();
    case string(_): return tstr();
    case brackets(AExpr expr): return typeOf(expr, tenv, useDef);
    case not(_): return tbool();
    case mul(_, _): return tint();
    case div(_, _): return tint();
    case add(_, _): return tint();
    case sub(_, _): return tint();
    case gt(_, _): return tbool();
    case lt(_, _): return tbool();
    case geq(_, _): return tbool();
    case leq(_, _): return tbool();
    case equal(_, _): return tbool();    
    case neq(_, _): return tbool();
    case and(_, _): return tbool();
    case or(_, _): return tbool();
    default: return tunknown();
  }
}

/* 
 * Pattern-based dispatch style:
 * 
 * Type typeOf(ref(str x, src = loc u), TEnv tenv, UseDef useDef) = t
 *   when <u, loc d> <- useDef, <d, x, _, Type t> <- tenv
 *
 * ... etc.
 * 
 * default Type typeOf(AExpr _, TEnv _, UseDef _) = tunknown();
 *
 */
 
 
 

