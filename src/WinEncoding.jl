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
    export decode1252, decode950
    
    const decode950(a::Vector{UInt8})=Cp950.decode(a)
    const decode950(f::String)= (@assert isfile(f) "Input must be a valid file name"; Cp950.decode(read(f)))
    const decode936(a)=Cp936.decode(a)
    const decode932(a)=Cp932.decode(a)

    module Cp950
        import .._invalid
        const cp950=include("cp950.jl")
        const _x80=[0xc2,0x80]             # '\u80'
        const _xff=[0xef, 0xa3, 0xb8]      # '\uf8f8'
        """
            decode950(a::Vector{UInt8})
        Convert an array of bytes `a` representing text in encoding cp950/big5 to a string.
        - fallback to big5-hkscs or '\ufffd';no invalid sequence error
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
            @view(o[1:b-1]) |> String
        end
    end

    module Cp936
        import .._invalid
        const cp936=include("cp936.jl")
        const _x80=[0xe2,0x82,0xac]     # '\u20ac' '€'
        const _xff=[0xef, 0xa3, 0xb5]      # '\uf8f5'


        """
            decode936(a::Vector{UInt8})
        Convert an array of bytes `a` representing text in encoding cp936/gbk to a string.
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
        Convert an array of bytes `a` representing text in encoding cp932/sjis to a string.
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
    Convert an array of bytes `a` representing text in encoding **cp1252/windows-1252** to a string.
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
    function decode1252(ss::Vector{UInt8}) 
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
        view(o,1:b-1) |> String
    end
end # module
