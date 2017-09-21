
import glossolalia
import json
export json
import sequtils, strutils

type
  TempleError* = object of Exception
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
    case kind*: TempleNodeKind
    of templeStr:
      strval*: string
    of templeValue:
      dotvals*: seq[string]
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
    node.dotvals.join(".")
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

proc saveToTempleStmt*[N](rule: Rule[N]): Rule[N] =
  rule.save do (matches: seq[TempleNode]) -> TempleNode:
    TempleNode(kind: templeStmt, sons: matches)

grammar(TempleNode):
  ident := (chr(IdentStartChars) and *chr(IdentChars)).save do (match: string) -> TempleNode:
    TempleNode(kind: templeStr, strval: match)
  filename := (str("\"") and *(absent(str("\"")) and chr(AllChars)) and str("\"")).save do (match: string) -> TempleNode:
    TempleNode(kind: templeStr, strval: match.replace("\""))
  ig := *str(" ")
  ws := +str(" ")

  extendsPattern := (str("{{") and ig and str("extends") and ws and filename and ig and str("}}")).save do (matches: seq[TempleNode]) -> TempleNode:
    TempleNode(kind: templeExtends, filename: matches[0])
  includePattern := (str("{{") and ig and str("include") and ws and filename and ig and str("}}")).save do (matches: seq[TempleNode]) -> TempleNode:
    TempleNode(kind: templeInclude, filename: matches[0])
  contentPattern := (str("{{") and ig and str("content") and ig and str("}}")).save do (matches: seq[TempleNode]) -> TempleNode:
    TempleNode(kind: templeContent)

  valuePattern := (ident and *(str(".") and ident)).save do (matches: seq[TempleNode]) -> TempleNode:
    TempleNode(kind: templeValue, dotvals: matches.mapIt($it))
  embedPattern := (str("${") and ig and valuePattern and ig and str("}")).save do (match: seq[TempleNode]) -> TempleNode:
    TempleNode(kind: templeEmbed, embedvalue: match[0])

  statementPattern := embedPattern or includePattern or forPattern or ifElsePattern or ifPattern

  forBodyPattern := (+(absent(statementPattern or endPattern) and chr(AllChars))).save do (match: string) -> TempleNode:
    TempleNode(kind: templeStr, strval: match)
  forPattern := (str("{{") and ig and str("for") and ws and ident and ws and str("in") and ws and valuePattern and
    ig and str("}}") and saveToTempleStmt(*(statementPattern or forBodyPattern)) and endPattern).save do (matches: seq[TempleNode]) -> TempleNode:
      TempleNode(kind: templeFor, elemname: matches[0], itervalue: matches[1], content: matches[2])

  # if
  ifBodyPattern := (+(absent(statementPattern or elsePattern or endPattern) and chr(AllChars))).save do (match: string) -> TempleNode:
    TempleNode(kind: templeStr, strval: match)
  ifHeadPattern := (str("{{") and ig and str("if") and ws and valuePattern and ig and str("}}"))
  ifPattern := (ifHeadPattern and saveToTempleStmt(*(statementPattern or ifBodyPattern)) and endPattern).save do (matches: seq[TempleNode]) -> TempleNode:
    TempleNode(kind: templeIf, sons: matches)
  ifElsePattern := (ifHeadPattern and saveToTempleStmt(*(statementPattern or ifBodyPattern)) and elsePattern and saveToTempleStmt(*(statementPattern or ifBodyPattern)) and endPattern).save do (matches: seq[TempleNode]) -> TempleNode:
    TempleNode(kind: templeIfElse, cond: matches[0], tcontent: matches[1], fcontent: matches[2])
  elsePattern := str("{{") and ig and str("else") and ig and str("}}")

  endPattern := str("{{") and ig and str("end") and ig and str("}}")

  otherPattern := (+(absent(statementPattern) and chr(AllChars))).save do (match: string) -> TempleNode:
    TempleNode(kind: templeStr, strval: match)
  topPattern := *(statementPattern or otherPattern)

type
  TemplateRenderer* = object
    obj: JsonNode

proc newTemplateRenderer*(): TemplateRenderer =
  result.obj = newJObject()
proc `[]`*(tmpl: TemplateRenderer, key: string): JsonNode =
  tmpl.obj[key]
proc `[]=`*(tmpl: TemplateRenderer, key: string, val: JsonNode) =
  tmpl.obj[key] = val
proc getVal*(tmpl: TemplateRenderer, key: TempleNode): JsonNode =
  if key.kind == templeStr:
    return tmpl[$key]
  elif key.kind == templeValue:
    var val = tmpl[key.dotvals[0]]
    for k in key.dotvals[1..^1]:
      val = val[k]
    return val
  else:
    raise newException(TempleError, "could not use key by " & $key)
proc eval*(tmpl: TemplateRenderer, node: TempleNode): string =
  case node.kind
  of templeStr:
    $node
  of templeStmt:
    var s = ""
    for elem in node.sons:
      s &= tmpl.eval(elem)
    s
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
proc render*(tmpl: TemplateRenderer, src: string): string =
  echo topPattern.match(src).nodes
  result = ""
  for node in topPattern.match(src).nodes:
    result &= tmpl.eval(node)