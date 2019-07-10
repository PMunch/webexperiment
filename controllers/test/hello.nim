import "../../createlib", strutils, os
from jester import Request

const
  view = getView(currentSourcePath())
var name: string

proc init* {.exportc, dynlib.} =
  name = "Peter Parker"

proc createPage*(request: Request): string {.exportc, dynlib.} =
  tmpls(view)
