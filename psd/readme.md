## About This Script
 This script exports aseprite files as photoshop file format (.psd)

## Installation
 1. Open your script folder.
   (File -> Scripts -> Open Scripts Folder)
 2. Drop "Export as PSD.lua"
 ~~## ver 1.0.2 requairs export_as_psd_lib directory too.~~
 the latest version of script does not require other than .lua flie for now.

## Usage
 1. Run script
   (File -> Scripts -> Export as PSD)
 2. Edit the filename to export if needed
 3. Specify the frame number to export
 4. Click OK
 5. If you see the message says "PSD file saved as * * *.psd", the process succeeded.
 6. Edit your psd file in other application (recommended[^1])

[^1]: Why do I recommended to edit my psd file?  
~~This script exports as PSD file without expression, the file may be big or huge.~~  
Compression is supported now.  
You can change scale if you need, in this step, too.

## In Use
You can edit the source code as you like, and distribute it.  
You cannot redestribute files with no change without my permission.

## Download
[Latest](https://github.com/Tsukina-7mochi/aseprite-scripts/blob/master/psd/Export%20as%20psd%201.2.lua)

## Update Log
- 1.2.0
  - Fixed problem that some applications cannot open psd file exported by this script
  - Unsupport shift-JIS
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

## Contact
Twitter: @Tsukina_7mochi  

## Reference
Aseprite API (https://github.com/aseprite/api)  
Adobe Photoshop File Formats Specification (https://www.adobe.com/devnet-apps/photoshop/fileformatashtml/)  
Lua 5.1 リファレンスマニュアル (http://milkpot.sakura.ne.jp/lua/lua51_manual_ja.html)  
Anatomy of a PSD File (https://github.com/layervault/psd.rb/wiki/Anatomy-of-a-PSD-File)  
Lua で数値の型チェック（整数なのか浮動小数点なのかを判定する方法） (https://qiita.com/iigura/items/4db51859fc49130d5f0c)  
PSD Tool (https://oov.github.io/psdtool/)

## Acknowledgments
FlashAir library to convert from UTF-8 to Shift _ JIS(https://github.com/AoiSaya/FlashAir_UTF8toSJIS)  
 To support Japanese character, I used this library.  
燻丸 (@ibushi_maru)  
 He gave me support a lot in sharing this script. Great thanks to him.  

## LICENSE
[MIT](https://github.com/Tsukina-7mochi/aseprite-scripts/blob/master/LICENSE)
