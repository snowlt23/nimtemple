
import private.node
import private.parser

import json
export json
import strutils

type
  TempleRenderer* = object
    obj: JsonNode

proc newTempleRenderer*(): TempleRenderer =
  result.obj = newJObject()

proc `[]`*(tmpl: TempleRenderer, key: string): JsonNode =
  tmpl.obj[key]
proc `[]=`*(tmpl: TempleRenderer, key: string, val: JsonNode) =
  tmpl.obj[key] = val

proc getVal*(tmpl: TempleRenderer, key: TempleNode): JsonNode =
  if key.kind == templeStr:
    return tmpl[$key]
  elif key.kind == templeValue:
    var val = tmpl[key.names[0]]
    for k in key.names[1..^1]:
      val = val[k]
    return val
  else:
    raise newException(TempleError, "couldn't find variable: $#" % $key)

proc eval*(tmpl: TempleRenderer, node: TempleNode): string =
  case node.kind
  of templeStr:
    $node
  of templeStmt:
    var s = ""
    for elem in node.sons:
      s &= tmpl.eval(elem)
    s
  of templeValue:
    tmpl.getVal(node).str
  of templeEmbed:
    tmpl.getVal(node.embedvalue).str
  of templeInclude:
    readFile($node.filename)
  of templeFor:
    var s = ""
    for elem in tmpl.getVal(node.itervalue):
      tmpl[$node.elemname] = elem
      s &= tmpl.eval(node.content)
    s
  of templeIf:
    if tmpl.getVal(node.cond).bval:
      tmpl.eval(node.tcontent)
    else:
      ""
  of templeIfElse:
    if tmpl.getVal(node.cond).bval:
      tmpl.eval(node.tcontent)
    else:
      tmpl.eval(node.fcontent)
  else:
    ""

proc renderSrc*(tmpl: TempleRenderer, filename: string, src: string): string =
  result = ""
  for node in parseTemple(filename, src).sons:
    result &= tmpl.eval(node)
proc renderFile*(tmpl: TempleRenderer, filename: string): string =
  result = ""
  for node in parseTemple(filename, readFile(filename)).sons:
    result &= tmpl.eval(node)

