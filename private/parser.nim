
import node

import macros
import strutils

const LF* = '\x0A'

type
  ParserContext* = object
    src*: string
    pos*: int
    filename*: string
    line*: int
    linepos*: int

proc newParserContext*(filename: string, src: string): ParserContext =
  result.src = src
  result.pos = 0
  result.filename = filename
  result.line = 1
  result.linepos = 1

proc iseof*(ctx: var ParserContext): bool =
  ctx.pos >= ctx.src.len
proc getchar*(ctx: var ParserContext): char =
  ctx.src[ctx.pos]
proc get*(ctx: var ParserContext, len: int): string =
  ctx.src[ctx.pos..<ctx.pos+len]
proc next*(ctx: var ParserContext) =
  if ctx.getchar() == LF:
    ctx.line += 1
    ctx.linepos = 1
  ctx.pos.inc
proc next*(ctx: var ParserContext, len: int) =
  for i in 0..<len:
    ctx.next()
proc skipGarbage*(ctx: var ParserContext) =
  while true:
    if ctx.get(1) == " " or ctx.getchar() in NewLines:
      ctx.next(1)
    else:
      break
proc getSpan*(ctx: var ParserContext): Span =
  result.filename = ctx.filename
  result.line = ctx.line
  result.linepos = ctx.linepos

#
# parse
#

macro parseseq*(ctx: typed, body: untyped): untyped =
  result = newStmtList()
  for b in body:
    if b.kind == nnkStrLit:
      result.add quote do:
        if `ctx`.get(`b`.len) != `b`:
          parseError(`ctx`.getSpan, "unmatching " & `b`)
        `ctx`.next(`b`.len)
    else:
      result.add(b)
    result.add quote do:
      `ctx`.skipGarbage()

proc parseError*(span: Span, msg: string) =
  raise newException(TempleParseError, "$#($#:$#): $#" % [span.filename, $span.line, $span.linepos, msg])

proc parseExpr*(ctx: var ParserContext): TempleNode
proc parseStmt*(ctx: var ParserContext): TempleNode

proc parseIdent*(ctx: var ParserContext): string =
  result = ""
  while true:
    if ctx.getchar in {' ', '}', LF}:
      break
    else:
      result.add(ctx.getchar)
      ctx.next()

proc checkEndBrackets*(ctx: var ParserContext) =
  ctx.skipGarbage()
  if ctx.get(2) != "}}":
    parseError(ctx.getSpan, "unmatching brackets")
  ctx.next(2)

proc parseValue*(ctx: var ParserContext): TempleNode =
  if ctx.getchar != '$':
    parseError(ctx.getSpan, "not variable: requires `$`")
  ctx.next(1)
  var names = newSeq[string]()
  var curstr = ""
  var span = ctx.getSpan()
  while true:
    ctx.skipGarbage()
    if ctx.getchar == '.':
      names.add(curstr)
      curstr = ""
    elif ctx.getchar in {' ', '}'}:
      break
    else:
      curstr &= ctx.getchar
    ctx.next()
  names.add(curstr)
  return TempleNode(span: span, kind: templeValue, names: names)

proc parseFor*(ctx: var ParserContext): TempleNode =
  let span = ctx.getSpan
  ctx.parseseq:
    "for"
    let ident = ctx.parseIdent()
    "in"
    let value = ctx.parseValue()
    ctx.checkEndBrackets()
    let body = ctx.parseStmt()
  return TempleNode(span: span, kind: templeFor, elemname: ident, itervalue: value, content: body)

proc parseIf*(ctx: var ParserContext): TempleNode =
  let span = ctx.getSpan
  ctx.parseseq:
    "if"
    let cond = ctx.parseValue()
    ctx.checkEndBrackets()
    let tcontent = ctx.parseStmt()
  var fcontent = TempleNode(span: span, kind: templeStr, strval: "")
  if ctx.get(4) == "else":
    ctx.parseseq:
      "else"
      ctx.checkEndBrackets()
      fcontent = ctx.parseStmt()
  return TempleNode(span: span, kind: templeIf, cond: cond, tcontent: tcontent, fcontent: fcontent)

proc parseExpr*(ctx: var ParserContext): TempleNode =
  if ctx.get(1) == "$":
    result = ctx.parseValue()
    ctx.checkEndBrackets()
  elif ctx.get(3) == "for":
    return ctx.parseFor()
  elif ctx.get(2) == "if":
    return ctx.parseIf()
  else:
    parseError(ctx.getSpan, "unknown expression")

proc parseStmt*(ctx: var ParserContext): TempleNode =
  var body = newSeq[TempleNode]()
  var curstr = ""
  var curspan = ctx.getSpan()
  while not ctx.iseof:
    if ctx.get(2) == "{{":
      ctx.next(2)
      ctx.skipGarbage()
      if ctx.get(3) == "end":
        ctx.next(3)
        ctx.checkEndBrackets()
        break
      elif ctx.get(4) == "else":
        break
      body.add(TempleNode(span: curspan, kind: templeStr, strval: curstr))
      body.add(ctx.parseExpr())
      curstr = ""
      curspan = ctx.getSpan()
    else:
      curstr &= ctx.get(1)
      ctx.next(1)
  body.add(TempleNode(span: curspan, kind: templeStr, strval: curstr))
  return TempleNode(span: body[0].span, kind: templeStmt, sons: body)

proc parseTemple*(filename: string, src: string): TempleNode =
  var ctx = newParserContext(filename, src)
  return ctx.parseStmt()
