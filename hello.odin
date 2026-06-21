package main

import "core:fmt"
import "core:slice"

Directions :: enum {
    N,
    S,
    E,
    W,
    UP,
    DOWN
}

main :: proc() {
    // variables
    a := 100 // we dont have `;` in this, cool.
    // now I assume that `a` has type int?
    b: i32 = 12000; // so now `b` is i32, nice.

    // how to free variables?
    // idk!

    // ---

    if a != 0 {
        if a > b {
            fmt.println("a > b")
        } else if a >= b {
            fmt.println("a >= b")
        } else if a < b {
            fmt.println("a < b")
        } else if a <= b {
            fmt.println("a <= b")
        } else {
            fmt.println("panic: unreachable.")
        }
    }

    // ---

    for i in 0..=10 {
        // this loop contains, [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10].
        fmt.println("i = ", i) // and yes, we can use multipule items, WITHOUT NEED TO SPECIFY TYPE, YAYYYYYY!
    }

    for i in 0..<2 {
        // this loop contains: [0,1], it skips 2, because 2 is not less then 2.
        fmt.println("less then 2: ", i)
    }

    for i := 0; i < 10; i += 1; { // our standard c style loop.
        fmt.println("i: ", i)
    }

    /* for {
     *     // forever loop
     * }
     */

     text := "hello worlds!!!!"

     for letter, i in text { // `letter` is rune(somewhat simmilar to char), `i` is index.
         fmt.println(i, ": ",letter, " type: ", typeid_of(type_of(letter))) // I love odin language!
     }

     // nice macros btw.
     #reverse for letter, i in text { // `letter` is rune(somewhat simmilar to char), `i` is index.
         fmt.println(i, ": ",letter, " type: ", typeid_of(type_of(letter))) // I love odin language!
     }

     // some things which i never got hold of... `slice`. odin makes it easier, nice.
     for letter in text[1:] { // `1:` means, to look at everything after the first character.
         fmt.println(letter) // e, l, l, o
     }

     // len() examples.
     for i in 0..<len(text) {
         if rune(text[i]) == "l" {
             continue // we dont need `l`.
         } else if rune(text[i]) == "!" {
             break
         } else {
             fmt.println(text[i]) // prints ascii.
             fmt.println( rune( text[i] )  // prints rune.
         }
     }

     // something I dont knwo the name of, i think they are called `tags`?
     outer: for i in 0..=10 {
         inner: for j in 0..=10 {
             if i == j { // we dont want i == j. we jump to outer.
                 continue outer
             } else if i+1 == j { // ooh, next i is j? so why not jump right into it?
                 continue inner
             } else {
                 fmt.println(i, ":", j)
             }
         }
     }
    // ---


    // view Directions enum for more info!
    Target_Direction := Directions.N // N is for north.

    #partial switch Target_Direction { // c like switch. #partial is when not all members need to be implemented, we skipped, `UP` and `DOWN` here.
        case .N: // it knows that we are talking about an enum.
            fmt.println("Must go north.")
        case .S: // it knows that we are talking about an enum.
            fmt.println("Must go south.")
        case .E: // it knows that we are talking about an enum.
            fmt.println("Must go east.")
        case .W: // it knows that we are talking about an enum.
            fmt.println("Must go west.")
        case:
            fmt.println("Must go either UP or DOWN.")
    }

    grade := 77.27
    switch grade { // also supports things like: 'A'..'M', 'a'..'m' whatever.
        case 0..=20:
            fmt.println("do an IQ test.")
        case 21..=49:
            fmt.println("fail....")
        case 50..=60:
            fmt.println("below averege.")
        case 61..=70:
            fmt.println("B")
        case 70..=80:
            fmt.println("A")
        case:
            fmt.println("Either A+, or A++. good!")
    }

    // ---

    defer fmt.println("this will print at the end.")
    defer {
        fmt.println("a")
        fmt.println("b")
        fmt.println("c")
    }

    // ---
    my_float:f32 = 22/7 // 3.141
    my_int  := i32(my_float) // casting
    my_i32  := cast(i32)my_float
    my_i64  := auto_cast my_float

    my_array  : [10]int // by default, all values are `0` (ZERO).
    my_array2 := [?]int { // when `?` is used, the compiler counts the items and auto assigns it a lenght.
        0,1,2,3,5,7,9,11,13,17
    }

    fmt.println(my_array2[1:]) // print first item, slice is a refrence, not a copy.

    // dynamic arrays, finally....
    numbers_up_untill_infiniti := make([dynamic]int)
    defer delete(numbers_up_untill_infiniti) // you have to delete it yourself
    // append some numbers.
    for x in 0..=100 {
        append(&numbers_up_untill_infiniti, x)
        // also print it, for some reason...
        fmt.println(numbers_up_untill_infiniti)
    }
    // pop(&numbers_up_untill_infiniti)
    // lets zero them all out...
    /* for x in 0..<len(numbers_up_untill_infiniti) {
     *     numbers_up_untill_infiniti[x] = 0
     * }
     */

    /* for x in numbers_up_untill_infiniti {
     *     // do something
     * }
     */

    // unordered_remove(&numbers_up_untill_infiniti, 0) // this will swap, [0] with [last] and pop(&numbers_up_untill_infiniti)
    append((&numbers_up_untill_infiniti, 999,1000,1001,1002,1003,10,11,12,13) // this will add all values into out list.
    slice.sort(numbers_up_untill_infiniti[:]) // this will create our infinite array a slice and sort it, not that we need it.

    // ---
    // maps

    words := make(map[int]string) // this will make a map, `int` -> `string`.
    words[0] = "Wood"
    words[1] = "Can"
    words[2] = "Plastic"
    words[3] = "Wash"
    words[4] = "Car"
    words[5] = "Language"

    fmt.println(words[0])

    people := make(map[string]Person)
    people["Bob"] = Person{"Bob", 12} // name="Bob", age=12

    languages := make(map[string]string, context.temp_allocator)
    languages["Python"] = "The BEST, WORST language every created."
    languages["C"]      = "OG"
    languages["c"]      = languages["C"] // just as an example.

    message, does_exist := languages["java"]
    if does_exist {
