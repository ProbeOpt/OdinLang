package main

import "core:fmt"
import "core:strings"
import "core:os"
import "core:unicode/utf8"
import "core:slice"

// example:
main :: proc() {
    // data is here!
    data := "The quick brown fox jumps over the lazy dog. This is a sample text for training a Markov chain model. Markov chains are useful for predicting the next token based on the previous one. In a simple language model, we can use word transitions to generate new text that resembles the training data. Hello world from Odin programming language. This is fun and educational. Let's see what the model generates next. The model learns patterns from the training data to predict likely next words."

    // splitting data into byte pairs!

    // // actual words:
    // words := strings.split(data, " ")

    // test: fmt.println(words) // ["The", "quick", ....]

    // // grouping with words! (we dont need this!)
    // pairs := make(map[string]string)
    // for i in 0..<(len(words)-1) {
    //     // test: fmt.println("l: ", words[i], " - r: ", words[i+1]) // l: is - r: fun
    //     if word_content, exists := pairs[words[i]]; exists {
    //         new_word := strings.concatenate({word_content, words[i+1]})
    //         pairs[new_word] = words[i+1]
    //     } else {
    //         pairs[words[i]] = words[i+1]
    //     }
    // }

    // "Th" => 15 // this measn, that Th occured 15 times.
    pairs := make(map[string]int)

    // grouping with byte-pairs:
    next_rune: for _char, i in data {
        if (i % 2 == 0) {
            // test: fmt.println("pair: ", _char, "|",rune(data[i+1])) // pair: T | h
            _l: rune // _char
            _r: rune // rune(data[i+1])

            if i+1 < len(data) {
                _l = _char
                _r = rune(data[i+1])
            } else {
                _l = _char
                _r =0
            }

            _pair_, _ := utf8.runes_to_string([]rune{_l,_r})
            if _, exists := pairs[_pair_]; exists {
                pairs[_pair_] += 1
            } else {
                pairs[_pair_] = 1
            }
         } else {
            continue next_rune
        }
    }

    pairs_slice := make([]Pair, len(pairs))
    idx := 0
    for k, v in pairs {
        pairs_slice[idx] = Pair{k, v}
        idx += 1
    }

    sort_pairs_by_count(&pairs_slice)

    // // test: print them (sorted), just for fun!
    // #reverse for x in pairs_slice {
    //     fmt.println(x.key, " -> ", x.value) // "e " -> 10
    // }

    // // test: print all of them
    // for x, y in pairs {
    //     fmt.println(x, " -> ", y)
    // }

    // now we select most occured, and repalce it with a NEW rune!
    ref_table := make(map[string]string)
    _has_more := true
    #reverse for x in pairs_slice {
        // top one is the most occured item!
        if x.value > 1 && _has_more { // only do it, if it occured MORE then 1 times, and only if unused runes has more!
            ref_table[x.key], _has_more = get_new_identifier()
            // test: fmt.println(x.key, " -> ", ref_table[x.key])
        }
    }

    // replacing things with things!
    new_data := data

    again: for x, y in ref_table {
        // test: fmt.println(x, "->", y)
        // Capture both return values: the new string and the allocation flag
        new_data, _ = strings.replace(new_data, x, y, -1)
        continue again
    }
    // test: fmt.println(new_data) // finally, BPE words, thank god!
    compressed_percentage := f64( int( len(new_data) ) / int( len(data) ) )
    fmt.println(" actual size: ",len(data)," | compresses size: ", len(new_data), " | compressed percentage: ", f64(compressed_percentage))
    fmt.println(new_data)

    //// # THIS WAS A SIDE DISTRACTION I GOT, A SMALL PREDICTION MODEL, NEVERMIND.
    //// <SUPPORTS ONLY WORK WORDS>

    // // now we have pairs
    // test: fmt.println(pairs["The"]) // quick
    // readbuf := [2048]u8{} // init a simple read buffer!
    // tread, err := os.read(os.stdin, readbuf[:])
    // read_word := ""
    // if err != nil {
    //     panic("bpe.odin: could not read!")
    // }
    // else {
    //     read_word = string(readbuf[:tread])
    // }
    // // test: fmt.println(read_word)

    // // distraction:
    // tok := "Markov"
    // completion := ""
    // next_tok: for x in 0..=10 {
    //     if next, exists := pairs[tok]; exists {
    //         completion = strings.concatenate({completion, " ", tok})
    //         tok = next
    //         continue next_tok
    //     } else {break}
    // }
    // fmt.println(completion)

    //// </SUPPORTS ONLY WORK WORDS>
}


//--// encoding //--//
ident_i := 0
unused_runes :=  []rune{
    '!', '@', '#', '$', '%', '^', '&', '*', '(', ')'
}   // using chinese, since no one uses them in text.

get_new_identifier :: proc() -> (string, bool) {
    if ident_i < len(unused_runes) {
        ident_i += 1
        return utf8.runes_to_string([]rune{unused_runes[ident_i-1]}), (ident_i > len(unused_runes)+1)
    } else { return "", false }
}

//--// pairs //--//
Pair :: struct {
    key:   string,
    value: int,
}

pair_less :: proc(lhs, rhs: Pair) -> bool {
    return lhs.value < rhs.value
}

// Function that takes a pointer to a slice and sorts it
sort_pairs_by_count :: proc(pairs_ptr: ^[]Pair) {
    // Dereference the pointer to access the slice
    pairs := pairs_ptr^

    // Sort the slice using the custom comparator
    slice.sort_by(pairs, pair_less)
}