#include "logic_gate.h"

int not_gate(const int a){
  return (~a) & 1;
}

int and_gate(const int a, const int b){
  return (a & b) & 1;
}

int nand_gate(const int a, const int b){
  return (~(a & b)) & 1;
}

int or_gate(const int a, const int b){
  return (a | b) & 1;
}

int xor_gate(const int a, const int b){
  return (a ^ b) & 1;
}
