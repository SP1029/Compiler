# Compiler
This project involves building compilation toolchain that translates a statically-typed subset of the **Python 3.6** into executable `x86_64` assembly code in 3 phases.

### Milestone 1: Lexical Analysis and Parsing
- Implemented a scanner in **Flex** and LALR parser in **Bison** for a statically typed Python 3.6 subset
- Generated a graphical representation of the **Abstract Syntax Tree** (AST) as a PDF from a DOT script output
- Supported features like primitive types, operators, control flow, functions, and basic OOP with single inheritance

### Milestone 2: Semantic Analysis and Intermediate Code Generation
- Performed semantic analysis creating a **symbol table** and checking for scope, type, and argument errors
- Generated a semantically equivalent **Three-Address Code (3AC)** representation for correct input programs
- Implemented runtime support for function calls via activation records and provided meaningful error messages

### Milestone 3: x86_64 Code Generation
- Translated the Three-Address Code (3AC) into runnable `x86_64` assembly code compatible with GAS on Linux
- Focused on correctness and completeness, ensuring the generator handled large expressions without failure
- Showcased the complete end-to-end translation of Python features into executable code

## Directory Structure
```bash
├───Code
│   ├───milestone 1
│   │   ├───src
│   │   └───tests
│   ├───milestone2
│   │   └───src
│   └───milestone3
│       ├───src
│       └───tests
├───Documentation
└───Problem Statements
```
