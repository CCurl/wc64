# What is wc64?
wc64 is a 64-bit implementation of Forth inspired by Tachyon, written for the FASM assembler.

The executable is currently at about 5552 bytes.

wc64 has a bunch of primitives and it:
- has a minimal "inner loop"
- can create colon-definitions,
- knows about immediate words,
- can make any syscall (with 0-6 arguments), and
- automatically loads a 'boot-file' named 'wc64-boot.fth' if it exists.

## Architecture Highlights
- **Direct-threaded interpreter** with tail-call dispatch optimization (31.5% faster than traditional CALL/RET)
- **Bit 63 tagging** for numeric literals and constants: enables unified dispatch through the interpreter
- **Tagged constants** in primTable: `(lit)`, `(jmp)`, `(jmpz)`, `(jmpnz)`, `(njmpz)`, `(njmpnz)`, `(h)`, `mem`, `cell`, `version`, `(l)`, `base`, `state` are compile-time constants generated via the `TAGGED_NUM` macro

### Tagged Constants Explanation
The interpreter uses bit 63 as a marker to distinguish between different value types:
- **Bit 63 = 0**: Code address (primitive or colon definition) → execute via `jmp`
- **Bit 63 = 1**: Numeric literal or constant → extract value with `btr` and push to stack

This unified approach eliminates special casing in the dictionary lookup and dispatch logic. Constants like `cell` (8) and address references like `(h)` are stored in primTable with bit 63 set, so they behave identically to numeric literals in code.

#### TAGGED_NUM Macro
Tagged constants are generated using the `TAGGED_NUM` macro:
```asm
macro TAGGED_NUM name, val {
    name = (val) + xNum
}

TAGGED_NUM PLIT_ADDR,   p_LIT
TAGGED_NUM PJMP_ADDR,   p_JMP
```

This approach keeps the constant definitions DRY and ensures all tagged values are consistently marked with bit 63.

## Building wc64
- On Linux, use make. Requires that `fasm` is installed.

I actually directed Claude (Haiku 4.5) to code most of it (with guidance from me), so I am hoping that it "understands" it well enough that it might be able to migrate it to another CPU/platform without too much trouble.

## Built-in primitives:

### Stack Manipulation
| Word        | Stack               | Description |
|-------------|---------------------|------------------------------|
| dup         | (n -- n n)          | Duplicate top of stack |
| drop        | (n --)              | Remove top of stack |
| swap        | (n1 n2 -- n2 n1)    | Swap top two stack items |
| over        | (n1 n2 -- n1 n2 n1) | Copy second item to top |

### Arithmetic
| Word   | Stack          | Description |
|--------|----------------|------------------------------|
| +      | (n1 n2 -- n3)  | Add |
| -      | (n1 n2 -- n3)  | Subtract (n1 - n2) |
| *      | (n1 n2 -- n3)  | Multiply |
| /mod   | (n1 n2 -- q r) | Quotient and remainder |
| 1+     | (n -- n')      | Increment |
| 1-     | (n -- n')      | Decrement |
| negate | (n -- -n)      | Negate |

### Logical/Bitwise
| Word   | Stack         | Description |
|--------|---------------|------------------------------|
| and    | (n1 n2 -- n3) | Bitwise AND |
| or     | (n1 n2 -- n3) | Bitwise OR |
| xor    | (n1 n2 -- n3) | Bitwise XOR |
| invert | (n -- ~n)     | Bitwise NOT |

### Comparison
| Word | Stack        | Description |
|------|--------------|------------------------------|
| =    | (n1 n2 -- f) | Equal (0 or -1) |
| <    | (n1 n2 -- f) | Less than (0 or -1) |
| >    | (n1 n2 -- f) | Greater than (0 or -1) |

### Memory Access
| Word | Stack       | Description |
|------|-------------|------------------------------|
| @    | (addr -- n) | Fetch 64-bit cell from memory |
| !    | (n addr --) | Store 64-bit cell to memory |
| c@   | (addr -- c) | Fetch byte from memory |
| c!   | (c addr --) | Store byte to memory |

### Return Stack
| Word | Stack               | Description |
|------|---------------------|------------------------------|
| >r   | (n --) (R: -- n)    | Push to return stack |
| r@   | (-- n) (R: n -- n ) | Copy return stack top |
| r>   | (-- n) (R: n --)    | Pop from return stack |

### Literals & Code
| Word   | Stack     | Description |
|--------|-----------|------------------------------|
| lit    | (-- n)    | Push next cell as literal |
| (lit)* | (-- addr) | Address of lit primitive (tagged constant) |
| lit,   | (n --)    | Compile n as literal |
| (h)*   | (-- addr) | Address of HERE variable (tagged constant) |
| mem*   | (-- addr) | Base address of code memory (tagged constant) |
| cell*  | (-- n)    | Size of a cell in bytes (tagged constant) |
| version* | (-- n)  | Version number (tagged constant) |
| ,      | (n --)    | Compile cell to HERE |

\* *Indicates tagged constant: value is pushed directly via bit 63 tagging*

### I/O
| Word | Stack         | Description |
|------|---------------|------------------------------|
| emit | (c --)        | Output character |
| type | (addr len --) | Output string |
| key  | (-- c)        | Read character from input |
| cr   | (--)          | Output newline |

### Dictionary
| Word     | Stack        | Description |
|----------|--------------|------------------------------|
| (l)*     | (-- addr)    | Address of LAST variable (tagged constant) |
| base*    | (-- addr)    | Address of current number base variable (tagged constant) |
| state*   | (-- addr)    | Address of compile/interpret state variable (tagged constant) |
| find     | (cs -- addr) | Find word in dictionary (0 if not found) |
| add-word | (--)         | Add the next word to dictionary |

\* *Indicates tagged constant: value is pushed directly via bit 63 tagging*

### String Operations
| Word      | Stack           | Description |
|-----------|-----------------|------------------------------|
| s-len     | (str -- n)      | Length of null-terminated string |
| lcase     | (c -- c')       | Convert character to lowercase |
| s-eqi     | (s1 s2 -- f)    | Case-insensitive string equality |
| count     | (cs -- str len) | Split counted string into address/length |
| next-word | (--)            | Parse next word from input |
| >in       | (-- addr)       | Address of input position variable |
| wd        | (-- addr)       | Address of word buffer |

### Parsing
| Word   | Stack            | Description |
|--------|------------------|------------------------------|
| is-num | (cs -- n 1 \| 0) | Parse number (decimal/hex/binary) |

### Control Flow
| Word     | Stack  | Description |
|----------|--------|------------------------------|
| exit     | (--)   | Return from colon definition |
| (jmp)    | (--)   | Unconditional branch |
| (jmpz)   | (f --) | Branch if zero (pops stack) |
| (jmpnz)  | (f --) | Branch if nonzero (pops stack) |
| (njmpz)  | (--)   | Branch if TOS zero (no pop) |
| (njmpnz) | (--)   | Branch if TOS nonzero (no pop) |

### Locals (Temp Stack)
| Word | Stack  | Description |
|------|--------|------------------------------|
| +L   | (--)   | Allocate locals frame (x, y, z) |
| -L   | (--)   | Free locals frame |
| x@   | (-- x) | Fetch local variable x |
| x!   | (n --) | Store to local variable x |
| x@+  | (-- x) | Fetch x then increment |
| y@   | (-- y) | Fetch local variable y |
| y!   | (n --) | Store to local variable y |
| y@+  | (-- y) | Fetch y then increment |
| z@   | (-- z) | Fetch local variable z |
| z!   | (n --) | Store to local variable z |
| z@+  | (-- z) | Fetch z then increment |

### Code Compilation
| Word      | Stack | Description |
|-----------|-------|------------------------------|
| immediate | (--)  | Mark last-defined word as immediate |

### File I/O
| Word   | Stack              | Description |
|--------|--------------------|------------------------------|
| fopen  | (name flags -- fd) | Open file (Linux syscall) |
| fclose | (fd --)            | Close file |
| fread  | (buf len fd -- n)  | Read from file |
| fwrite | (buf len fd -- n)  | Write to file |

### System Calls
| Word     | Stack                      | Description |
|----------|------------------------    |------------------------------|
| syscall0 | (n -- r)                   | Make Linux syscall with 0 args |
| syscall1 | (a1 n -- r)                | Make Linux syscall with 1 arg  |
| syscall2 | (a1 a2 n -- r)             | Make Linux syscall with 2 args |
| syscall3 | (a1 a2 a3 n -- r)          | Make Linux syscall with 3 args |
| syscall4 | (a1 a2 a3 a4 n -- r)       | Make Linux syscall with 4 args |
| syscall5 | (a1 a2 a3 a4 a5 n -- r)    | Make Linux syscall with 5 args |
| syscall6 | (a1 a2 a3 a4 a5 a6 n -- r) | Make Linux syscall with 6 args |

### Other
| Word  | Stack    | Description |
|-------|----------|------------------------------|
| outer | (str --) | Interpret string as Forth code |
| bye   | (--)     | Exit the system |
