import Markdown.Document;
import markdown.AST.Node;
import markdown.TextFieldRenderer;

class TextFieldMarkdown {
	public static function markdownToHtml(markdown:String):String {
		// create document
		var document = new Document();

		try {
			// no beginning or end new lines
			markdown = ~/(^\n+|\n+$)/g.replace(markdown, "");

			// replace windows line endings with unix
			markdown = ~/(\r\n|\r)/g.replace(markdown, '\n');

			var lines = markdown.split("\n");

			// parse ref links
			document.parseRefLinks(lines);

			// parse ast
			var blocks = document.parseLines(lines);
			return renderHtml(blocks);
		} catch (e:Dynamic) {
			return '<p><font face="_typewriter>$e</font></p>';
		}
	}

	public static function renderHtml(blocks:Array<Node>):String {
		return new TextFieldRenderer().render(blocks);
	}
}
