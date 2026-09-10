#include <stdio.h>
#include <stdint.h>

// Definimos la estructura de la CPU
typedef struct {
    uint32_t pc;         // contador de 32 bits
    uint32_t psw;        // estatus (program status word)
    uint16_t regs[16];   // 16 registros de 16 bits
} CPU;

#define DATA_MEM_SIZE 65536
#define PROG_MEM_SIZE 64

uint8_t data_memory[DATA_MEM_SIZE];
uint32_t program_memory[PROG_MEM_SIZE]; // vector de 32 bits

void execute_instruction_32bit(CPU *cpu, uint32_t instr) {
    // extraemos los primeros 4 bits (31-28) 
    uint32_t opcode = (instr >> 28) & 0xF;

    switch (opcode) {
        
        case 0x0: { // ADD (Tipo r) -> | p1(4b) | p2(4b) | p3(4b) | p4(4b) | p5(4b) |  12 bits en cero |
            // instr >> 28 es p1 (0000, caso 0x0)
            uint32_t rd = (instr >> 24) & 0xF; // P2
            uint32_t rs = (instr >> 20) & 0xF; // P3
            uint32_t rt = (instr >> 16) & 0xF; // P4
            // p5 estaría en (instr >> 12) & 0xF y debería ser 0000
            
            cpu->regs[rd] = cpu->regs[rs] + cpu->regs[rt];
            
            printf("[ADD] R%d = R%d + R%d | Resultado: %d\n", rd, rs, rt, cpu->regs[rd]);
            cpu->pc++;
            break;
        }

        case 0x2: { // LW -> | 2h (4b) | rd (4b) | rs (4b) | 20 bits restantes (offset) |
            uint32_t rd     = (instr >> 24) & 0xF;
            uint32_t rs     = (instr >> 20) & 0xF;
            uint32_t offset = instr & 0xFFFFF;
            
            uint32_t address = cpu->regs[rs] + offset;
            
            if (address < DATA_MEM_SIZE - 1) {
                // lee 16 bits (2 bytes) de la memoria de datos
                cpu->regs[rd] = data_memory[address] | (data_memory[address + 1] << 8);
                printf("[LW] R%d cargado desde memoria[0x%05X]\n", rd, address);
            } else {
                printf("[ERROR LW] Dirección 0x%05X fuera de rango\n", address);
            }
            cpu->pc++;
            break;
        }

        case 0x3: { // SW -> | 3h (4b) | rd (4b) | rs (4b) | 20 bits (offset) |
            uint32_t rd     = (instr >> 24) & 0xF;
            uint32_t rs     = (instr >> 20) & 0xF;
            uint32_t offset = instr & 0xFFFFF;
            
            uint32_t address = cpu->regs[rs] + offset;
            
            if (address < DATA_MEM_SIZE - 1) {
                // 16 bits (2 bytes) en la memoria de datos
                data_memory[address]     = cpu->regs[rd] & 0xFF;
                data_memory[address + 1] = (cpu->regs[rd] >> 8) & 0xFF;
                printf("[SW] Guardado R%d en memoria[0x%05X]\n", rd, address);
            } else {
                printf("[ERROR SW] Dirección 0x%05X fuera de rango\n", address);
            }
            cpu->pc++;
            break;
        }

        case 0x4: { // BEQ -> | 4h (4b) | rd (4b) | rs (4b) | 20 bits (target/offset)  |
            uint32_t rd     = (instr >> 24) & 0xF;
            uint32_t rs     = (instr >> 20) & 0xF;
            uint32_t target = instr & 0xFFFFF; // dirección de salto en program_memory
            
            if (cpu->regs[rd] == cpu->regs[rs]) {
                cpu->pc = target; 
                printf("[BEQ] %d == %d. Saltando a PC: %d\n", cpu->regs[rd], cpu->regs[rs], cpu->pc);
            } else {
                cpu->pc++;
                printf("[BEQ] %d != %d. No se toma el salto.\n", cpu->regs[rd], cpu->regs[rs]);
            }
            break;
        }

        case 0xE: { // J -> | 1110 (4b) | Dirección de salto (28 bits) |
            // 1110 binario = 0xE en Hexadecimal
            uint32_t target = instr & 0xFFFFFFF; // 28 bits de dirección 
            
            cpu->pc = target;
            printf("[J] Salto incondicional a PC: %d\n", cpu->pc);
            break;
        }

        default:
            printf("[ERROR] Opcode ejecutable no válido: 0x%X\n", opcode);
            cpu->pc++; //evita el bucle infinito
            break;
    }
}