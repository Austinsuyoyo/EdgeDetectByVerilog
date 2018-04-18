# EdgeDetectByVerilog

Use iverilog(compiler) compile file and get edge detect image(bmp file)

# Enviroment
1. Windows OS
2. Dowload & Install iverilog compiler from [here](http://bleyer.org/icarus/)

# Usage
Use these command compile your file
```
iverilog -o  bmp top.v load_bmp.v sram.v filter.v
vvp bmp
```

# Original
![Original](https://raw.githubusercontent.com/Austinsuyoyo/EdgeDetectByVerilog/master/src/lena_256x256.bmp)

# Output
![Original](https://raw.githubusercontent.com/Austinsuyoyo/EdgeDetectByVerilog/master/img/lena_output.bmp)
