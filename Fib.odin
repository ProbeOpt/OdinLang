package main

import "core:fmt"

fib :: proc(n: int) -> int {
    a, b := 0, 1
    for _ in 0..=n {
        a, b = b, a + b // a becomes b, and b becomes sum of a and b. cool algo btw.
    }
    return a // return the `a` variable, since it holds our fib.
}

main :: proc() {
    // how to calcualte fib?
    fmt.println("\nfib(100) = ", fib(100))
}