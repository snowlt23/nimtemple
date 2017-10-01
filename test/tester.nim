
import unittest
import nimtemple

suite "nimtemple":
  var tmpl = initTempleRenderer()
  tmpl["heroine"] = %* "Yuduki Yukari"
  tmpl["persons"] = %* ["Yukari", "Maki", "Akane", "Aoi"]

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

