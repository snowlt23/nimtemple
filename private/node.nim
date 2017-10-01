
import sequtils, strutils

type
  TempleError* = object of Exception
  TempleParseError* = object of Exception
  Span* = object
    filename*: string
    line*: int
    linepos*: int
  TempleNodeKind* = enum
    templeStr
    templeValue
    templeStmt
    templeDefine
    templeExtends
    templeInclude
    templeContent
    templeFor
    templeIf
  TempleNode* = ref object
    span*: Span
    case kind*: TempleNodeKind
    of templeStr:
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
      discard
    of templeFor:
      elemname*: string
      itervalue*: TempleNode
      content*: TempleNode
    of templeIf:
      cond*: TempleNode
      tcontent*: TempleNode
      fcontent*: TempleNode

proc `$`*(node: TempleNode): string =
  case node.kind
  of templeStr:
    node.strval
  of templeValue:
    node.names.join(".")
  of templeStmt:
    "(kind: templeStmt, sons: $#)" % $node.sons
  of templeDefine:
    "(kind: templeDefine, definename: $#, definecontent: $#)" % [$node.definename, $node.definecontent]
  of templeExtends:
    "(kind: templeExtends, filename: $#)" % node.filename.strval
  of templeInclude:
    "(kind: templeInclude, include: $#)" % node.filename.strval
  of templeContent:
    "(kind: templeContent)"
  of templeFor:
    "(kind: templeFor, elemname: $#, itervalue: $#, content: $#)" % [$node.elemname, $node.itervalue, $node.content]
  of templeIf:
    "(kind: templeIf, cond: $#, tcontent: $#, fcontent: $#)" % [$node.cond, $node.tcontent, $node.fcontent]
