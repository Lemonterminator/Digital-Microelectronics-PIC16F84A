# C++ Lesson 1: Circuit Prototype + VCD for GTKWave

This folder demonstrates a circuit prototype in C++ and generates a VCD waveform.

## Files
- `main.cpp`: XOR model + VCD writer
- `run.sh`: build and run
- `wave.vcd`: waveform file (generated)

## Run
```bash
./run.sh
```

## View waveform
```bash
gtkwave wave.vcd
```

## How visualization works
GTKWave reads waveform dump formats like VCD. In HDL, simulators write VCD for you; in C++, you can write the same VCD text format directly, then open it in GTKWave.
