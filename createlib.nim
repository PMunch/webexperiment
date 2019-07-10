include templates
import os

#const
#  fileName{.strdefine.}: string = ""
#  fileContent = staticRead(fileName)

macro tmpls*(body: static[string]): typed =
  result = newStmtList()
  result.add parseExpr("result = \"\"")
  parse_template(result, reindent(staticRead(body)))

template getView*(spath = currentSourcePath()): untyped =
  const splitFileName = spath.relativePath(absolutePath("controllers", currentSourcePath().splitfile.dir)).splitFile()
  currentSourcePath().splitfile.dir / "views" / splitFileName.dir / splitFileName.name & ".html"

#proc createPage*(name: string, x: tuple[name: string, age: int]): string {.exportc, dynlib.} =
#  tmpls(fileContent)
