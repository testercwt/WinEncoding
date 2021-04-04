using Test
using WinEncoding

let 
    @testset "codepage 1252" begin
        # 3 times size in extreme scenerio
        @test codeunits(decode1252([0x80,0x80,0x80]))==[0xe2, 0x82, 0xac, 0xe2, 0x82, 0xac, 0xe2, 0x82, 0xac]
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
    @testset "codepage 932" begin
        @test WinEncoding.decode932([0x80])=="\u80"
        @test WinEncoding.decode932([0xff])=="\uf8f3"
        @test WinEncoding.decode932([0xa0])=="\uf8f0"
        @test WinEncoding.decode932([0x82,0xa0])=="あ"
        @test WinEncoding.decode932([0x89,0xbe])=="伽"
    end
end