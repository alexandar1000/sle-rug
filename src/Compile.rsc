module Compile

import AST;
import Resolve;
import IO;
import lang::html5::DOM; // see standard library

/*
 * Implement a compiler for QL to HTML and Javascript
 *
 * - assume the form is type- and name-correct
 * - separate the compiler in two parts form2html and form2js producing 2 files
 * - use string templates to generate Javascript
 * - use the HTML5Node type and the `str toString(HTML5Node x)` function to format to string
 * - use any client web framework (e.g. Vue, React, jQuery, whatever) you like for event handling
 * - map booleans to checkboxes, strings to textfields, ints to numeric text fields
 * - be sure to generate uneditable widgets for computed questions!
 * - if needed, use the name analysis to link uses to definitions
 */

void compile(AForm f) {
  writeFile(f.src[extension="js"].top, form2js(f));
  writeFile(f.src[extension="html"].top, toString(form2html(f)));
}

HTML5Node form2html(AForm f) {
  return html(
  		   head(
  		     title(f.name), 
  		     meta(name("viewport"), content("width=device-width, initial-scale=1")),
  		     link(\rel("stylesheet"), href("https://maxcdn.bootstrapcdn.com/bootstrap/4.1.3/css/bootstrap.min.css")),
  		     script(src("https://ajax.googleapis.com/ajax/libs/jquery/3.3.1/jquery.min.js")),
  		     script(src("https://cdnjs.cloudflare.com/ajax/libs/popper.js/1.14.3/umd/popper.min.js")),
  		     script(src("https://maxcdn.bootstrapcdn.com/bootstrap/4.1.3/js/bootstrap.min.js")),
  		     // Generated JavaScript file
  		     script(src(f.src[extension="js"].file))
  		   ),
  		   body(
  		     div(class("container mt-5"),
  		       h1(f.name),
  		       // Generate html for each question
  		       questions2html(form(), f.questions)
  		     )
  		   )
  		 );
}

HTML5Node questions2html(HTML5Node parent, list[AQuestion] questions) {
	for (AQuestion q <- questions) {
		parent.kids += [ question2html(q) ];
	}
	
	return parent;
}

HTML5Node question2html(AQuestion q) {
	switch (q) {
		case question(str lbl, str id, AType questionType):
			return question2html(q, questionType);
		case computed(str lbl, str id, AType questionType, AExpr computedExpr):
			return computed2html(q, questionType);
		case block(list[AQuestion] questions):
			return questions2html(div(), questions);
		case ifThen(AExpr guard, AQuestion question):
			return question2html(question);
		case ifThenElse(AExpr guard, AQuestion ifQuestion, AQuestion elseQuestion): {
			ifDiv = question2html(ifQuestion);
			elseDiv = question2html(elseQuestion);
			return div(ifDiv, elseDiv);
		}
		default: throw "Unsupported question <q>";
	}
}

HTML5Node question2html(AQuestion q, AType t) {
	switch (t) {
		case stringType():
			return div(class("form-group"), id(q.id),
				     label(\for("<q.id>_input"), q.lbl),
				     input(\type("text"), class("form-control"), id("<q.id>_input"))
				   );
		case integerType():
			return div(class("form-group"), id(q.id),
				     label(\for("<q.id>_input"), q.lbl),
				     input(\type("number"), class("form-control"), id("<q.id>_input"))
				   );
		case booleanType():
			return div(class("form-group form-check"), id(q.id),
				     label(class("form-check-label"), 
				       input(\type("checkbox"), class("form-check-input"), id("<q.id>_input")),
				       q.lbl
				     )
				   );
		default: throw "Unsupported type <t>";
	}
}

HTML5Node computed2html(AQuestion q, AType t) {
	switch (t) {
		case integerType():
			return div(class("form-group"), id(q.id),
				     label(\for("<q.id>_input"), q.lbl),
				     // TODO: add js to evaluate and set value dynamically
				     input(\type("number"), class("form-control"), id("<q.id>_input"), \value(0), disabled(true))
				   );
		case booleanType():
			return div(class("form-group form-check"), id(q.id),
				     label(class("form-check-label"), 
				       // TODO: add js to evaluate and set value dynamically
				       input(\type("checkbox"), class("form-check-input"), id("<q.id>_input"), disabled(true)),
				       q.lbl
				     )
				   );
		default: throw "Unsupported type <t>";
	}
}

str form2js(AForm f) {
    str jsResult = "function handleForm() {\n\n";
    for (/AQuestion q := f.questions, q has id) {
		jsResult += "$(\'#<q.id>\').hide();\n";
	}
	for (AQuestion q <- f.questions, q has id) {
		jsResult += "$(\'#<q.id>\').show();\n";
	}
	jsResult += "\n";
    for (AQuestion q <- f.questions) {
		jsResult += question2js(q);
	}
	jsResult += "\n}\n\n";
	jsResult += "$(function() {\n\t <jsMain(f)>})\n";
	return jsResult; 
}


str jsMain(AForm f) {
	str funct = "";
	for (/AQuestion q := f.questions, q has id) {
		funct += "$(\'#<q.id>\').hide();\n";
		if (!(q has computedExpr)) {
			if (booleanType() := q.questionType) {
				funct += "$(\'#<q.id>_input\').click(function() {\n\thandleForm();\n});\n";
			} else {
				funct += "$(\'#<q.id>_input\').on(\'input\', function() {\n\thandleForm();\n});\n";
			}
		}
	}
	for (AQuestion q <- f.questions, q has id) {
		funct += "$(\'#<q.id>\').show();\n";
	}
	
	return funct;
}



str question2js(AQuestion q) {
  switch (q) {
		case question(str lbl, str id, AType questionType): {
			if (booleanType() := questionType) {
				return "var <id> = $(\'#<id>_input\').is(\':checked\');\n";
			} else {
				return "var <id> = $(\'#<id>_input\').val();\n";
			}
		}
		case computed(str lbl, str id, AType questionType, AExpr computedExpr): {
			if (booleanType() := questionType) {
				return "$(\'#<id>_input\').prop(\'checked\', <expr2js(computedExpr)>)";
			} else {
				return "$(\'#<id>_input\').val(<expr2js(computedExpr)>)";
			}
		}
		case block(list[AQuestion] questions): {
			str jsResult = "{\n";
		    for (AQuestion q <- questions) {
		    	if (q has id) {
		    		jsResult += "$(\'#<q.id>\').show();\n";
		    	}
				jsResult += question2js(q) + "\n";
			} 
			return jsResult + "}";
		}
		case ifThen(AExpr guard, AQuestion question): {
			str jsResult = "";
			if (q has id) {
	    		jsResult += "$(\'#<question.id>\').hide();\n";
	    	}
			return jsResult + "if (<expr2js(guard)>) <question2js(question)>";
		}
		case ifThenElse(AExpr guard, AQuestion ifQuestion, AQuestion elseQuestion): {
			return "if (<expr2js(guard)>) <question2js(ifQuestion)> else <question2js(elseQuestion)>";
		}
		default: throw "Unsupported question <q>";
	}
	return "";
}


str expr2js(AExpr e) {
	switch (e) {
	//TODO
	case ref(str x): return x;
    case boolean(bool boolValue): return "<boolValue>";
    case integer(int intValue): return "<intValue>";
    case string(str stringValue): return "<stringValue>";
    case brackets(AExpr expr): return "(<expr2js(expr)>)";
    case not(AExpr expr): return "!(<expr2js(expr)>)";
    case mul(AExpr lhs, AExpr rhs): return "<expr2js(lhs)> * <expr2js(rhs)>";
    case div(AExpr lhs, AExpr rhs): return "<expr2js(lhs)> / <expr2js(rhs)>";
    case add(AExpr lhs, AExpr rhs): return "<expr2js(lhs)> + <expr2js(rhs)>";
    case sub(AExpr lhs, AExpr rhs): return "<expr2js(lhs)> - <expr2js(rhs)>";
    case gt(AExpr lhs, AExpr rhs): return "<expr2js(lhs)> \> <expr2js(rhs)>";
    case lt(AExpr lhs, AExpr rhs): return "<expr2js(lhs)> \< <expr2js(rhs)>";
    case geq(AExpr lhs, AExpr rhs): return "<expr2js(lhs)> \>= <expr2js(rhs)>";
    case leq(AExpr lhs, AExpr rhs): return "<expr2js(lhs)> \<= <expr2js(rhs)>";
    case equal(AExpr lhs, AExpr rhs): return "<expr2js(lhs)> == <expr2js(rhs)>"; // Let rascal's == operator handle type checking
    case neq(AExpr lhs, AExpr rhs): return "<expr2js(lhs)> != <expr2js(rhs)>"; // Let rascal's == operator handle type checking
    case and(AExpr lhs, AExpr rhs): return "<expr2js(lhs)> && <expr2js(rhs)>";
    case or(AExpr lhs, AExpr rhs): return "<expr2js(lhs)> || <expr2js(rhs)>";
    default: throw "Unsupported expression <e>";
  }
}
