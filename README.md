# WinEncoding
>Decoding windows-1252 bytes to UTF-8 string<br>
>No binary dependency


    decode1252(a::Vector{UInt8})
Convert an array of bytes `a` representing text in encoding ***cp1252/windows-1252*** to a string.
- [0x8d] => '\\u8d' as Windows API does
- no invalid sequence error
- non-blocking
## Examples
```julia
julia> decode1252([0x80])
"€"

julia> decode1252([0xa9])
"©"
```
---

    decode950(a::Vector{UInt8})
Convert an array of bytes `a` representing text in encoding ***cp950/big5/hkscs*** to a string.
- fallback to big5-hkscs or '\ufffd';no invalid sequence error
- non-blocking

