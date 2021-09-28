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

## Examples

```julia
julia> decode950([0xa4,0x48])
"人"
```

---

# Q&A
## Why decoding with this package instead of lib_iconv based package?
iconv is popular and ususally pre-installed on linux systems.However , it has several drawbacks
- older version produce inconsistent result , you have to installed latest iconv by your-self .
Or simplily remove it because iconv based package will install one if not found
- it is slow in some circumstance
- it will crash the program while decoding if exception was not captured by the program
- it blocked the coroutine and this is bad in some application such as web service
- it is not 100% compatible with Windows API result. For example,in cp1252/windows-1252 [0x8d] throw error while it is supposed to be 'u8d'. Many web pages in latin-1 charset is actually encoded with codepage 1252 instead of latin-1. And in unknown charset , it should fallback to codepage 1252 as well.

## What does decode950  do?
Cp950 is popular and ususally the default charset of traditional Han character in east asia/taiwan. However , the iconv support is limited. Cp950 and hkscs were superset of big5 but hkscs was not compatible with cp950.
- older version iconv cannot decode big5-hkscs. And several web page in charset of big5 was actually encoded with big5-hkscs 
- many web page in charset of big5 was actually encoded with cp950
- It is possible that  web page in charset of big5 was actually mixed cp950 and hkscs . But hkscs is not compatible with cp950. For example, euro sign was in cp950 but not in hkscs; therefore , it will trigger exception if mixed cp950/hkscs encoding in iconv based method
- at this time point (2021/Apr) ,no package can decode mixed cp950/hkscs
### decode950 will try decode with cp950 ,if invalid, fallback to hkscs if available, fallback to '\ufffd' if both invalid