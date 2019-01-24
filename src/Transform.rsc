module Transform

import Resolve;
import AST;
import Syntax;
import Set;
import IO;
import ParseTree;

/* 
 * Transforming QL forms
 */
 
 
/* Normalization:
 *  wrt to the semantics of QL the following
 *     q0: "" int; if (a) { if (b) { q1: "" int; } q2: "" int; }
 *
 *  is equivalent to
 *     if (true) q0: "" int;
 *     if (a && b) q1: "" int;
 *     if (a) q2: "" int;
 *
 * Write a transformation that performs this flattening transformation.
 *
 */
 
AForm flatten(AForm f) {
  list[AQuestion] qs = [];
  for (AQuestion q <- f.questions) {
	qs += flatten(boolean(true), q);
  }
  return form(f.name, qs, src=f.src); 
}

list[AQuestion] flatten(AExpr guard, AQuestion q) {
  switch (q) {
	case question(str lbl, str id, AType questionType):
	  return [ ifThen(guard, q) ];
	case computed(str lbl, str id, AType questionType, AExpr computedExpr):
	  return [ ifThen(guard, q) ];
	case block(list[AQuestion] questions):
	  return flattenBlock(boolean(true), block(questions));
	case ifThen(AExpr innerGuard, AQuestion question):
	  return flattenBlock(and(guard, innerGuard), question);
	case ifThenElse(AExpr innerGuard, AQuestion ifQuestion, AQuestion elseQuestion): {
	  list[AQuestion] qs = [];
	  qs += flattenBlock(and(guard, innerGuard), ifQuestion);
			
	  // The guard of else equals not(ifGuard)
	  qs += flattenBlock(and(guard, not(innerGuard)), elseQuestion);
	  return qs;
	}
	default: throw "Unsupported question <q>";
  }
}

// Calls flatten on all the questions in the block
list[AQuestion] flattenBlock(AExpr guard, AQuestion block) {
  list[AQuestion] flattenedQs = [];
  switch (block) {
	case block(list[AQuestion] qs): {
	  for (AQuestion q <- qs) {
	    flattenedQs += flatten(guard, q);
      }
	  return flattenedQs;
	}
	default: return flatten(guard, block);
  }
}


/* Rename refactoring:
 *
 * Write a refactoring transformation that consistently renames all occurrences of the same name.
 * Use the results of name resolution to find the equivalence class of a name.
 *
 */
 
set[loc] eqClass(Form f, loc occ, UseDef useDef) {
  set[loc] class = {};
	
  if (isEmpty(useDef[occ])) {
    // If occ is the defining occurence add use occurences
    class += { use | <loc use, occ> <- useDef };
		
    // Add defining Id location
    class += question2Id(f, occ);
  } else {
    // If occ is a use occurence, find the def occurence and add the other use occurences
	loc def = toList(useDef[occ])[0];
	class += { use | <loc use, def> <- useDef };
		
	// Add defining Id location
	class += question2Id(f, def);
  }

  return class;
}

bool isValidId(str name){
  try {
	parse(#Id, name);
	return true;
  } catch: return false;
}

loc question2Id(Form f, loc questionLoc) {
  for (/Question q := f, q@\loc == questionLoc) {
	for (/Id x := q) {
	  return x@\loc;
	}
  }
  return questionLoc;
}
 
Form rename(Form f, loc useOrDef, str newName, UseDef useDef) {
  // Generate set of locations of item to rename
  toRename = eqClass(f, useOrDef, useDef);
	
  // Check if new name is a valid identifier
  if (!isValidId(newName)) {
	return f;
  }

  // Check if name is not in use already
  Id newId = parse(#Id, newName);	
  for (/Id x := f) {
    if (x == newId) {
	  throw "Name already exists!";
	}
  }
	
  // Traverse form and rename id's in toRename to newName
  return visit(f) {
  	case Id x => newId
  	when x@\loc in toRename
  }
	
  return f;
}
