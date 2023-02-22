# Export as PSD

## About This Script

 This script enables export of photoshop file format (.psd) to aseprite.

## Installation

 1. Open your script folder.
      (File -> Scripts -> Open Scripts Folder)
  2. Place "Export as psd.lua"

## Usage

 1. Run script
      (File -> Scripts -> Export as PSD)
 2. Edit the filename to export if needed.
 3. Specify the frame number to export.
 4. Click `Export` button.

## Download

- [Pre-release](https://github.com/Tsukina-7mochi/aseprite-scripts/blob/dev/psd/Export%20as%20psd.lua)
- [Latest](https://raw.githubusercontent.com/Tsukina-7mochi/aseprite-scripts/master/psd/Export%20as%20psd.lua)

## Update Log

-1.3.0
  - Implement animated psd export
- 1.2.1
  - Enriched User Interface.
- 1.2.0
  - Fixed problem that some applications cannot open psd file exported by this script
  - Unsupported shift-JIS
- 1.1.2
  - Fixed an issue with compression
- 1.1.1
  - Fixed an issue with compression
- 1.1.0
  - Support compression
- 1.0.2 2020/4/15
  - Support Shift-JIS Character
- 1.0.1 2020/1/31
  - Fix issues on exporting empty layer
- 1.0.0 2020/1/31
  - First Release

## Reference

Aseprite API (https://github.com/aseprite/api)
Adobe Photoshop File Formats Specification (https://www.adobe.com/devnet-apps/photoshop/fileformatashtml/)
Lua 5.1 リファレンスマニュアル (http://milkpot.sakura.ne.jp/lua/lua51_manual_ja.html)
Anatomy of a PSD File (https://github.com/layervault/psd.rb/wiki/Anatomy-of-a-PSD-File)
Lua で数値の型チェック（整数なのか浮動小数点なのかを判定する方法） (https://qiita.com/iigura/items/4db51859fc49130d5f0c)
PSD Tool (https://oov.github.io/psdtool/)

## Acknowledgments

[燻丸](https://twitter.com/ibushi_maru) gave me support a lot in sharing this script. Great thanks to him.

## Others

- This script is provided with [MIT License](https://github.com/Tsukina-7mochi/aseprite-scripts/blob/master/LICENSE)
