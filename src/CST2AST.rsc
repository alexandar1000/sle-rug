module CST2AST

import Syntax;
import AST;

import ParseTree;
import String;
import Boolean;

/*
 * Implement a mapping from concrete syntax trees (CSTs) to abstract syntax trees (ASTs)
 *
 * - Use switch to do case distinction with concrete patterns (like in Hack your JS) 
 * - Map regular CST arguments (e.g., *, +, ?) to lists 
 *   (NB: you can iterate over * / + arguments using `<-` in comprehensions or for-loops).
 * - Map lexical nodes to Rascal primitive types (bool, int, str)
 * - See the ref example on how to obtain and propagate source locations.
 */

AForm cst2ast(start[Form] sf) = cst2ast(sf.top);

AForm cst2ast(f:(Form)`form <Id x> { <Question* qs> }`) {
  return form("<x>", [ cst2ast(q) | Question q <- qs ], src=f@\loc); 
}

AQuestion cst2ast(q:Question q) {
  switch (q) {
    case (Question)`<Str q> <Id x> : <Type t>`:
      return question("<q>", "<x>", cst2ast(t), src=q@\loc);
    case (Question)`<Str q> <Id x> : <Type t> = <Expr e>`:
    	return computed("<q>", "<x>", cst2ast(t), cst2ast(e), src=q@\loc);
   	case (Question)`{ <Question* qs> }`:
    	return block([ cst2ast(question) | question <- qs ], src=q@\loc);
    case (Question)`if ( <Expr e> ) <Question q>`:
    	return ifThen(cst2ast(e), cst2ast(q), src=q@\loc);
    case (Question)`if ( <Expr e> ) <Question q> else <Question q2>`:
    	return ifThenElse(cst2ast(e), cst2ast(q), cst2ast(q2), src=q@\loc);
    default: throw "Unhandled question: <q>";
  }
}

AExpr cst2ast(e:Expr e) {
  switch (e) {
    case (Expr)`<Id x>`: 
      return ref("<x>", src=e@\loc);
    case (Expr)`<Bool b>`:
      return boolean(fromString("<b>"), src=e@\loc);
    case (Expr)`<Int i>`:
      return integer(toInt("<i>"), src=e@\loc);
    case (Expr)`<Str s>`:
      return string("<s>", src=e@\loc);
    case (Expr)`( <Expr e> )`:
      return brackets(cst2ast(e), src=e@\loc);
    case (Expr)`! <Expr e>`:
      return not(cst2ast(e));
    case (Expr)`<Expr l> * <Expr r>`:
      return mul(cst2ast(l), cst2ast(r), src=e@\loc);
    case (Expr)`<Expr l> / <Expr r>`:
      return div(cst2ast(l), cst2ast(r), src=e@\loc);
    case (Expr)`<Expr l> + <Expr r>`:
      return add(cst2ast(l), cst2ast(r), src=e@\loc);
    case (Expr)`<Expr l> - <Expr r>`:
      return sub(cst2ast(l), cst2ast(r), src=e@\loc);
    case (Expr)`<Expr l> \> <Expr r>`:
      return gt(cst2ast(l), cst2ast(r), src=e@\loc);
    case (Expr)`<Expr l> \< <Expr r>`:
      return lt(cst2ast(l), cst2ast(r), src=e@\loc);
    case (Expr)`<Expr l> \<= <Expr r>`:
      return leq(cst2ast(l), cst2ast(r), src=e@\loc);
    case (Expr)`<Expr l> \>= <Expr r>`:
      return geq(cst2ast(l), cst2ast(r), src=e@\loc);
    case (Expr)`<Expr l> == <Expr r>`:
      return eq(cst2ast(l), cst2ast(r), src=e@\loc);
    case (Expr)`<Expr l> != <Expr r>`:
      return neq(cst2ast(l), cst2ast(r), src=e@\loc);
    case (Expr)`<Expr l> && <Expr r>`:
      return and(cst2ast(l), cst2ast(r), src=e@\loc);
    case (Expr)`<Expr l> || <Expr r>`:
      return or(cst2ast(l), cst2ast(r), src=e@\loc);
    default: throw "Unhandled expression: <e>";
  }
}

AType cst2ast(t:Type t) {
  switch (t) {
  	case (Type)`boolean`:
  	  return booleanType(src=t@\loc);
  	case (Type)`integer`:
  	  return integerType(src=t@\loc);
  	case (Type)`string`:
  	  return stringType(src=t@\loc);
  	default: throw "Unhandled type: <t>";
  }
}
