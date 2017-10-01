
import private.node
import private.parser

import json
export json
import strutils
import tables
import options
import os

type
  TempleRenderer* = object
    basepath*: string
    obj: JsonNode
    defines: Table[string, string]
    parentnodes: Option[TempleNode]

proc newTempleRenderer*(): TempleRenderer =
  result.obj = newJObject()
  result.defines = initTable[string, string]()

proc `[]`*(tmpl: TempleRenderer, key: string): JsonNode =
  tmpl.obj[key]
proc `[]=`*(tmpl: TempleRenderer, key: string, val: JsonNode) =
  tmpl.obj[key] = val

proc getVal*(tmpl: TempleRenderer, key: TempleNode): JsonNode =
  if key.kind == templeStrLit:
    return tmpl[key.strval]
  elif key.kind == templeValue:
    var val = tmpl[key.names[0]]
    for k in key.names[1..^1]:
      val = val[k]
    return val
  else:
    raise newException(TempleError, "couldn't find variable: $#" % key.debug)

proc eval*(tmpl: var TempleRenderer, node: TempleNode): string =
  case node.kind
  of templeStrLit:
    "\"" & node.strval & "\""
  of templeStmt:
    var s = ""
    for elem in node.sons:
      s &= tmpl.eval(elem)
    s
  of templeValue:
    tmpl.getVal(node).str
  of templeExtends:
    tmpl.parentnodes = some parseTemple(tmpl.basepath / node.filename.strval, readFile(tmpl.basepath / node.filename.strval))
    ""
  of templeDefine:
    if tmpl.defines.hasKey(node.definename):
      tmpl.defines[node.definename]
    else:
      tmpl.defines[node.definename] = tmpl.eval(node.definecontent)
      ""
  of templeInclude:
    readFile(node.filename.strval)
  of templeContent:
    node.content
  of templeStrip:
    tmpl.eval(node.stripnode).strip()
  of templeFor:
    var s = ""
    for elem in tmpl.getVal(node.itervalue):
      tmpl[$node.elemname] = elem
      s &= tmpl.eval(node.forcontent)
    s
  of templeIf:
    if tmpl.getVal(node.cond).bval:
      tmpl.eval(node.tcontent)
    else:
      tmpl.eval(node.fcontent)

proc renderSrc*(tmpl: var TempleRenderer, filename: string, src: string): string =
  tmpl.basepath = filename.splitPath().head
  let node = parseTemple(filename, src)
  result = tmpl.eval(node)
  if tmpl.parentnodes.isSome:
    result = tmpl.eval(tmpl.parentnodes.get)
proc renderFile*(tmpl: var TempleRenderer, filename: string): string =
  tmpl.renderSrc(filename, readFile(filename))

