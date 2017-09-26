
import nimtemple

var tmpl = newTempleRenderer()
tmpl["persons"] = %* ["Yuduki Yukari", "Tsurumaki Maki", "Kotonoha Akane", "Kotonoha Aoi"]
echo tmpl.renderFile("./template_for.html")
