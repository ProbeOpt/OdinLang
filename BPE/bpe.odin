package main

import "core:fmt"
import "core:strings"
import "core:unicode/utf8"

Pair :: struct {
    left:  rune,
    right: rune,
}

BPE :: struct {
    merges:   map[Pair]int,
    vocab:    map[rune]string,   // new_token_rune -> merged string
    next_id:  rune,
}

get_pairs :: proc(runes: []rune) -> map[Pair]int {
    pairs := make(map[Pair]int)
    for i := 0; i < len(runes)-1; i += 1 {
        left  := runes[i]
        right := runes[i+1]
        if left == 0 || right == 0 { continue }
        p := Pair{left = left, right = right}
        pairs[p] += 1
    }
    return pairs
}

most_frequent_pair :: proc(pairs: map[Pair]int) -> (Pair, int, bool) {
    if len(pairs) == 0 {
        return {}, 0, false
    }

    max_count := 0
    best_pair := Pair{}

    for p, count in pairs {
        if count > max_count {
            max_count = count
            best_pair = p
        }
    }
    return best_pair, max_count, max_count > 1
}

merge_text :: proc(runes: []rune, pair: Pair, new_token: rune) -> []rune {
    new_runes := make([dynamic]rune, 0, len(runes))

    i := 0
    for i < len(runes) {
        if i + 1 < len(runes) && runes[i] == pair.left && runes[i+1] == pair.right {
            append(&new_runes, new_token)
            i += 2
        } else {
            append(&new_runes, runes[i])
            i += 1
        }
    }
    return new_runes[:]
}

train_bpe :: proc(text: string, num_merges: int = 200) -> (BPE, string) {
    bpe := BPE{
        merges  = make(map[Pair]int),
        vocab   = make(map[rune]string),
        next_id = 'A',  // Start with uppercase A, B, C...
    }

    // Lowercase everything first
    lower_text := strings.to_lower(text)
    current := utf8.string_to_runes(lower_text)

    // Base vocab (lowercase characters)
    for r in current {
        if r >= 'a' && r <= 'z' || r == ' ' || r == '.' || r == '\'' || r == ',' {
            bpe.vocab[r] = utf8.runes_to_string([]rune{r})
        }
    }

    for merge_idx := 0; merge_idx < num_merges; merge_idx += 1 {
        pairs := get_pairs(current)
        if len(pairs) == 0 {
            delete(pairs)
            break
        }

        best_pair, count, ok := most_frequent_pair(pairs)
        delete(pairs)

        if !ok || count < 3 {
            break
        }

        if best_pair.left == 0 || best_pair.right == 0 {
            break
        }

        // Get next uppercase token
        new_token := bpe.next_id
        if new_token > 'Z' {
            break // Stop if we run out of uppercase letters
        }
        bpe.next_id += 1

        bpe.merges[best_pair] = merge_idx

        left_s  := utf8.runes_to_string([]rune{best_pair.left})
        right_s := utf8.runes_to_string([]rune{best_pair.right})
        bpe.vocab[new_token] = strings.concatenate([]string{left_s, right_s})

        new_current := merge_text(current, best_pair, new_token)
        delete(current)
        current = new_current

        if count >= 5 {
            fmt.printf("Merge %3d: '%s'+'%s' → %c (freq:%d)\n",
                       merge_idx, left_s, right_s, new_token, count)
        }
    }

    final_text := utf8.runes_to_string(current)
    delete(current)
    return bpe, final_text
}

main :: proc() {
    original := "The quick brown fox jumps over the lazy dog. This is a sample text for training a Markov chain model. Markov chains are useful for predicting the next token based on the previous one. In a simple language model, we can use word transitions to generate new text that resembles the training data. Hello world from Odin programming language. This is fun and educational. Let's see what the model generates next. The model learns patterns from the training data to predict likely next words."

    fmt.println("Original length:", len(original))

    bpe, compressed := train_bpe(original, num_merges = 180)

    fmt.println("\nCompressed length:", len(compressed))
    ratio := f64(len(compressed)) / f64(len(original)) * 100
    fmt.printf("Compression ratio: %.2f%% (lower is better)\n", ratio)

    fmt.println("\nPreview of compressed text (lowercase + UPPER new tokens):")
    preview_len := min(400, len(compressed))
    fmt.println(compressed[:preview_len])
    if len(compressed) > preview_len {
        fmt.println("...")
    }

    fmt.println("\nSample merges:")
    for id := 'A'; id < min('A'+20, bpe.next_id); id += 1 {
        if s, ok := bpe.vocab[id]; ok {
            fmt.printf("%c → %s\n", id, s)
        }
    }
}