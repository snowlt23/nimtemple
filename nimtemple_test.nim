
import nimtemple

var tmpl = newTemplateRenderer()
tmpl["language"] = %* "ja"
tmpl["persons"] = %* [
  {"name": "yukari"},
  {"name": "maki"},
  {"name": "akane"},
  {"name": "aoi"},
]
tmpl["isHello"] = %* true
echo tmpl.render(readFile("./template_example.html"))
