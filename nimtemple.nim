
import pegs
import json
export json

let includePattern* = peg"""
"{{" \s* "include" \s+ "\"" {@} "\"" \s* "}}"
"""
let contentPattern* = peg"""
"{{" \s* "content" \s* "}}"
"""
let extendsPattern* = peg"""
"{{" \s* "extends" \s+ "\"" {@} "\"" \s* "}}"
"""
let statementPattern* = peg"""
statement <- for / if
for <- "{{" \s* {"for"} \s+ {\ident} \s+ "in" \s+ val \s* "}}" {(!statement / (!end .))*} end
if <- "{{" \s* {"if"} \s+ val \s* "}}" {(!statement / (!end !else .))*} else? end
else <- "{{" \s* {"else"} \s* "}}" {(!statement / (!end .))*}
val <- {\ident} ("." {\ident})*
end <- ("{{" \s* "end" \s* "}}")
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
proc getVal*(tmpl: TemplateRenderer, keys: openArray[string]): JsonNode =
  var val = tmpl[keys[0]]
  for key in @keys[1..^1]:
    val = val[key]
  return val
proc render*(tmpl: TemplateRenderer, src: string): string =
  result = src
  var extendsmatches = newSeq[string](1)
  if result.find(extendsPattern, extendsmatches) != -1:
    # extends
    result = readFile(extendsmatches[0]).replace(contentPattern, result.replace(extendsPattern, ""))
  result = result.replace(includePattern) do (m, n: int, c: openArray[string]) -> string:
    # include
    let filename = c[0]
    result = tmpl.render(readFile(filename))
  result = result.replace(statementPattern) do (m, n: int, c: openArray[string]) -> string:
    # for
    result = ""
    echo @c
    case c[0]
    of "for":
      let
        elemname = c[1]
        itername = @c[2..n-2]
        content = c[n-1]
      for elem in tmpl.getVal(itername):
        var curtmpl = tmpl
        curtmpl[elemname] = elem
        result &= curtmpl.render(content)
    of "if":
      if c[n-2] == "else":
        let
          value = tmpl.getVal(@c[1..n-4])
          tcontent = c[n-3]
          fcontent = c[n-1]
        if value.bval:
          result &= tmpl.render(tcontent)
        else:
          result &= tmpl.render(fcontent)
      else:
        let
          value = tmpl.getVal(@c[1..n-3])
          tcontent = c[n-2]
        if value.bval:
          result &= tmpl.render(tcontent)
    else:
      discard
  result = result.replace(valPattern) do (m, n: int, c: openArray[string]) -> string:
    # val
    tmpl.getVal(@c[0..<n]).str
