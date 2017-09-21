
import node

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

proc parseValue*(ctx: var ParserContext): TempleNode =
  ctx.next(1)
  var names = newSeq[string]()
  var curstr = ""
  var span = ctx.getSpan()
  while true:
    ctx.skipGarbage()
    if ctx.getchar == '.':
      names.add(curstr)
      curstr = ""
    elif ctx.get(2) == "}}":
      ctx.next(2)
      break
    else:
      curstr &= ctx.getchar
    ctx.next()
  names.add(curstr)
  return TempleNode(span: span, kind: templeValue, names: names)

proc parseExpr*(ctx: var ParserContext): TempleNode =
  if ctx.get(1) == "$":
    return ctx.parseValue()
  else:
    raise newException(TempleError, "unknown expression")

proc parseStmt*(ctx: var ParserContext): seq[TempleNode] =
  result = @[]
  var curstr = ""
  var curspan = ctx.getSpan()
  while not ctx.iseof:
    if ctx.get(2) == "{{":
      result.add(TempleNode(span: curspan, kind: templeStr, strval: curstr))
      ctx.next(2)
      ctx.skipGarbage()
      result.add(ctx.parseExpr())
      curstr = ""
      curspan = ctx.getSpan()
    else:
      curstr &= ctx.get(1)
      ctx.next(1)
  result.add(TempleNode(span: curspan, kind: templeStr, strval: curstr))

proc parseTemple*(filename: string, src: string): seq[TempleNode] =
  var ctx = newParserContext(filename, src)
  return ctx.parseStmt()
