# Juliaから外部プログラムを実行する <a href="https://github.com/ohno/RunningExternalPrograms/"><img src="https://img.shields.io/badge/-GitHub-181717.svg?logo=github&style=flat"></a> <a href="https://github.com/ohno/RunningExternalPrograms/blob/main/README.ipynb"><img alt="Jupyter Notebook" src="https://img.shields.io/badge/Jupyter%20Notebook-FA0F00.svg?style=flat&logo=jupyter&logoColor=white"/></a> <a href="https://zenn.dev/ohno/articles/a922710b53ea02"><img src="https://img.shields.io/badge/Zenn-3EA8FF.svg?logo=Zenn&style=flat&logoColor=white"></a>

© 2021 Shuhei Ohno
<br>License: https://opensource.org/licenses/MIT
<br>Repository: https://github.com/ohno/RunningExternalPrograms

[Calling C and Fortran Code](https://docs.julialang.org/en/v1/manual/calling-c-and-fortran-code/)によると, JuliaではCやFortranのルーチンを`ccall`で呼び出せます. しかし, 共有ライブラリとしてコンパイルしないとけないので, 標準入力と標準出力でデータをやり取りするメインプログラムを呼び出すことは難しいように思われます. **元のプログラムには手を加えない**で, Julaiからプログラムを呼び出せるようにすることがこのノートのテーマです. CやFortranに限らず, 外部プログラムを呼び出す方法は[Running External Programs](https://docs.julialang.org/en/v1/manual/running-external-programs/)に概ね書いてありますが, サンプルが少なく, Windows環境だといろいろ引っかかるポイントがあるので補足説明していきます. 環境は以下の通りです.

```julia
versioninfo()
```
    Julia Version 1.6.2
    Commit 1b93d53fc4 (2021-07-14 15:36 UTC)
    Platform Info:
      OS: Windows (x86_64-w64-mingw32)
      CPU: Intel(R) Core(TM) i7-4650U CPU @ 1.70GHz
      WORD_SIZE: 64
      LIBM: libopenlibm
      LLVM: libLLVM-11.0.1 (ORCJIT, haswell)
    

## Hello World!

さっそくですがHello World!していきましょう. 戻り値が不要な(標準出力で良い)場合は`run()`, 結果を受け取りたい場合は`read()`か`readchomp()`です. なお, コマンドを囲むのはバッククォートです. 

<strong>これはWindowsでは動きません</strong>

```julia
run(`echo hello`)
```

```julia
read(`echo hello`, String)
```

```julia
readchomp(`echo hello`)
```

<strong>Windowsでのechoはこっち！</strong>

```julia
run(`cmd /C echo hello`)
```
    hello

```julia
read(`cmd /C echo hello`, String)
```
    "hello\r\n"

```julia
readchomp(`cmd /C echo hello`)
```
    "hello"

型はそれぞれ以下のようになります. 出力に`hello`が挟まりますが気にしないでください.

```julia
println("1. ", typeof(`cmd /C echo hello`))
println("2. ", typeof(run(`cmd /C echo hello`)))
println("3. ", typeof(read(`cmd /C echo hello`, String)))
println("4. ", typeof(readchomp(`cmd /C echo hello`)))
```
    1. Cmd
    hello
    2. Base.Process
    3. String
    4. SubString{String}
    
メモ帳`notepad.exe`などのプログラムを呼び出すこともできます.

```julia
run(`notepad`)
```

```julia
run(`notepad.exe`)
```

```julia
run(`notepad.exe program1.f90`)
```

## 標準出力のみ

Hello World!と同じですが, 一応確認しましょう. 次の`program1.f90`は4という数値を標準出力に返すだけのプログラムです. コンパイルして生成された`program1.exe`を呼び出して標準出力の動作を確認していきます. (ファイルは[リポジトリ](https://github.com/ohno/RunningExternalPrograms)にあります. `gfortran`がインストールされてパスが通っていれば`compile.bat`をクリックすると勝手にコンパイルされます.)

`program1.f90`
```fortran
program main
  write(6,*) 4
end program main
```

```julia
run(`program1`);
```
               4

```julia
run(`program1.exe`);
```
               4

```julia
run(`cmd /C program1.exe`)
```
               4

```julia
read(`program1.exe`, String)
```
    "           4\r\n"

```julia
readchomp(`program1.exe`)
```
    "           4"

## 標準入力から変数を１つ渡す

次の`program2.f90`は標準入力をread文で読み取り, 数値を2乗して標準出力に返すプログラムです. コンパイルして生成された`program2.exe`を呼び出して動作を確認していきます. (ファイルは[リポジトリ](https://github.com/ohno/RunningExternalPrograms)にあります. `gfortran`がインストールされてパスが通っていれば`compile.bat`をクリックすると勝手にコンパイルされます.)

`program2.f90`
```fortran
program main
  implicit none
  integer x
  read(5,*) x
  write(6,*) x**2
end program main
```
`input2.txt`
```
5
```

まず, コマンドラインから`<`によって標準入力を渡せますが, `<`は`'<'`のようにシングルクォーテーションで囲います.


```julia
run(`cmd /C program2.exe '<' input2.txt`)
```
              25

コマンドプロンプトを経由せずに実行するには`pipeline()`を使います. 引数`stdin`にファイル名やコマンドを与えることができます. ファイル名の時はダブルクォーテーション, コマンドはバッククォートなので気を付けてください.

```julia
run(pipeline(`program2.exe`, stdin="input2.txt"))
```
              25

```julia
run(pipeline(`program2.exe`, stdin=`cmd /C echo 6`))
```
              36

以下のように`open`文で標準入力を渡すこともできます. 恐らく, 結果を受け取れないようなので`run`でよいと思います. 強いて言うなら, `open`と`end`の間で`for`文を回したり, `write`, `print`,`println`などが使い分けられるなどのメリットがあります.

```julia
open(`program2.exe`, "w", stdout) do io
   println(io, 7)
end
```
              49

```julia
io = open(`program2.exe`, "w", stdout)
println(io, 7)
close(io)
```
              49

## 標準入力から変数を２つ渡す

次の`program3.f90`は標準入力をread文で読み取り, 2つの数値の和を取って標準出力に返すプログラムです. 基本的には先ほどの例と同じですが, Fortran側のプログラムが2つの数値を読み取れるようになっています. コンパイルして生成された`program3.exe`を呼び出して動作を確認していきます. (ファイルは[リポジトリ](https://github.com/ohno/RunningExternalPrograms)にあります. `gfortran`がインストールされてパスが通っていれば`compile.bat`をクリックすると勝手にコンパイルされます.)

`program3.f90`
```fortran
program main
  implicit none
  double precision x, y
  read(5,*) x, y
  write(6,*) x + y
end program main
```
`input2.txt`
```
5
6
```

```julia
run(pipeline(`program3.exe`, stdin="input3.txt"))
```
       11.000000000000000

```julia
run(pipeline(`program3.exe`, stdin=`cmd /C echo 5 7`))
```
       12.000000000000000     

```julia
open(`program3.exe`, "w", stdout) do io
   println(io, "5 8")
end
```
       13.000000000000000     

```julia
input = "5
9"

open(`program3.exe`, "w", stdout) do io
   println(io, input)
end
```
       14.000000000000000     

```julia
open(`program3.exe`, "w", stdout) do io
   println(io, 5)
   println(io, 10)
end
```
       15.000000000000000     

配列として渡したい場合には以下のように対処します.

```julia
input = [5,11]
run(pipeline(`program3.exe`, stdin=`cmd /C echo $input`))
```
       16.000000000000000     

```julia
input = [5,12]
open(`program3.exe`, "w", stdout) do io
    for x in input
        println(io, x)
    end
end
```
       17.000000000000000     

## 外部プログラムを関数として扱う

先ほどの`program3.exe`を例に解説します. このプログラムを関数として扱うには, 戻り値が必要なので`read()`か`readchomp()`を利用します. これらの結果は文字列なので, さらに`parse()`を使って数値に型変換します.

```julia
f(X) = parse(Float64,readchomp(pipeline(`program3.exe`, stdin=`cmd /C echo $X`)))
```

```julia
y = f([5,13])
```
    18.0

## 外部プログラムのパラメータ最適化

ここでは[Optim.jl](https://github.com/JuliaNLSolvers/Optim.jl)を利用します. 事前に[パッケージモード](https://qiita.com/skiing_LAL10/items/0c0132a34629fbc8a91f)で`add Optim`を実行してインストールし, ノート上では`using Optim`を宣言しておく必要があります. まず, [Rosenbrock関数](https://en.wikipedia.org/wiki/Rosenbrock_function)を最小化する例を見てみましょう.

```julia
# using Pkg
# Pkg.add("Optim")
using Optim
```

```julia
rosenbrock_julia(x) = (1.0 - x[1])^2 + 100.0 * (x[2] - x[1]^2)^2
x0 = [0.0, 0.0]
opt = optimize(rosenbrock_julia, x0)

println(Optim.minimizer(opt))
println(Optim.minimum(opt))
```
    [0.9999634355313174, 0.9999315506115275]
    3.5255270584829996e-9
    
次の`program4.f90`は標準入力から変数$x,y$を受け取ってRosenbrock関数の値を標準出力に返す例です. このプログラムをコンパイルした`program4.exe`をJuliaの関数としての扱い, $x,y$を最適化します.

`program4.f90`
```fortran
program main
  implicit none
  double precision x, y
  read(5,*) x, y
  write(6,*) 100.*(x*x-y)**2+(1.-x)**2
end program main
```

```julia
rosenbrock_fortran(x) = parse(Float64,readchomp(pipeline(`program4.exe`, stdin=`cmd /C echo $x`)))
x0 = [0.0, 0.0]
opt = optimize(rosenbrock_fortran, x0)

println(Optim.minimizer(opt))
println(Optim.minimum(opt))
```
    [0.9999634355313174, 0.9999315506115275]
    3.5255270584829996e-9

Juliaだけの例と, Fortranと連携した例で全く同じ結果が得られました.
