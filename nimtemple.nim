
import pegs
import json
export json

let includePattern* = peg"""
"{{" \s* "include" \s+ "\"" {@} "\"" \s* "}}"
"""
let forPattern* = peg"""
"{{" \s* "for" \s+ {\ident} \s+ "in" \s+ {\ident} \s* "}}" {@} ("{{" \s* "end" \s* "}}")
"""
let valPattern* = peg"""
"${" \s* {\ident} ("." {\ident})*  \s* "}"
"""

type
  TemplateRenderer* = object
    obj: JsonNode

proc newTemplateRenderer*(): TemplateRenderer =
  result.obj = newJObject()
proc `[]`*(tmpl: TemplateRenderer, key: string): JsonNode =
  tmpl.obj[key]
proc `[]=`*(tmpl: TemplateRenderer, key: string, val: JsonNode) =
  tmpl.obj[key] = val
proc render*(tmpl: TemplateRenderer, src: string): string =
  result = src
  result = result.replace(includePattern) do (m, n: int, c: openArray[string]) -> string:
    let filename = c[0]
    result = tmpl.render(readFile(filename))
  result = result.replace(forPattern) do (m, n: int, c: openArray[string]) -> string:
    result = ""
    let
      elemname = c[0]
      itername = c[1]
      content = c[2]
    for elem in tmpl[itername]:
      result &= content.replace(valPattern) do (m, n: int, c: openArray[string]) -> string:
        var val = if elemname == c[0]:
                    elem
                  else:
                    tmpl[c[0]]
        for i in 1..<n:
          val = val[c[i]]
        return val.str
  result = result.replace(valPattern) do (m, n: int, c: openArray[string]) -> string:
    var val = tmpl[c[0]]
    for i in 1..<n:
      val = val[c[i]]
    return val.str
