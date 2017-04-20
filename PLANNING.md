# Planning

Teapot 2.0 will feature isolated build directories and private dependencies.

## Isolated Build Directories

Individual packages will be built into discrete directories:

```
teapot/#{platform}/libpng/include/png.h
teapot/#{platform}/libpng/lib/libpng.a
```

## Private Dependencies

All dependencies by default are public.

Given a package, C, that depends on B, and B publicly depends on A, C also depends on A.

The problem is that some dependencies of B should not also be dependencies of A, for example internal build tools, etc. It's not necessary for a consumer of A to be aware of C in all cases.
