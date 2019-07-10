import "../createlib", strutils, os
from jester import Request

const
  view = getView(currentSourcePath())

proc createPage*(request: Request): string {.exportc, dynlib.} =
  tmpls(view)
