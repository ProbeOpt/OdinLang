package main

import "core:fmt"
import "core:os"
import "core:strings"
import "core:strconv"

/*
    Masm - A simple assembly-like interpreter

    Supported instructions:
      halt                  - stop execution
      nop                   - no operation
      push <operand>        - push value onto stack
      pop <reg>             - pop value from stack into register
      mov <reg>, <operand>  - move value into register
      add <reg>, <operand>  - add to register
      sub <reg>, <operand>  - subtract from register
      mul <reg>, <operand>  - multiply register
      div <reg>, <operand>  - divide register
      mod <reg>, <operand>  - modulo register
      inc <reg>             - increment register
      dec <reg>             - decrement register
      print <operand>       - print value
      dump                  - debug: print registers & stack
      cmp <op1>, <op2>      - compare two values, set flags
      jmp <label>           - unconditional jump
      je/jz  <label>        - jump if equal / zero
      jne/jnz <label>       - jump if not equal / not zero
      jl <label>            - jump if less
      jg <label>            - jump if greater
      jle <label>           - jump if less or equal
      jge <label>           - jump if greater or equal
      call <label>          - call subroutine
      ret                   - return from subroutine
      <name>:               - define a label

    Operands:
      $5   or  5            - immediate integer
      eax, ebx, ecx, edx    - registers (also esi, edi, esp, ebp)

    Lines starting with ;; are comments.

    Example program (save as sample.masm):
      ;; Compute 5! = 120
      mov ecx, $5
      mov eax, $1
      loop:
          mul eax, ecx
          dec ecx
          jg loop
      print eax
      halt
*/

Instruction :: struct {
    op:   string,
    arg1: string,
    arg2: string,
    line: int,
}

State :: struct {
    reg:        map[string]int,
    memory:     map[int]int,
    stack:      [dynamic]int,
    call_stack: [dynamic]int,
    labels:     map[string]int,
    code:       [dynamic]Instruction,
    ip:         int,
    flags: struct {
        zero:    bool,
        sign:    bool,
        less:    bool,
        greater: bool,
    },
}

read_entire_file :: proc(file_path: string) -> (string, bool) {
    data, err := os.read_entire_file(file_path, context.allocator)
    if err != nil {
        return "", false
    }
    return string(data), true
}

is_register :: proc(name: string) -> bool {
    return name == "eax" || name == "ebx" || name == "ecx" || name == "edx" ||
           name == "esi" || name == "edi" || name == "esp" || name == "ebp"
}

// Resolve an operand to an integer value.
// Accepts: $5, 5 (immediates) or register names.
resolve_operand :: proc(state: ^State, operand: string) -> (int, bool) {
    if len(operand) == 0 {
        return 0, false
    }
    if strings.has_prefix(operand, "$") {
        value, err := strconv.parse_int(operand[1:], 10, 64)
        if err != nil {
            return 0, false
        }
        return int(value), true
    }
    if is_register(operand) {
        if val, ok := state.reg[operand]; ok {
            return val, true
        }
        return 0, true
    }
    // Try parsing as a bare integer
    value, err := strconv.parse_int(operand, 10, 64)
    if err == nil {
        return int(value), true
    }
    return 0, false
}

set_register :: proc(state: ^State, name: string, value: int) -> bool {
    if is_register(name) {
        state.reg[name] = value
        return true
    }
    return false
}

fmt_error :: proc(file: string, line_num: int, msg: string) {
    fmt.println(file, ":", line_num, " - ", msg)
}

parse_program :: proc(file_path: string, contents: string) -> (State, bool) {
    state := State{
        reg        = make(map[string]int),
        memory     = make(map[int]int),
        stack      = make([dynamic]int, context.allocator),
        call_stack = make([dynamic]int, context.allocator),
        labels     = make(map[string]int),
        code       = make([dynamic]Instruction, context.allocator),
        ip         = 0,
    }

    // Initialize registers to 0
    state.reg["eax"] = 0
    state.reg["ebx"] = 0
    state.reg["ecx"] = 0
    state.reg["edx"] = 0
    state.reg["esi"] = 0
    state.reg["edi"] = 0
    state.reg["esp"] = 0
    state.reg["ebp"] = 0

    lines := strings.split_lines(contents)
    instr_index := 0

    for line_num, raw_line in lines {
        line := strings.trim_space(raw_line)
        if len(line) == 0 { continue }
        if strings.has_prefix(line, ";;") { continue }

        parts := strings.fields(line)
        if len(parts) == 0 { continue }

        // Check for inline label: "name:" or "name:" followed by instruction
        if strings.has_suffix(parts[0], ":") {
            label_name := parts[0][:len(parts[0])-1]
            if len(label_name) > 0 {
                state.labels[label_name] = instr_index
            }
            parts = parts[1:]
            if len(parts) == 0 { continue }
        }

        // Strip trailing commas from each token ("mov eax, ebx" -> ["mov","eax","ebx"])
        cleaned := make([dynamic]string, context.allocator)
        for p in parts {
            append(&cleaned, strings.trim_right(p, ","))
        }

        instr := Instruction{
            op=   cleaned[0],
            line= line_num + 1
        }
        if len(cleaned) >= 2 { instr.arg1 = cleaned[1] }
        if len(cleaned) >= 3 { instr.arg2 = cleaned[2] }

        append(&state.code, instr)
        instr_index += 1
    }

    return state, true
}

jump_to_label :: proc(state: ^State, file_path: string, line_num: int, label: string) -> bool {
    if target, ok := state.labels[label]; ok {
        state.ip = target
        return true
    }
    fmt_error(file_path, line_num, "Unknown label: " + label)
    return false
}

execute :: proc(state: ^State, file_path: string) {
    for state.ip < len(state.code) {
        instr := state.code[state.ip]

        switch instr.op {
        case "halt":
            return

        case "nop", "":
            state.ip += 1

        case "push":
            value, ok := resolve_operand(state, instr.arg1)
            if !ok {
                fmt_error(file_path, instr.line, "Invalid operand for push: " + instr.arg1)
                return
            }
            append(&state.stack, value)
            state.ip += 1

        case "pop":
            if !is_register(instr.arg1) {
                fmt_error(file_path, instr.line, "pop requires a register")
                return
            }
            if len(state.stack) == 0 {
                fmt_error(file_path, instr.line, "pop from empty stack")
                return
            }
            value := state.stack[len(state.stack)-1]
            state.stack = state.stack[:len(state.stack)-1]
            set_register(state, instr.arg1, value)
            state.ip += 1

        case "mov":
            if !is_register(instr.arg1) {
                fmt_error(file_path, instr.line, "mov destination must be a register")
                return
            }
            value, ok := resolve_operand(state, instr.arg2)
            if !ok {
                fmt_error(file_path, instr.line, "Invalid source operand for mov")
                return
            }
            set_register(state, instr.arg1, value)
            state.ip += 1

        case "add":
            if !is_register(instr.arg1) {
                fmt_error(file_path, instr.line, "add destination must be a register")
                return
            }
            v2, ok := resolve_operand(state, instr.arg2)
            if !ok {
                fmt_error(file_path, instr.line, "Invalid source operand for add")
                return
            }
            state.reg[instr.arg1] = state.reg[instr.arg1] + v2
            state.ip += 1

        case "sub":
            if !is_register(instr.arg1) {
                fmt_error(file_path, instr.line, "sub destination must be a register")
                return
            }
            v2, ok := resolve_operand(state, instr.arg2)
            if !ok {
                fmt_error(file_path, instr.line, "Invalid source operand for sub")
                return
            }
            result := state.reg[instr.arg1] - v2
            state.reg[instr.arg1] = result
            state.flags.zero = (result == 0)
            state.flags.sign = (result < 0)
            state.ip += 1

        case "mul":
            if !is_register(instr.arg1) {
                fmt_error(file_path, instr.line, "mul destination must be a register")
                return
            }
            v2, ok := resolve_operand(state, instr.arg2)
            if !ok {
                fmt_error(file_path, instr.line, "Invalid source operand for mul")
                return
            }
            state.reg[instr.arg1] = state.reg[instr.arg1] * v2
            state.ip += 1

        case "div":
            if !is_register(instr.arg1) {
                fmt_error(file_path, instr.line, "div destination must be a register")
                return
            }
            v2, ok := resolve_operand(state, instr.arg2)
            if !ok {
                fmt_error(file_path, instr.line, "Invalid source operand for div")
                return
            }
            if v2 == 0 {
                fmt_error(file_path, instr.line, "Division by zero")
                return
            }
            state.reg[instr.arg1] = state.reg[instr.arg1] / v2
            state.ip += 1

        case "mod":
            if !is_register(instr.arg1) {
                fmt_error(file_path, instr.line, "mod destination must be a register")
                return
            }
            v2, ok := resolve_operand(state, instr.arg2)
            if !ok {
                fmt_error(file_path, instr.line, "Invalid source operand for mod")
                return
            }
            if v2 == 0 {
                fmt_error(file_path, instr.line, "Modulo by zero")
                return
            }
            state.reg[instr.arg1] = state.reg[instr.arg1] % v2
            state.ip += 1

        case "inc":
            if !is_register(instr.arg1) {
                fmt_error(file_path, instr.line, "inc requires a register")
                return
            }
            state.reg[instr.arg1] += 1
            state.ip += 1

        case "dec":
            if !is_register(instr.arg1) {
                fmt_error(file_path, instr.line, "dec requires a register")
                return
            }
            state.reg[instr.arg1] -= 1
            state.ip += 1

        case "print":
            value, ok := resolve_operand(state, instr.arg1)
            if ok {
                fmt.println(value)
            } else {
                // Fall back to printing the literal token
                fmt.println(instr.arg1)
            }
            state.ip += 1

        case "dump":
            fmt.println("=== DUMP ===")
            fmt.println("Registers:")
            for k, v in state.reg {
                fmt.println("  ", k, " = ", v)
            }
            fmt.println("Stack:     ", state.stack)
            fmt.println("CallStack: ", state.call_stack)
            fmt.println("IP:        ", state.ip)
            fmt.println("============")
            state.ip += 1

        case "cmp":
            v1, ok1 := resolve_operand(state, instr.arg1)
            v2, ok2 := resolve_operand(state, instr.arg2)
            if !ok1 || !ok2 {
                fmt_error(file_path, instr.line, "Invalid operands for cmp")
                return
            }
            diff := v1 - v2
            state.flags.zero    = (diff == 0)
            state.flags.sign    = (diff < 0)
            state.flags.less    = (v1 < v2)
            state.flags.greater = (v1 > v2)
            state.ip += 1

        case "jmp":
            if !jump_to_label(state, file_path, instr.line, instr.arg1) { return }

        case "je", "jz":
            if state.flags.zero {
                if !jump_to_label(state, file_path, instr.line, instr.arg1) { return }
            } else {
                state.ip += 1
            }

        case "jne", "jnz":
            if !state.flags.zero {
                if !jump_to_label(state, file_path, instr.line, instr.arg1) { return }
            } else {
                state.ip += 1
            }

        case "jl":
            if state.flags.less {
                if !jump_to_label(state, file_path, instr.line, instr.arg1) { return }
            } else {
                state.ip += 1
            }

        case "jg":
            if state.flags.greater {
                if !jump_to_label(state, file_path, instr.line, instr.arg1) { return }
            } else {
                state.ip += 1
            }

        case "jle":
            if state.flags.zero || state.flags.less {
                if !jump_to_label(state, file_path, instr.line, instr.arg1) { return }
            } else {
                state.ip += 1
            }

        case "jge":
            if state.flags.zero || state.flags.greater {
                if !jump_to_label(state, file_path, instr.line, instr.arg1) { return }
            } else {
                state.ip += 1
            }

        case "call":
            if target, ok := state.labels[instr.arg1]; ok {
                append(&state.call_stack, state.ip + 1)
                state.ip = target
            } else {
                fmt_error(file_path, instr.line, "Unknown label: " + instr.arg1)
                return
            }

        case "ret":
            if len(state.call_stack) == 0 {
                fmt_error(file_path, instr.line, "ret without matching call")
                return
            }
            state.ip = state.call_stack[len(state.call_stack)-1]
            state.call_stack = state.call_stack[:len(state.call_stack)-1]

        case:
            fmt_error(file_path, instr.line, "Unknown instruction: " + instr.op)
            return
        }
    }
}

main :: proc() {
    if len(os.args) <= 1 {
        fmt.println("Masm: Usage: <file.masm>")
        return
    }

    file_path := os.args[1]
    contents, ok := read_entire_file(file_path)
    if !ok {
        fmt.println("Masm: Could not read file:", file_path)
        return
    }

    if contents == "" {
        fmt.println("Masm: file:", file_path, "is empty.")
        return
    }

    state, ok := parse_program(file_path, contents)
    if !ok {
        return
    }

    execute(&state, file_path)
}