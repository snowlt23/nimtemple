
import nimtemple

var tmpl = newTemplateRenderer()
tmpl["language"] = %* "ja"
tmpl["persons"] = %* [
  {"name": "yukari"},
  {"name": "maki"},
  {"name": "akane"},
  {"name": "aoi"},
]
echo tmpl.render(readFile("./template_example.html"))
