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
  		     script(src(f.src[extension="js"].top))
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

HTML5Node question2html(AQuestion q, AType t) {
	switch (t) {
		case stringType():
			return div(class("form-group"),
				     label(\for(q.id), q.lbl),
				     input(\type("text"), name(q.id), class("form-control"), id(q.id))
				   );
		case integerType():
			return div(class("form-group"),
				     label(\for(q.id), q.lbl),
				     input(\type("number"), name(q.id), class("form-control"), id(q.id))
				   );
		case booleanType():
			return div(class("form-group form-check"),
				     label(class("form-check-label"), 
				       input(\type("checkbox"), name(q.id), class("form-check-input"), id(q.id)),
				       q.lbl
				     )
				   );
		default: throw "Unsupported type <t>";
	}
}

HTML5Node computed2html(AQuestion q, AType t) {
	switch (t) {
		case integerType():
			return div(class("form-group"),
				     label(\for(q.id), q.lbl),
				     // TODO: add js to evaluate and set value dynamically
				     input(\type("number"), name(q.id), class("form-control"), id(q.id), \value("22"), disabled(true))
				   );
		case booleanType():
			return div(class("form-group form-check"),
				     label(class("form-check-label"), 
				       // TODO: add js to evaluate and set value dynamically
				       input(\type("checkbox"), name(q.id), class("form-check-input"), id(q.id), \value("true"), disabled(true)),
				       q.lbl
				     )
				   );
		default: throw "Unsupported type <t>";
	}
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

str form2js(AForm f) {
  return "";
}

str question2js(AQuestion q) {

}

str expr2js(AExpr e) {

}
