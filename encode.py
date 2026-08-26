#!/usr/bin/env python3
"""Encoder STX4/RTM32. Opcode = 5 bits en [31:27] (NO 6 bits estilo MIPS)."""

def enc_r(func, rs=0, rt=0, rd=0, aux=0, x=0):
    return ((rs & 31) << 22) | ((rt & 31) << 17) | ((rd & 31) << 12) | ((aux & 31) << 7) | ((x & 1) << 6) | (func & 63)

def enc_i(op, rs, rt, imm):
    return ((op & 31) << 27) | ((rs & 31) << 22) | ((rt & 31) << 17) | (imm & 0x1FFFF)

def enc_l(op, rs, rt, imm, h=0):
    return ((op & 31) << 27) | ((rs & 31) << 22) | ((rt & 31) << 17) | ((h & 1) << 16) | (imm & 0xFFFF)

def enc_j(op, addr_words):
    return ((op & 31) << 27) | (addr_words & 0x7FFFFFF)

OP = dict(ADDI=1, J=2, JAL=3, ANDI=4, ORI=5, XORI=6, LUI=7,
          LW=8, SW=9, SH=10, SB=11, LH=12, LHU=13, LB=14, LBU=15,
          BEQ=16, BNE=17, BLT=18, BGT=19, BLE=20, BGE=21, SLTI=22, SLTIU=23)

FN = dict(SLL=0, SRL=1, SRA=2, SLLR=3, SRLR=4, SRAR=5,
          AND=8, OR=9, XOR=10, NOR=11, SLT=12, SLTU=13, JR=14, JALR=15,
          LHX=16, LHUX=17, LBX=18, LBUX=19, LWX=20, MUL=21, MULH=22, MULHU=23,
          DIV=24, DIVU=25, REST=26, RESTU=27, ADD=28, SUB=29, TRAP=32, RFT=33)

if __name__ == "__main__":
    print(f"ADDI R2,R0,21 = 0x{enc_i(OP['ADDI'], 0, 2, 21):08X}")
    print(f"ADD  R6,R4,R5 = 0x{enc_r(FN['ADD'], 4, 5, 6):08X}")
    print(f"J    word 5   = 0x{enc_j(OP['J'], 5):08X}")
