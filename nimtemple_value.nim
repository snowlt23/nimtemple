
import nimtemple

var tmpl = newTemplateRenderer()
tmpl["person"] = %* "Yuduki Yukari"
echo tmpl.renderFile("./template_value.html")
