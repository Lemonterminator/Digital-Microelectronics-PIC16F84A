# VHDL Lesson 1: GHDL + GTKWave

This directory is set up and validated on Ubuntu 24.04 (WSL2).

## Verified tools
- `ghdl` 4.1.0
- `gtkwave` 3.3.116

## Files
- `hello.vhd`: simple XOR design
- `tb_hello.vhd`: testbench
- `run.sh`: compile + simulate + generate VCD waveform
- `wave.vcd`: simulation waveform output

## Run
```bash
./run.sh
```

## View waveform
```bash
gtkwave wave.vcd
```

## If you need to install on another Ubuntu machine
```bash
sudo apt update
sudo apt install -y ghdl gtkwave
```
