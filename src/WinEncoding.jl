module WinEncoding
#     const cp950=include("cp950.jl")
    const cp1252b=include("cp1252b.jl")
#     const cp936=include("cp936.jl")
#     const cp932=include("cp932.jl")
#     const cp932b=include("cp932b.jl")
#     const _x80=[0xc2,0x80]             # '\u80'
#     const _x80_936=[0xe2,0x82,0xac]     # '\u20ac' '€'
#     const _xff=[0xef, 0xa3, 0xb8]      # '\uf8f8'
#     const _xff_936=[0xef, 0xa3, 0xb5]      # '\uf8f5'
    const _invalid=[0xef, 0xbf, 0xbd]  # '�'
    export decode1252, decode950, encode1252

    """
        decode950(a::Vector{UInt8})
    Convert an array of bytes `a` representing text in encoding `cp950/big5/hkscs` to a string.
    - fallback to big5-hkscs or '\ufffd';no invalid sequence error
    - non-blocking

        decode950(f::Filename)
    Convert file `f` content to Vector{UInt8} from cp950 to utf-8 Vector{UInt8}
    ## Examples
    ```jldoctest
    julia> decode950([0xa4,0x48])
    "人"
    ```
    """
    const decode950(a::Vector{UInt8})=Cp950.decode(a)
    function decode950(f::String,type=Vector{UInt8})
        @assert isfile(f) "$f must be a valid file name"
        bom=read(f,3)
        if bom == [0xef,0xbb,0xbf] 
            @info "Detect utf-8 bom(byte order mark) ; just read"
            read(f)
        elseif length(bom) >= 2 && bom[1:2]==[0xff,0xfe]
            @info "Detect UTF-16LE bom ; using built-in transcode"
            transcode(UInt8,reinterpret(read(f),UInt16))
        else
            Cp950.decode(read(f),type)
        end
    end
    const decode936(a)=Cp936.decode(a)
    const decode932(a)=Cp932.decode(a)

    module Cp950
        import .._invalid
        const cp950=include("cp950.jl")
        const _x80=[0xc2,0x80]             # '\u80'
        const _xff=[0xef, 0xa3, 0xb8]      # '\uf8f8'

        function decode(ss::Vector{UInt8},type::Type=String) 
            blength=length(ss)
            o=Array{UInt8}(undef,blength*2+1)
            b=1
            skip1=false
            @inbounds for (i,c) in enumerate(ss)
                skip1==true && (skip1=false;continue)
                c<0x80 && (o[b]=c; b+=1;continue)
                c==0x80 && (copyto!(o,b,_x80,1,2); b+=2;continue)
                c==0xff && (copyto!(o,b,_xff,1,3); b+=3;continue)
                i % 1_000_000 == 1 && yield()
                skip1=true
                hh=c-0x80
                ll=((i1=i+1) <= blength ) ? ss[i1] : 0x00
                cc=(ll < 0x40 || ll==0xff || 0x7e<ll<0xa1) ? _invalid : (ll-=0x3f;ll > 0x3f && (ll-=0x22);cp950[hh][ll])
                ccl=length(cc)
                unsafe_copyto!(o,b,cc,1,ccl)
                b+=ccl
            end
            type===String ? String(@view(o[1:b-1])) : o[1:b-1]
        end
    end

    module Cp936
        import .._invalid
        const cp936=include("cp936.jl")
        const _x80=[0xe2,0x82,0xac]     # '\u20ac' '€'
        const _xff=[0xef, 0xa3, 0xb5]      # '\uf8f5'


        """
            decode936(a::Vector{UInt8})
        Convert an array of bytes `a` representing text in encoding ***cp936/gbk*** to a string.
        - fallback to '\ufffd';no invalid sequence error
        - non-blocking
        """
        function decode(ss::Vector{UInt8}) 
            blength=length(ss)
            o=Array{UInt8}(undef,blength*2+1)
            b=1
            skip1=false
            @inbounds for (i,c) in enumerate(ss)
                skip1==true && (skip1=false;continue)
                c<0x80 && (o[b]=c; b+=1;continue)
                c==0x80 && (copyto!(o,b,_x80,1,3); b+=3;continue)
                c==0xff && (copyto!(o,b,_xff,1,3); b+=3;continue)
                i % 1024*1024 == 0 && yield()
                skip1=true
                hh=c-0x80
                ll=((i1=i+1) <= blength) ? ss[i1] : 0x00
                cc=(ll < 0x40 || ll==0xff) ? _invalid : cp936[hh][ll-0x3f]
                ccl=length(cc)
                unsafe_copyto!(o,b,cc,1,ccl)
                b+=ccl
            end
            @view(o[1:b-1]) |> String
        end
    end #cp936

    module Cp932
        const _invalid=[0xe3, 0x83, 0xbb] #'・'
        const cp932=include("cp932.jl")
        const cp932b=include("cp932b.jl")
        """
            decode932(a::Vector{UInt8})
        Convert an array of bytes `a` representing text in encoding ***cp932/sjis*** to a string.
        - fallback to '・';no invalid sequence error
        - non-blocking
        """
        function decode(ss::Vector{UInt8}) 
            blength=length(ss)
            o=Array{UInt8}(undef,blength*2+1)
            b=1
            skip1=false
            @inbounds for (i, c) in enumerate(ss)
                skip1==true && (skip1=false;continue)
                c<0x80 && (o[b]=c; b+=1;continue)
                if (c == 0x80 || 0xa0 <= c <0xe0 || c > 0xef) 
                    let cc=cp932b[c-0x7f]; ccl=length(cc)
                        copyto!(o,b,cc,1,ccl); b+=ccl;continue
                    end
                end
                i % 1024*1024 == 0 && yield()
                skip1=true
                hh=c-0x80
                hh > 0x1f && (hh-=0x40)
                ll=((i1=i+1) <= blength) ? ss[i1] : 0x00
                cc=(ll < 0x40 || ll > 0xfc) ? _invalid : cp932[hh][ll-0x3f]
                ccl=length(cc)
                unsafe_copyto!(o,b,cc,1,ccl)
                b+=ccl
            end
            @view(o[1:b-1]) |> String
        end
    end #cp932

    #internal use
    function _7bit(ss)
        for c in ss
            c < 0x80 || return false
        end
        true     
    end
    #internal use
    function _7bit2(ss)
        for (i,c) in enumerate(ss)
            c < 0x80 || return (false,i-one(i))
        end
        true,length(ss)
    end
    """
        decode1252(a::Vector{UInt8})
    Convert an array of bytes `a` representing text in encoding `cp1252/windows-1252` to a string.
    - [0x8d] => '\\u8d' as Windows API does
    - no invalid sequence error
    - non-blocking
    ## Examples
    ```jldoctest
    julia> decode1252([0x80])
    "€"
    
    julia> decode1252([0xa9])
    "©"

    ```
    """
    function decode1252(ss::Vector{UInt8},type::Type=String) 
        o=Array{UInt8}(undef,length(ss)*3)
        is7bit,len = _7bit2(ss)
#         o[1:len]=ss[1:len]
#         unsafe_copyto!(o,1,ss,1,len)
        copyto!(o,1,ss,1,len)
        b=len+1
        @inbounds for c in @view(ss[b:end])
            if c<0x80
                o[b]=c
                b+=1
            else
                b % 1024*1024 == 0 && yield()
                cc=cp1252b[c+1]
                ccl=length(cc)
                unsafe_copyto!(o,b,cc,1,ccl)
                b+=ccl
            end
        end
        type===String ? String(@view(o[1:b-1])) : o[1:b-1]
    end
    function decode1252(f::String,type=Vector{UInt8})
        @assert isfile(f) "Input must be a valid file name"
        decode1252(read(f),type)
    end
    function encode1252(ss::String) 
        tbl=Dict('Ú' => 0xda, '\uad' => 0xad, '¢' => 0xa2, 'Í' => 0xcd, 'ç' => 0xe7, 'ÿ' => 0xff, '®' => 0xae, 'ã' => 0xe3, '«' => 0xab, '¼' => 0xbc, 'å' => 0xe5, 'æ' => 0xe6, '€' => 0x80, '†' => 0x86, 'ä' => 0xe4, 'À' => 0xc0, 'ž' => 0x9e, 'é' => 0xe9, 'ò' => 0xf2, '°' => 0xb0, 'Š' => 0x8a, '¥' => 0xa5, '£' => 0xa3, '¦' => 0xa6, 'Á' => 0xc1, '“' => 0x93, 'Þ' => 0xde, '¿' => 0xbf, 'Å' => 0xc5, '\u8d' => 0x8d, 'Ã' => 0xc3, '¨' => 0xa8, 'œ' => 0x9c, '§' => 0xa7, 'á' => 0xe1, '\u81' => 0x81, '´' => 0xb4, 'Ô' => 0xd4, 'Ý' => 0xdd, 'à' => 0xe0, 'Ò' => 0xd2, 'ß' => 0xdf, 'ê' => 0xea, '²' => 0xb2, 'ù' => 0xf9, 'û' => 0xfb, 'þ' => 0xfe, '„' => 0x84, '©' => 0xa9, '‰' => 0x89, 'ð' => 0xf0, 'Ö' => 0xd6, '¬' => 0xac, '‡' => 0x87, 'ü' => 0xfc, '‘' => 0x91, 'ª' => 0xaa, 'ý' => 0xfd, '\u9d' => 0x9d, 'Õ' => 0xd5, 'Ž' => 0x8e, 'Ø' => 0xd8, 'Ù' => 0xd9, '¡' => 0xa1, '¸' => 0xb8, '›' => 0x9b, 'Ê' => 0xca, '×' => 0xd7, 'è' => 0xe8, '¹' => 0xb9, '…' => 0x85, '\ua0' => 0xa0, 'ˆ' => 0x88, '–' => 0x96, 'Ì' => 0xcc, 'ñ' => 0xf1, '÷' => 0xf7, '¾' => 0xbe, 'õ' => 0xf5, '½' => 0xbd, 'Û' => 0xdb, 'ô' => 0xf4, 'ó' => 0xf3, '»' => 0xbb, 'ö' => 0xf6, 'Ï' => 0xcf, '±' => 0xb1, 'Œ' => 0x8c, 'Â' => 0xc2, 'ƒ' => 0x83, 'Î' => 0xce, 'Ü' => 0xdc, '¤' => 0xa4, 'Ä' => 0xc4, '˜' => 0x98, 'µ' => 0xb5, 'Ð' => 0xd0, '³' => 0xb3, 'Ñ' => 0xd1, 'Ÿ' => 0x9f, '’' => 0x92, 'š' => 0x9a, 'ì' => 0xec, '—' => 0x97, 'ë' => 0xeb, 'î' => 0xee, '¶' => 0xb6, 'ø' => 0xf8, 'Ó' => 0xd3, 'Æ' => 0xc6, 'ú' => 0xfa, 'Ç' => 0xc7, '·' => 0xb7, '\u8f' => 0x8f, '™' => 0x99, 'ï' => 0xef, 'í' => 0xed, 'â' => 0xe2, 'È' => 0xc8, 'É' => 0xc9, '‚' => 0x82, '‹' => 0x8b, 'Ë' => 0xcb, 'º' => 0xba, '”' => 0x94, '¯' => 0xaf, '\u90' => 0x90, '•' => 0x95)
        chars=collect(ss)
        o=Array{UInt8}(undef,ncodeunits(ss))
        b=1
        for c in chars
            cc= codepoint(c)
            o[b]= cc < 0x00000080 ? UInt8(cc) : get(tbl,c,0x3f)
            b+=1
        end
        o[1:b-1]
    end #encode1252
end # module
