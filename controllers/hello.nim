import "../createlib", strutils, os
from jester import Request

const
  view = getView(currentSourcePath())

proc createPage*(request: Request): string {.exportc, dynlib.} =
  let
    name = "Peter"
    x = (name: "Peter", age: 42)
  tmpls(view)
