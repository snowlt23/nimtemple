
import nimtemple

var tmpl = newTempleRenderer()
tmpl["person"] = %* "Yuduki Yukari"
echo tmpl.renderFile("./template_value.html")
