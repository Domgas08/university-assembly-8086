## INT 1 Step Mode – ADD (and OR) Instruction Analysis (8086 Assembly)

This program implements an INT 1 (single-step / trap mode) interrupt handler
that analyzes executed instructions and recognizes the
`ADD r/m, immediate` instruction format and `OR r/m, immediate`.

The interrupt handler:
- Detects step-mode interrupts (INT 1)
- Checks whether the executed instruction is ADD
- Decodes ModR/M byte
- Handles byte and word operations
- Prints instruction address, opcode, operands, and immediate values
