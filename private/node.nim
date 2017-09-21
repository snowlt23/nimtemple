
import sequtils, strutils

type
  TempleError* = object of Exception
  Span* = object
    filename*: string
    line*: int
    linepos*: int
  TempleNodeKind* = enum
    templeStr
    templeValue
    templeStmt
    templeEmbed
    templeExtends
    templeInclude
    templeContent
    templeFor
    templeIf
    templeIfElse
  TempleNode* = ref object
    span*: Span
    case kind*: TempleNodeKind
    of templeStr:
      strval*: string
    of templeValue:
      names*: seq[string]
    of templeStmt:
      sons*: seq[TempleNode]
    of templeEmbed:
      embedvalue*: TempleNode
    of templeExtends, templeInclude:
      filename*: TempleNode
    of templeContent:
      discard
    of templeFor:
      elemname*: TempleNode
      itervalue*: TempleNode
      content*: TempleNode
    of templeIf, templeIfElse:
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
  of templeEmbed:
    "(kind: templeEmbed, embedvalue: $#)" % $node.embedvalue
  of templeExtends:
    "(kind: templeExtends, filename: $#)" % node.filename.strval
  of templeInclude:
    "(kind: templeInclude, include: $#)" % node.filename.strval
  of templeContent:
    "(kind: templeContent)"
  of templeFor:
    "(kind: templeFor, elemname: $#, itervalue: $#, content: $#)" % [$node.elemname, $node.itervalue, $node.content]
  of templeIf:
    "(kind: templeIf, cond: $#, tcontent: $#)" % [$node.cond, $node.tcontent]
  of templeIfElse:
    "(kind: templeIf, cond: $#, tcontent: $#, fcontent: $#)" % [$node.cond, $node.tcontent, $node.fcontent]
  else:
    ""