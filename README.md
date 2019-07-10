webexperiment
=============

Little experiment with some web stuff. It automatically compiles the controllers
and views into .so files which it then calls to reply to requests. It also
detects if these files have changed and recompiles them. This means that both
the controllers and the views can be edited while the server is running and the
changes will be immediately visible.

To try it run:
`nim c -r test`

Stuff that should be added:
- Compiling the controllers/views with `-d:release` when `test` was compiled
with it.
- Don't show nim compiler output in release build
- Support routing and argument passing
