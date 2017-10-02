
import private.node
import private.parser

import json
export json
import strutils, sequtils
import tables
import options
import os

type
  TempleRenderer* = object
    basepath*: string
    obj: JsonNode
    defines: Table[string, string]
    calls: Table[string, proc (jnode: JsonNode): JsonNode]
    parentnodes: Option[TempleNode]

proc initTempleRenderer*(): TempleRenderer =
  result.obj = newJObject()
  result.defines = initTable[string, string]()
  result.calls = initTable[string, proc (jnode: JsonNode): JsonNode]()

proc `[]`*(tmpl: TempleRenderer, key: string): JsonNode =
  tmpl.obj[key]
proc `[]=`*(tmpl: var TempleRenderer, key: string, val: JsonNode) =
  tmpl.obj[key] = val
proc hasKey*(tmpl: TempleRenderer, key: string): bool =
  tmpl.obj.hasKey(key)
proc del*(tmpl: var TempleRenderer, key: string) =
  tmpl.obj.delete(key)

proc addProc*(tmpl: var TempleRenderer, key: string, fn: proc (jnode: JsonNode): JsonNode) =
  tmpl.calls[key] = fn

proc evalNode*(tmpl: TempleRenderer, node: TempleNode): JsonNode

proc getVal*(tmpl: TempleRenderer, key: TempleNode): JsonNode =
  if key.kind == templeValue:
    if not tmpl.hasKey(key.names[0]):
      return %* nil
    var val = tmpl[key.names[0]]
    for k in key.names[1..^1]:
      if not val.hasKey(k):
        return %* nil
      val = val[k]
    return val
  else:
    return tmpl.evalNode(key)

proc evalNode*(tmpl: TempleRenderer, node: TempleNode): JsonNode =
  case node.kind
  of templeStrLit:
    return %* node.strval
  of templeIntLit:
    return %* node.intval
  of templeValue:
    return tmpl.getVal(node)
  of templeCall:
    let args = %* node.args.mapIt(tmpl.evalNode(it))
    return tmpl.calls[node.callname](args)
  else:
    raise newException(TempleError, "evalNode unsupported $#" % $node.kind)

proc eval*(tmpl: var TempleRenderer, node: TempleNode): string =
  case node.kind
  of templeStrLit:
    "\"" & node.strval & "\""
  of templeIntLit:
    $node.intval
  of templeStmt:
    var s = ""
    for elem in node.sons:
      s &= tmpl.eval(elem)
    s
  of templeValue:
    let val = tmpl.getVal(node)
    if val.kind == JString:
      val.str
    else:
      $val
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
  of templeCall:
    let val = tmpl.evalNode(node)
    if val.kind == JString:
      val.str
    else:
      $val

proc renderSrc*(tmpl: var TempleRenderer, filename: string, src: string): string =
  tmpl.basepath = filename.splitPath().head
  let node = parseTemple(filename, src)
  result = tmpl.eval(node)
  if tmpl.parentnodes.isSome:
    result = tmpl.eval(tmpl.parentnodes.get)
proc renderFile*(tmpl: var TempleRenderer, filename: string): string =
  tmpl.renderSrc(filename, readFile(filename))

