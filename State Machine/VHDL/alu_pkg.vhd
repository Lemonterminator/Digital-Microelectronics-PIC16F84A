library ieee;
use ieee.std_logic_1164.all;

package alu_pkg is

  type alu_op is (
    ADDWF, ANDWF, ADDLW, ANDLW, BCF, BTFSC,
    BSF, BTFSS, CLRF, CLRW, COMF, DECF,
    DECFSZ, INCF, INCFSZ, IORLW, MOVF, MOVWF, CALL,
    GOTO, MOVLW, RETLW, RETUR, IORWF, NOP,
    RLF, RRF, SUBLW, SUBWF, SWAPF, XORLW, XORWF
  );

  constant STATUS_Z  : natural := 2;
  constant STATUS_DC : natural := 1;
  constant STATUS_C  : natural := 0;

end package alu_pkg;

package body alu_pkg is
end package body alu_pkg;
