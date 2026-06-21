package main

import "core:fmt"

is_prime :: proc(n: int) -> bool {
    if n <= 1 { return false } // if n is either smaller then 1 or is 1, is not a prime.
    if n <= 3 { return true }  // if n is either 2 or 3, it is a prime.
    if n % 2 == 0 || n % 3 == 0 { return false } // if it is divisible by 2 or 3, then it is not a prime.

    i := 5 // we set i to 5, since 5 is next prime number.
    for {
        if (i*i) <= n { // continue if i*i is less then or equal to n.
            if n % i == 0 || n % (i+2) == 0 { // if n is divisible by i OR n is divisible by i+2, and dont prodice a remainder, then it is not a prime.
                return false
            }
            i += 6
        } else { break } // if number is greater then i^2 then we break, because, that is out of our scope.
    }

    return true // otherwise, number IS a prime.
}

main :: proc() {
    limit := 100

    fmt.println("Prime numbers up to", limit, ":")

    for n := 2; n <= limit; n += 1 {
        if is_prime(n) {
            fmt.println(n)
        }
    }
}