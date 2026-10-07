# Aseprite Scripts

This is a implementation of scripts and extensions of Aseprite, a pixel-art editor.

## Structure

For historical reason, this repository contains multiple projects as monorepo.
Bundled scripts (icon-and-cursor, psd) are built from `src` directory; the scripts in their project directories are build artifacts, you MUST NOT refer or edit them at all.
Unbundled scripts (lcd-pixel-filter, smooth-filter) are placed directly in their project directories and edited there.

- build.lua: Build script.
- icon-and-cursor: Exporter script for ICO, CUR and ANI files (bundled).
- lcd-pixel-filter: LCD-like visual filter script (unbundled).
- lib: Libraries. DO NOT edit files in this repository.
  - aseprite/definitions: The type definition of the Aseprite API.
- mise.toml: Tool versions, environment variables and task scripts.
- psd: Exporter script for PSD, photoshop data format (bundled).
- readme.md
- smooth-filter: Smoothing visual filter script (unbundled).
- src: Source codes of bundled scripts

## Coding Rules

- Rood directory of scripts in `src` directory is `src`. Use absolute reference like `src.foo.bar`
- Scripts specific to apps are stored in `src/app/{appName}` directory. `src/app/{appName}/init.lua` is the bundle entry and holds `package.manifest`.
- Reusable modules are stored in `src/pkg` directory.

## Prerequirements

- mise (installs Lua 5.4 and Stylua via `mise install`)

## Tools

- `mise install`: install Lua and Stylua
- `mise run prepare`: download necessary libraries
- `mise run build`: build scripts
- `mise run test`: run tests
- `mise run fmt`: run formatter (`mise run fmt:check` to check only)

## Documentation

You should read documentation in this repository:
Aseprite API documentation (remote): https://github.com/aseprite/api.
API Type definition (local file): `lib/aseprite/definitions` directory.
