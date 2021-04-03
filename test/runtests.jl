using Test
using WinEncoding

let 
    @testset "codepage 1252" begin
        @test decode1252([0xf0])=="ð"
        @test decode1252([0x33,0x34,0x35])=="345"
        @test decode1252([0xa2,0xe7])=="¢ç"
    end
    @testset "codepage 950" begin
        @test WinEncoding.decode950([0xa4,0x48])=="人"
        @test WinEncoding.decode950([0xa4])=="�" #"\ufffd"
    end
    @testset "codepage 936" begin
        @test WinEncoding.decode936([0x81,0x40])=="丂"
        @test WinEncoding.decode936([0x80])=="€"
        @test WinEncoding.decode936([0xff])=="\uf8f5"
    end
end