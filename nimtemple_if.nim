
import nimtemple

var tmpl = newTempleRenderer()
tmpl["islittle"] = %* true
echo tmpl.renderFile("./template_if.html")
tmpl["islittle"] = %* false
echo tmpl.renderFile("./template_if.html")
