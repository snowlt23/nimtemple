
import unittest
import nimtemple
import future

suite "nimtemple":
  var tmpl = initTempleRenderer()
  tmpl["vr"] = %* true
  tmpl["heroine"] = %* "Yuduki Yukari"
  tmpl["persons"] = %* ["Yukari", "Maki", "Akane", "Aoi"]
  tmpl.addProc("isTrue") do (node: JsonNode) -> JsonNode:
    if node[0].bval:
      %* "TRUE!"
    else:
      %* "FALSE!"
  tmpl.addProc("default") do (node: JsonNode) -> JsonNode:
    if node[0].kind == JNull:
      node[1]
    else:
      node[0]

  test "value":
    check tmpl.renderSrc("test", "{{ $heroine }}") == "Yuduki Yukari"
  test "for":
    check tmpl.renderSrc("test", """
    {{ for person in $persons }}
    <li>{{$person}}</li>
    {{ end }}""") == """
    <li>Yukari</li>
    <li>Maki</li>
    <li>Akane</li>
    <li>Aoi</li>
    """
  test "if":
    let src = """
{{ if $islittle }}
Kotonoha Aoi
{{ else }}
Kotonoha Akane
{{ end }}"""
    tmpl["islittle"] = %* true
    check tmpl.renderSrc("test", src) == "Kotonoha Aoi\n"
    tmpl["islittle"] = %* false
    check tmpl.renderSrc("test", src) == "Kotonoha Akane\n"
  test "extends":
    var tmpl = initTempleRenderer()
    check tmpl.renderFile("test/extends.html") == """

<title>ZUNDA</title>

"""
  test "call":
    check tmpl.renderSrc("test", """
    {{ isTrue($vr) }}
    """) == """
    TRUE!
    """
  test "call str":
    let src = """
    {{ default($wtf, "DEFAULT!") }}
    """
    check tmpl.renderSrc("test", src) == """
    DEFAULT!
    """
    tmpl["wtf"] = %* true
    check tmpl.renderSrc("test", src) == """
    true
    """

