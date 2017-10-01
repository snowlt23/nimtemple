
import sequtils, strutils

type
  TempleError* = object of Exception
  TempleParseError* = object of Exception
  Span* = object
    filename*: string
    line*: int
    linepos*: int
  TempleNodeKind* = enum
    templeStrLit
    templeValue
    templeStmt
    templeDefine
    templeExtends
    templeInclude
    templeContent
    templeStrip
    templeFor
    templeIf
  TempleNode* = ref object
    span*: Span
    case kind*: TempleNodeKind
    of templeStrLit:
      strval*: string
    of templeValue:
      names*: seq[string]
    of templeStmt:
      sons*: seq[TempleNode]
    of templeDefine:
      definename*: string
      definecontent*: TempleNode
    of templeExtends, templeInclude:
      filename*: TempleNode
    of templeContent:
      content*: string
    of templeStrip:
      stripnode*: TempleNode
    of templeFor:
      elemname*: string
      itervalue*: TempleNode
      forcontent*: TempleNode
    of templeIf:
      cond*: TempleNode
      tcontent*: TempleNode
      fcontent*: TempleNode

proc debug*(node: TempleNode): string =
  case node.kind
  of templeStrLit:
    "(kind: templeStr, strval: $#)" % node.strval
  of templeValue:
    "(kind: templeValue, names: $#)" % node.names.join(".")
  of templeStmt:
    "(kind: templeStmt, sons: $#)" % node.sons.mapIt(it.debug)
  of templeDefine:
    "(kind: templeDefine, definename: $#, definecontent: $#)" % [node.definename, $node.definecontent.debug]
  of templeExtends:
    "(kind: templeExtends, filename: $#)" % node.filename.strval
  of templeInclude:
    "(kind: templeInclude, include: $#)" % node.filename.strval
  of templeContent:
    "(kind: templeContent, content: $#)" % node.content
  of templeStrip:
    "(kind: templeExtends, stripnode: $#)" % node.stripnode.debug
  of templeFor:
    "(kind: templeFor, elemname: $#, itervalue: $#, forcontent: $#)" % [$node.elemname, node.itervalue.debug, node.forcontent.debug]
  of templeIf:
    "(kind: templeIf, cond: $#, tcontent: $#, fcontent: $#)" % [node.cond.debug, node.tcontent.debug, node.fcontent.debug]
