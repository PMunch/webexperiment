import "../createlib", strutils, os
import jester

const
  view = getView(currentSourcePath())

proc init*: string {.exportc, dynlib.} =
  # This sets the route, so /home no longer points to this controller
  # This is meant to be used with the same prefix as the controller name..
  "/something/@id"

proc createPage*(request: Request): string {.exportc, dynlib.} =
  tmpls(view)
