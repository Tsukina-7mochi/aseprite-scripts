# Aseprite Scripts

This is a implementation of scripts and extensions of Aseprite, a pixel-art editor.

## Structure

For historical reason, this repository contains multiple projects as monorepo.
All source code is placed in `src` directory, not those of each project.
Scripts in project directory is build artifact, you MUST NOT refer or edit this at all.

- build.lua: Build script.
- check-manifest.lua: Validates manifests of scripts.
- icon-and-cursor: Exporter script for ICO, CUR and ANI files.
- lcd-pixel-filter: LCD-like visual filter script.
- lib: Libraries. DO NOT edit files in this repository.
  - aseprite/definitions: The type definition of the Aseprite API.
- mise.toml: Tool versions, environment variables and task scripts.
- psd: Exporter script for PSD, photoshop data format.
- readme.md
- smooth-filter: Smoothing visual filter script.
- src: Source codes
- targets.lua: List of scripts to build and release.

## Coding Rules

- Rood directory of scripts in `src` directory is `src`. Use absolute reference like `src.foo.bar`
- Scripts specific to apps are stored in `src/app/{appName}` directory.
- Reusable modules are stored in `src/pkg` directory.

## Versioning

- Each script has its own version in `package.manifest.version` of `src/entry/*.lua`, formatted as `yyyy.mm.dd`.
- Bump the version of a script to the date of the change when you update it.
- Build artifacts are committed; run `mise run build` and commit them.

## Prerequirements

- mise (installs Lua 5.4 and Stylua via `mise install`)

## Tools

- `mise install`: install Lua and Stylua
- `mise run prepare`: download necessary libraries
- `mise run build`: build scripts
- `mise run test`: run tests
- `mise run check:manifest`: validate manifests of scripts
- `mise run fmt`: run formatter (`mise run fmt:check` to check only)

## Documentation

You should read documentation in this repository:
Aseprite API documentation (remote): https://github.com/aseprite/api.
API Type definition (local file): `lib/aseprite/definitions` directory.
