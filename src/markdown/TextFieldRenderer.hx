package markdown;

import markdown.AST.TextNode;
import markdown.AST.Node;
import markdown.AST.ElementNode;
import markdown.AST.NodeVisitor;

class TextFieldRenderer implements NodeVisitor {
	static var BLOCK_TAGS = new EReg('blockquote|h1|h2|h3|h4|h5|h6|hr|p|pre|li|ul|ol', '');
	static var SKIPPED_TAGS = new EReg('ul|ol', '');

	var buffer:StringBuf;

	public function new() {}

	public function render(nodes:Array<Node>):String {
		buffer = new StringBuf();
		for (node in nodes) {
			if (Std.isOfType(node, ElementNode)) {
				var elementNode = cast(node, ElementNode);
				node = new WrappedElementNode(elementNode.tag, elementNode.children, elementNode.attributes, null);
			}
			node.accept(this);
		}
		return buffer.toString();
	}

	public function visitText(text:TextNode):Void {
		buffer.add(text.text);
	}

	private function needsNewLine(wrappedElement:WrappedElementNode):Bool {
		if (!BLOCK_TAGS.match(wrappedElement.tag)) {
			return false;
		}
		if (wrappedElement.parent == null) {
			return buffer.toString() != "";
		}
		var index = wrappedElement.parent.children.indexOf(wrappedElement);
		if (index == 0 && SKIPPED_TAGS.match(wrappedElement.parent.tag)) {
			return needsNewLine(wrappedElement.parent);
		}
		return index != 0;
	}

	public function visitElementBefore(element:ElementNode):Bool {
		if (SKIPPED_TAGS.match(element.tag)) {
			return true;
		}

		var wrappedElement = cast(element, WrappedElementNode);

		// Hackish. Separate block-level elements with newlines.
		if (this.needsNewLine(wrappedElement)) {
			buffer.add('\n');
		}

		switch (element.tag) {
			case "h1":
				buffer.add('<p class="h1"');
			case "h2":
				buffer.add('<p class="h2"');
			case "h3":
				buffer.add('<p class="h3"');
			case "h4":
				buffer.add('<p class="h4"');
			case "h5":
				buffer.add('<p class="h5"');
			case "h6":
				buffer.add('<p class="h6"');
			case "pre":
				buffer.add('<p class="pre"');
			case "code":
				buffer.add('<span class="code"');
			case "strong":
				buffer.add('<b');
			case "em":
				buffer.add('<i');
			case "blockquote":
				buffer.add('<textformat class="blockquote" blockindent="20"');
			case "hr":
				buffer.add('<p class="hr">---</p>');
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
					buffer.add('<font size="+5">');
				case "h2":
					buffer.add('<font size="+4">');
				case "h3":
					buffer.add('<font size="+3">');
				case "h4":
					buffer.add('<font size="+2">');
				case "h5":
					buffer.add('<font size="+1">');
				case "pre":
					buffer.add('<font face="_typewriter">');
				case "code":
					buffer.add('<font face="_typewriter">');
				case "a":
					buffer.add('<u>');
			}

			#if (!flash && openfl < "9.2.0")
			// workaround for older, non-flash targets that do not render the list item bullet
			if (BLOCK_TAGS.match(element.tag) && wrappedElement.parent != null && wrappedElement.parent.tag == "li") {
				buffer.add('• ');
			}
			#end
			return true;
		}
	}

	public function visitElementAfter(element:ElementNode):Void {
		if (SKIPPED_TAGS.match(element.tag)) {
			return;
		}
		switch (element.tag) {
			case "h1":
				buffer.add('</font></p>');
			case "h2":
				buffer.add('</font></p>');
			case "h3":
				buffer.add('</font></p>');
			case "h4":
				buffer.add('</font></p>');
			case "h5":
				buffer.add('</font></p>');
			case "h6":
				buffer.add('</p>');
			case "pre":
				buffer.add('</font></p>');
			case "code":
				buffer.add('</font></span>');
			case "strong":
				buffer.add('</b>');
			case "em":
				buffer.add('</i>');
			case "blockquote":
				buffer.add("</textformat>");
			case "a":
				buffer.add("</u></a>");
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

class WrappedElementNode extends ElementNode {
	public function new(tag:String, children:Array<Node>, attributes:Map<String, String>, parent:WrappedElementNode) {
		if (children == null) {
			// accept() does not check for null children
			// so we need an empty array
			children = [];
		}
		for (i in 0...children.length) {
			var child = children[i];
			if (!Std.isOfType(child, ElementNode)) {
				continue;
			}
			var elementNodeChild = cast(child, ElementNode);
			var wrappedChild = new WrappedElementNode(elementNodeChild.tag, elementNodeChild.children, elementNodeChild.attributes, this);
			children[i] = wrappedChild;
		}
		super(tag, children);
		this.parent = parent;
		for (key in attributes.keys()) {
			this.attributes.set(key, attributes.get(key));
		}
	}

	public var parent:WrappedElementNode;
}
