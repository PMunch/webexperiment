import jester
import jester/patterns
import os, osproc
import times
import dynlib
import tables
import streams

proc dlerror(): cstring {.header: "<dlfcn.h>".}

type
  CreatePageProcedure = proc(request: Request): string {.stdcall.}
  InitControllerProcedure = proc(): string {.stdcall.}
  Controller = object
    handle: LibHandle
    init: InitControllerProcedure
    createPage: CreatePageProcedure
    compileError: string
    built: Time
    pattern: Pattern

var loadedControllers: Table[string, Controller]

proc rebuildLibrary(file, name, cache, view: string): bool =
  if not fileExists(cache) or
    fileNewer(file, cache) or
    fileNewer(view, cache):
    echo "Compiling controller ", name, ":"
    let (outp, ecode) = when defined(release):
      execCmdEx("nim c -d:release --app:lib -o:" & cache & " " & file)
    else:
      execCmdEx("nim c --app:lib -o:" & cache & " " & file)
    echo outp
    if ecode != 0:
      loadedControllers[name].compileError = outp
    else:
      reset loadedControllers[name].compileError
    return true

proc rebuildLibrary(file: string): bool =
  let
    splitpath = file.relativePath("controllers").splitFile()
    name = "/" & (if splitpath.dir.len > 0: splitpath.dir & "/" & splitpath.name else: splitpath.name)
    cache = "cache" / splitpath.dir / "lib" & splitpath.name & ".so"
    view = "views" / splitpath.dir / splitpath.name & ".html"
  rebuildLibrary(file, name, cache, view)

proc loadLibrary(file: string) =
  let
    splitpath = file.relativePath("controllers").splitFile()
    name = "/" & (if splitpath.dir.len > 0: splitpath.dir & "/" & splitpath.name else: splitpath.name)
    cache = "cache" / splitpath.dir / "lib" & splitpath.name & ".so"
    view = "views" / splitpath.dir / splitpath.name & ".html"
  loadedControllers[name] = Controller()
  discard rebuildLibrary(file, name, cache, view)
  loadedControllers[name].built = getLastModificationTime(cache)
  loadedControllers[name].handle = loadLib(cache)
  if loadedControllers[name].handle == nil:
    echo "Error loading library"
    echo dlerror()
    quit(QuitFailure)

  loadedControllers[name].init = cast[InitControllerProcedure](loadedControllers[name].handle.symAddr("init"))
  if loadedControllers[name].init != nil:
    let pattern = loadedControllers[name].init()
    if pattern.len > 0:
      loadedControllers[name].pattern = parsePattern(pattern)
      let first = loadedControllers[name].pattern[0]
      if first.typ == NodeText and first.optional == false and first.text != name & "/" and first.text != name:
        echo "WARNING: A route shouldn't have a different name from it's controller"
        echo "Route " & pattern & " points to controller " & name

  loadedControllers[name].createPage = cast[CreatePageProcedure](loadedControllers[name].handle.symAddr("createPage"))
  if loadedControllers[name].createPage == nil:
    echo "Error loading 'createPage' function from library"
    quit(QuitFailure)

for file in walkFiles("controllers/*.nim"):
  loadLibrary(file)

for file in walkFiles("controllers/**/*.nim"):
  loadLibrary(file)

proc autorouter*(request: Request): ResponseData {.gcsafe.} =
  if loadedControllers.hasKey(request.path) and loadedControllers[request.path].pattern.len == 0:
    if rebuildLibrary("controllers" & request.path & ".nim"):
      loadedControllers[request.path].handle.unloadLib()
      loadLibrary("controllers" & request.path & ".nim")
    result.matched = true
    try:
      if loadedControllers[request.path].compileError.len != 0:
        result.content = loadedControllers[request.path].compileError
        result.code = Http500
      else:
        result.content = loadedControllers[request.path].createPage(request)
        result.code = Http200
    except:
      result.code = Http500
      result.content = getCurrentExceptionMsg()
  else:
    for controllerPath, controller in loadedControllers:
      if controller.pattern.len == 0: continue
      if rebuildLibrary("controllers" & controllerPath & ".nim"):
        loadedControllers[controllerPath].handle.unloadLib()
        loadLibrary("controllers" & controllerPath & ".nim")
      let match = controller.pattern.match(request.path)
      if match.matched:
        var modifiedRequest = request
        modifiedRequest.setPatternParams(match.params)
        result.content = controller.createPage(modifiedRequest)
        result.code = Http200
        result.matched = true
        return
    if not loadedControllers.hasKey(request.path):
      if fileExists("controllers" & request.path & ".nim") and
        fileExists("views" & request.path & ".html"):
        loadLibrary("controllers" & request.path & ".nim")
        result.matched = true
        if loadedControllers[request.path].compileError.len != 0:
          result.content = loadedControllers[request.path].compileError
          result.code = Http500
        else:
          result.content = loadedControllers[request.path].createPage(request)
          result.code = Http200

proc main() =
  let settings = newSettings(port=5000.Port)
  var server = initJester(autorouter, settings=settings)
  #when defined(release):
  #  let pattern = parsePattern("/show/@id/?")
  #  echo pattern.match("/show/100")
  server.serve()

when isMainModule:
  main()
