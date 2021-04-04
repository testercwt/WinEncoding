# WinEncoding
Decoding windows-1252 bytes to UTF-8 string


    decode1252(a::Vector{UInt8})
Convert an array of bytes a representing text in encoding cp1252 to a string.
[0x8d] => '\\u8d' as Windows API does;no invalid sequence error;non-blocking 


    decode950(a::Vector{UInt8})
Convert an array of bytes a representing text in encoding cp950 to a string.
fallback to big5-hkscs or '\ufffd';no invalid sequence error;non-blocking 

> No binary dependency
