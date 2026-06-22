package main

import "core:fmt"
import "core:os"
import "core:strings"
import "core:strconv"

read_entire_file :: proc(file_path: string) -> (string, bool) {
    data, err := os.read_entire_file(file_path, context.allocator)
    if err != .NONE {
        return "", false
    }
    return string(data), true
}

pushs :: proc(s: ^[dynamic]int, value: int) {
    append(s, value)
}

pops :: proc(s: ^[dynamic]int) -> (int, bool) {
    if len(s^) > 0 {
        value := s^[len(s^)-1]
        s^ = s^[:len(s^)-1]
        return value, true
    }
    return 0, false // Handle empty stack case
}

//--// END-STACK //--//

main :: proc() {
    if len(os.args) <= 1 {
        fmt.println("Masm: Usage: <file.masm>")
        return
    }

    file_path := os.args[1]

    // read file
    contents, ok := read_entire_file(file_path)
    if !ok {
        fmt.println("Masm: Could not read file: ", file_path)
        return
    }

    // interpret it
    // registers: eax, ebx, ecx, ...
    reg := make(map[string]int)

    // the memory, very much like pointer to a BIG memory address!
    memory := make(map[int]string)

    // stack
    MemStack := make([dynamic]int)

    // main interpretation starts here:
    if contents == "" {
        fmt.println("Masm: file:", file_path, "is empty.")
        return
    }

    lines := strings.split_lines(contents)

    new_line: for _, line in lines {
        // Skip empty lines
        if len(line) == 0 {
            continue new_line
        }

        parts := strings.fields(line)
        if len(parts) == 0 {
            continue new_line
        }

        part := parts[0]

        if part == ";;" {
            continue new_line
        }

        if part == "halt" {
            break
        }

        if part == "push" {
            if len(parts) < 2 {
                fmt.println("Masm: Error: push requires an argument")
                continue new_line
            }
            item_str := parts[1]
            value, err := strconv.parse_int(item_str, 10, 64)
            if err != nil {
                fmt.println("Masm: Error: Invalid integer '", item_str, "'")
                continue new_line
            }
            pushs(&MemStack, int(value))
        }

        // Add more instructions here as needed
    }

    fmt.println(MemStack)
    return
}

fmt_error :: proc(file: string, line, col: int, msg: string) {
    fmt.println(file, ":", line, ":", col, " - ", msg)
}