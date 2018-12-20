module Eval

import AST;
import Resolve;

/*
 * Implement big-step semantics for QL
 */
 
// NB: Eval may assume the form is type- and name-correct.


// Semantic domain for expressions (values)
data Value
  = vint(int n)
  | vbool(bool b)
  | vstr(str s);

// The value environment
alias VEnv = map[str name, Value \value];

// Modeling user input
data Input
  = input(str question, Value \value);
  
// produce an environment which for each question has a default value
// (e.g. 0 for int, "" for str etc.)
VEnv initialEnv(AForm f) {
  return ( q.id : defaultValue(q.questionType) | /AQuestion q := f.questions, q has questionType );
}

Value defaultValue(AType t) {
	switch (t) {
		case booleanType():
			return vbool(false);
		
		case integerType():
			return vint(0);
		
		case stringType():
			return vstr("");
		
		default:
			throw "Unsupported Type <t>";
	}
}


// Because of out-of-order use and declaration of questions
// we use the solve primitive in Rascal to find the fixpoint of venv.
VEnv eval(AForm f, Input inp, VEnv venv) {
  return solve (venv) {
    venv = evalOnce(f, inp, venv);
  }
}

VEnv evalOnce(AForm f, Input inp, VEnv venv) {
	Aquestion question;
	
	for (/AQuestion q := f) {
	  	  venv += eval(q, inp, venv);
	}
	return venv;
}

VEnv eval(AQuestion q, Input inp, VEnv venv) {
  // evaluate conditions for branching,
  // evaluate inp and computed questions to return updated VEnv
    switch (q) {
    //if it is an ordinary question, we should update the value of the question in the venv
      case question(_, str identifier, _, _): 
      	if (identifier == inp.question) {
      		return venv + (inp.question : inp.\value);
      	}
      
      //if it is computed, we need to evaluate what is computed and asign it to the venv
      case computed(_, str identifier, _, AExpr expr, _):
      	return venv + (inp.question : eval(expr, venv));
      
      //if if-then question, evaluate the guard and recursively call if it is true
      case ifThen(AExpr guard, AQuestion question, _):
      	if (eval(guard, venv) == vbool(true)) {
          return eval(question, inp, venv);
      	}
      
      //if if-then-else question, evaluate the guard and recursively call the adequate question
      case ifThenElse(AExpr guard, AQuestion ifQ, AQuestion elseQ, _):
        if (eval(guard, venv) == vbool(true)) {
          return eval(ifQ, inp, venv);
        } else {
          return eval(elseQ, inp, venv);
        }
      default: return venv;
  }
}

Value eval(AExpr e, VEnv venv) {
  switch (e) {
    case ref(str x): return venv[x];
    case boolean(bool boolValue): return vbool(boolValue);
    case integer(int intValue): return vint(intValue);
    case string(str stringValue): return vstr(stringValue);
    case brackets(AExpr expr): return eval(expr, venv);
    case not(AExpr expr): return vbool(!eval(expr).b);
    case mul(AExpr lhs, AExpr rhs): return vint(eval(lhs, venv).n * eval(rhs, venv).n);
    case div(AExpr lhs, AExpr rhs): return vint(eval(lhs, venv).n / eval(rhs, venv).n);
    case add(AExpr lhs, AExpr rhs): return vint(eval(lhs, venv).n + eval(rhs, venv).n);
    case sub(AExpr lhs, AExpr rhs): return vint(eval(lhs, venv).n - eval(rhs, venv).n);
    case gt(AExpr lhs, AExpr rhs): return vbool(eval(lhs, venv).n > eval(rhs, venv).n);
    case lt(AExpr lhs, AExpr rhs): return vbool(eval(lhs, venv).n < eval(rhs, venv).n);
    case geq(AExpr lhs, AExpr rhs): return vbool(eval(lhs, venv).n >= eval(rhs, venv).n);
    case leq(AExpr lhs, AExpr rhs): return vbool(eval(lhs, venv).n <= eval(rhs, venv).n);
    case equal(AExpr lhs, AExpr rhs): {
      Value helpLhs = eval(lhs, venv);
      Value helpRhs = eval(rhs, venv);
	      if (helpLhs has n && helpRhs has n) {
	        return vbool(helpLhs.n == helpRhs.n);
	      }
	      if (helpLhs has b && helpRhs has b) {
	        return vbool(helpLhs.b == helpRhs.b);
	      }
	      if (helpLhs has s && helpRhs has s) {
	        return vbool(helpLhs.s == helpRhs.s);
	      }
	      return vbool(false);
      }
    case neq(AExpr lhs, AExpr rhs): {
      Value helpLhs = eval(lhs, venv);
      Value helpRhs = eval(rhs, venv);
	      if (helpLhs has n && helpRhs has n) {
	        return vbool(helpLhs.n == helpRhs.n);
	      }
	      if (helpLhs has b && helpRhs has b) {
	        return vbool(helpLhs.b == helpRhs.b);
	      }
	      if (helpLhs has s && helpRhs has s) {
	        return vbool(helpLhs.s == helpRhs.s);
	      }
	      return vbool(false);
      }
    case and(AExpr lhs, AExpr rhs): return vbool(eval(lhs, venv).b && eval(rhs, venv).b);
    case or(AExpr lhs, AExpr rhs): return vbool(eval(lhs, venv).b || eval(rhs, venv).b);

    
    // etc.
    
    default: throw "Unsupported expression <e>";
  }
}