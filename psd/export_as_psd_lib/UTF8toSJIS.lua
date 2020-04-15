--[[
	UTF8toSJIS.lua - for FlashAir
	rev. 0.01
	Based on Mgo-tec/SD_UTF8toSJIS version 1.21

	This is a library for converting from UTF-8 code string to Shift_JIS code string.
	In advance, you need to upload a conversion table file Utf8Sjis.tbl to FlashAir.

The MIT License (MIT)

Copyright (c) 2019 AoiSaya
Copyright (c) 2016 Mgo-tec
Blog URL ---> https://www.mgo-tec.com

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
--]]

local UTF8toSJIS = {
	cnvtbl={
		[0xE2] = {0xE28090, 0x01EEC}; --文字"‐" UTF8コード E28090～、S_jisコード815D
		[0xE3] = {0xE38080, 0x09DCC}; --スペース UTF8コード E38080～、S_jisコード8140
		[0xE4] = {0xE4B880, 0x11CCC}; --文字"一" UTF8コード E4B880～、S_jisコード88EA
		[0xE5] = {0xE58085, 0x12BCC}; --文字"倅" UTF8コード E58085～、S_jisコード98E4
		[0xE6] = {0xE6808E, 0x1AAC2}; --文字"怎" UTF8コード E6808E～、S_jisコード9C83
		[0xE7] = {0xE78081, 0x229A6}; --文字"瀁" UTF8コード E78081～、S_jisコードE066
		[0xE8] = {0xE88080, 0x2A8A4}; --文字"耀" UTF8コード E88080～、S_jisコード9773
		[0xE9] = {0xE98080, 0x327A4}; --文字"退" UTF8コード E98080～、S_jisコード91DE
	};
}

--***********String型文字列をShift_JISコードに変換************************************
function UTF8toSJIS:UTF8_to_SJIS_str_cnv(f2, strUTF8) -- return strSJIS, sj_length
	local sj_cnt = 1
	local fnt_cnt = 1
	local sp_addres = 0x9DCC --スペース
	local SJ1, SJ2
	local sjis_byte = {}
	local str_length = strUTF8:len()

--	local UTF8SJIS_file = "Utf8Sjis.tbl"
--	local f2 = io.open(UTF8SJIS_file, "r")

	if f2==nil then
		return nil
	end

	while fnt_cnt<=str_length do
		local utf8_byte = strUTF8:byte(fnt_cnt)
		if utf8_byte>=0xC2 and utf8_byte<=0xD1 then --2バイト文字
			sp_addres = self:UTF8_To_SJIS_code_cnv(strUTF8:byte(fnt_cnt,fnt_cnt+1))
			SJ1, SJ2 = self:SD_Flash_UTF8SJIS_Table_Read(f2, sp_addres)
			sjis_byte[sj_cnt] 	= SJ1
			sjis_byte[sj_cnt+1] = SJ2
			sj_cnt	= sj_cnt  + 2
			fnt_cnt = fnt_cnt + 2
		elseif utf8_byte>=0xE2 and utf8_byte<=0xEF then
			sp_addres = self:UTF8_To_SJIS_code_cnv(strUTF8:byte(fnt_cnt,fnt_cnt+2))
			SJ1, SJ2 = self:SD_Flash_UTF8SJIS_Table_Read(f2, sp_addres)
			if SJ1>=0xA1 and SJ1<=0xDF then --Shift_JISで半角カナコードが返ってきた場合の対処
				sjis_byte[sj_cnt] 	= SJ1
				sj_cnt = sj_cnt + 1
			else
				sjis_byte[sj_cnt] 	= SJ1
				sjis_byte[sj_cnt+1] = SJ2
				sj_cnt = sj_cnt + 2
			end
			fnt_cnt = fnt_cnt + 3
		elseif utf8_byte>=0x20 and utf8_byte<=0x7E then
			sjis_byte[sj_cnt] = utf8_byte
			sj_cnt	= sj_cnt  + 1
			fnt_cnt = fnt_cnt + 1
		else --その他は全て半角スペースとする。
			sjis_byte[sj_cnt] = 0x20
			sj_cnt	= sj_cnt  + 1
			fnt_cnt = fnt_cnt + 1
		end
	end
	return string.char(table.unpack(sjis_byte)), sj_cnt-1
end

--***********UTF-8コードをSD内の変換テーブルを読み出してShift-JISコードに変換****
function UTF8toSJIS:UTF8_To_SJIS_code_cnv(utf8_1, utf8_2, utf8_3) --return: SD_addrs
	local SD_addrs = 0x9DCC --スペース
	if utf8_1>=0xC2 and utf8_1<=0xD1 then
		--0xB0からS_JISコード実データ。0x00-0xAFまではライセンス文ヘッダ。
		SD_addrs = ((utf8_1*256 + utf8_2)-0xC2A2)*2 + 0xB0 --文字"¢" UTF8コード C2A2～、S_jisコード8191
	elseif utf8_2>=0x80 then
		local UTF8uint = (utf8_1*65536) + (utf8_2*256) + utf8_3

		local tbl = self.cnvtbl[utf8_1]
		if tbl then
			SD_addrs = (UTF8uint-tbl[1])*2 + tbl[2]
		elseif utf8_1>=0xEF and utf8_2>=0xBC then
			SD_addrs = (UTF8uint-0xEFBC81)*2 + 0x3A6A4 --文字"！" UTF8コード EFBC81～、S_jisコード8149
			if utf8_1==0xEF and utf8_2==0xBD and utf8_3==0x9E then
				SD_addrs = 0x3A8DE -- "～" UTF8コード EFBD9E、S_jisコード8160
			end
		end
	end
	return SD_addrs
end

function UTF8toSJIS:SD_Flash_UTF8SJIS_Table_Read(ff, addrs) --return: sj1, sj2
	if ff then
		ff:seek("set", addrs)
		return (ff:read(2)):byte(1,2)
	else
		return " UTF8toSjis file has not been uploaded to the flash in SD file system"
	end
end

return UTF8toSJIS
