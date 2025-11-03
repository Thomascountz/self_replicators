# BFF

BFF is an extension of the Brainfuck language, developed by the research team at Paradigms of Intelligence for their self-replicator research[^1].

Instead of describing the language like they do in the paper, I want to document the design decisions of the interpreter I've implemented here.

## Brainfuck

[Brainfuck (BF)](https://esolangs.org/wiki/Brainfuck) is a minimalist turing-complete programming language created in 1993 by Urban Müller. A brainfuck program is made up of eight instructions, and the interpreter consists of an instruction pointer, a data array (or tape) of bytes, a data pointer, and input/output streams.

The instruction pointer starts at the beginning of the program and executes one instruction at a time. The data pointer can be moved forward and backward through the tape and instructions can add or subtract the value of data where it is pointing. Bytes from the data array are written to and read from the input and output streams, respectively.

## BFF - Brainfuck Family Extension

BFF extends BF by:

1. Adding a second data pointer
2. Replacing the I/O streams with read/write operations between the two data pointers
3. Using the data tape for both instructions and data

This means that both data pointers (`head0` and `head1`) can manipulate instructions read by the instruction pointer, i.e. the program can modify itself during execution. This ability for a program to modify itself during execution is known as metaprogramming.

The researchers specific implementation of BFF is available on Github here: [https://github.com/paradigms-of-intelligence/cubff](https://github.com/paradigms-of-intelligence/cubff)

### Instruction Set

The BFF language is made up of 10 instructions and a `Null` type. These are similar to the Brainfuck instructions, but with some differences in semantics and behavior to support the metaprogramming capabilities.

| Instruction | Definition                                                   |
| ----------- | ------------------------------------------------------------ |
| <           | head0 = head0 - 1                                            |
| >           | head0 = head0 + 1                                            |
| {           | head1 = head1 - 1                                            |
| }           | head1 = head1 + 1                                            |
| -           | tape[head0] = tape[head0] - 1                                |
| +           | tape[head0] = tape[head0] + 1                                |
| .           | tape[head1] = tape[head0]                                    |
| ,           | tape[head0] = tape[head1]                                    |
| [           | if (tape[head0] == 0): jump forwards to matching ] command.  |
| ]           | if (tape[head0] != 0): jump backwards to matching [ command. |

### Design Decisions for This Implementation

1. A "tape" is constructed of 64 "cells," initialized to a random value 8-bit Extended ASCII value.
2. Cells do not overflow or underflow into neighboring cells, but instead their values will wrap around. i.e., if a cell is decremented below `0`, it will wrap to `255`, and if incremented above `255`, it will wrap to `0`.
3. The instruction pointer and both read/write heads start at data tape index `0` and interpretation begins with the instruction at that position.
4. Unbalanced parentheses will cause the program to terminate after reaching either end of the tape while searching for a match.
5. The program automatically terminates after a fixed number of characters being read (2^13).
6. By virtue of borrowing most of the original BF instruction set, the distribution of valid instructions across the 256 possible byte values is not uniform.

[^1]: Alakuijala, Jyrki, et al. "Computational life: How well-formed, self-replicating programs emerge from simple interaction." arXiv preprint arXiv:2406.19108 (2024).
