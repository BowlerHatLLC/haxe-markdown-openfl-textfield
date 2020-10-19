package markdown;

import markdown.AST.TextNode;
import markdown.AST.Node;
import markdown.AST.ElementNode;
import markdown.AST.NodeVisitor;

class TextFieldRenderer implements NodeVisitor {
	static var BLOCK_TAGS = new EReg('blockquote|h1|h2|h3|h4|h5|h6|hr|p|pre', '');

	var buffer:StringBuf;

	public function new() {}

	public function render(nodes:Array<Node>):String {
		buffer = new StringBuf();
		for (node in nodes)
			node.accept(this);
		return buffer.toString();
	}

	public function visitText(text:TextNode):Void {
		buffer.add(text.text);
	}

	public function visitElementBefore(element:ElementNode):Bool {
		// Hackish. Separate block-level elements with newlines.
		if (buffer.toString() != "" && BLOCK_TAGS.match(element.tag)) {
			buffer.add('\n');
		}

		switch (element.tag) {
			case "h1":
				buffer.add('<p');
			case "h2":
				buffer.add('<p');
			case "h3":
				buffer.add('<p');
			case "h4":
				buffer.add('<p');
			case "h5":
				buffer.add('<p');
			case "h6":
				buffer.add('<p');
			case "pre":
				buffer.add('<p');
			case "code":
				buffer.add('<font face="_typewriter"');
			case "strong":
				buffer.add('<b');
			case "em":
				buffer.add('<i');
			case "blockquote":
				buffer.add('<textformat blockindent="20"');
			case "hr":
				buffer.add('<p>---</p>');
				return true;
			default:
				buffer.add('<${element.tag}');
		}

		// Sort the keys so that we generate stable output.
		// TODO(rnystrom): This assumes keys returns a fresh mutable
		// collection.
		var attributeNames = [for (k in element.attributes.keys()) k];
		attributeNames.sort(sortAttributes);
		for (name in attributeNames) {
			buffer.add(' $name="${element.attributes.get(name)}"');
		}

		if (element.isEmpty()) {
			// Empty element like <hr/>.
			buffer.add(' />');
			return false;
		} else {
			buffer.add('>');

			switch (element.tag) {
				case "h1":
					buffer.add('<font size=\"+2\">');
				case "h2":
					buffer.add('<font size=\"+2\">');
				case "pre":
					buffer.add('<font face=\"_typewriter\">');
			}
			return true;
		}
	}

	public function visitElementAfter(element:ElementNode):Void {
		switch (element.tag) {
			case "h1":
				buffer.add('</font></p>');
			case "h2":
				buffer.add('</font></p>');
			case "h3":
				buffer.add('</p>');
			case "h4":
				buffer.add('</p>');
			case "h5":
				buffer.add('</p>');
			case "h6":
				buffer.add('</p>');
			case "pre":
				buffer.add('</font></p>');
			case "code":
				buffer.add('</font>');
			case "strong":
				buffer.add('</b>');
			case "em":
				buffer.add('</i>');
			case "blockquote":
				buffer.add("</textformat>");
			case "hr":
				return;
			default:
				buffer.add('</${element.tag}>');
		}
	}

	static var attributeOrder = ['src', 'alt'];

	static function sortAttributes(a:String, b:String) {
		var ia = attributeOrder.indexOf(a);
		var ib = attributeOrder.indexOf(a);
		if (ia > -1 && ib > -1)
			return ia - ib;
		return Reflect.compare(a, b);
	}
}
