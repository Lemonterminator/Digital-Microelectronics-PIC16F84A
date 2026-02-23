# Verilog Lesson 1: Icarus Verilog + GTKWave

## Files
- `hello.v`: simple XOR design
- `tb_hello.v`: testbench
- `run.sh`: compile + simulate
- `wave.vcd`: waveform output (after running)

## Install (Ubuntu)
```bash
sudo apt update
sudo apt install -y iverilog verilator yosys gtkwave
```

## Run
```bash
./run.sh
```

## View waveform
```bash
gtkwave wave.vcd
```
