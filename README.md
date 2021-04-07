# WinEncoding
>Decoding windows-1252 bytes to UTF-8 string<br>
>No binary dependency


    decode1252(a::Vector{UInt8})
Converts an array of bytes `a` representing text in encoding ***cp1252/windows-1252*** to a string.
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

## Examples

```julia
julia> decode950([0xa4,0x48])
"人"
```

---

# Q&A
## Why decode with this package instead of a lib_iconv-based package?
iconv is popular and ususally pre-installed on Linux systems. However, it has several drawbacks:
- older versions produce inconsistent results, you have to install the latest iconv yourself.
Or simply remove it because iconv-based package will install one if not found.
- it is slow in some circumstances,
- it will crash the program while decoding, if an exception was not captured by the program,
- it blocks the coroutine and this is bad in some applications such as for a web service,
- it is not 100% compatible with Windows API result. For example, in cp1252/windows-1252 [0x8d] throws error while it is supposed to be 'u8d'. Many web pages in latin-1 charset are actually encoded with codepage 1252 instead of latin-1. And for unknown charset, it should fallback to codepage 1252 as well.

## What does decode950 do?
Cp950 is popular and ususally the default charset of traditional Han character in East Asia/Taiwan. However, the iconv support is limited. Cp950 and hkscs were superset of big5 but hkscs was not compatible with cp950.
- older versions of iconv cannot decode big5-hkscs. And several web pages in the big5 charset were actually encoded with big5-hkscs,
- many web pages in the big5 charset are actually encoded with cp950,
- is possible that a web page in the big5 charset was actually mixed cp950 and hkscs. But hkscs is not compatible with cp950. For example, the euro sign, €, was in cp950 but not in hkscs; therefore, it will trigger exception if mixed cp950/hkscs encoding in iconv based method
- at this time point (April 2021), no package can decode mixed cp950/hkscs.

### decode950 will try to decode cp950, if invalid, will fallback to hkscs if available, or fallback to '\ufffd' if both are invalid.
