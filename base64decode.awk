# base64decode.awk
#
# Introduction
# ============
# Decode Base64-encoded strings.
#
# Invocation
# ==========
# Typically you run the script like this:
#
#     $ awk -f base64decode.awk [file1 [file2 [...]]] > output

# The script implements Base64 decoding, based on RFC 3548:
#
# https://tools.ietf.org/html/rfc3548

# create our lookup table
BEGIN {
    # load symbols based on the alphabet
    for (i=0; i<26; i++) {
        BASE64[sprintf("%c", i+65)] = i
        BASE64[sprintf("%c", i+97)] = i+26
    }
    # load our numbers
    for (i=0; i<10; i++) {
        BASE64[sprintf("%c", i+48)] = i+52
    }
    # and finally our two additional characters
    BASE64["+"] = 62
    BASE64["/"] = 63
    # also add in our padding character
    BASE64["="] = -1
}

# The main function to decode Base64 data.
#
# Arguments:
# * encoded - the Base64 string
# * result - an array to return the binary data in
#
# We exit on error. For other use cases this should be changed to
# returning an error code somehow.
function base64decode(encoded, result) {
    n = 1
    while (length(encoded) >= 4) {
        g0 = BASE64[substr(encoded, 1, 1)]
        g1 = BASE64[substr(encoded, 2, 1)]
        g2 = BASE64[substr(encoded, 3, 1)]
        g3 = BASE64[substr(encoded, 4, 1)]
        if (g0 == "") {
            printf("Unrecognized character %c in Base 64 encoded string\n",
                   g0) >> "/dev/stderr"
            exit 1
        }
        if (g1 == "") {
            printf("Unrecognized character %c in Base 64 encoded string\n",
                   g1) >> "/dev/stderr"
            exit 1
        }
        if (g2 == "") {
            printf("Unrecognized character %c in Base 64 encoded string\n",
                   g2) >> "/dev/stderr"
            exit 1
        }
        if (g3 == "") {
            printf("Unrecognized character %c in Base 64 encoded string\n",
                   g3) >> "/dev/stderr"
            exit 1
        }

        # we don't have bit shifting in AWK, but we can achieve the same
        # results with multiplication, division, and modulo arithmetic
        result[n++] = (g0 * 4) + int(g1 / 16)
        if (g2 != -1) {
            result[n++] = ((g1 * 16) % 256) + int(g2 / 4)
            if (g3 != -1) {
                result[n++] = ((g2 * 64) % 256) + g3
            }
        }

        encoded = substr(encoded, 5)
    }
    if (length(encoded) != 0) {
        printf("Extra characters at end of Base 64 encoded string: \"%s\"\n",
               encoded) >> "/dev/stderr"
        exit 1
    }
}

# our main text processing
{
    # Decode what we have read.
    base64decode($0, result)

    # Output the decoded string.
    #
    # We cannot output a NUL character using BusyBox AWK. See:
    # https://stackoverflow.com/a/32302711
    #
    # So we collect our result into an octal string and use the
    # shell "printf" command to create the actual output. 
    # 
    # This also helps with gawk, which gets confused about the
    # non-ASCII output if localization is used unless this is
    # set via LC_ALL=C or via "--characters-as-bytes".
    printf_str = ""
    for (i=1; i in result; i++) {
        printf_str = printf_str sprintf("\\%03o", result[i])
        if (length(printf_str) >= 1024) {
            system("printf '" printf_str "'")
            printf_str = ""
        }
        delete result[i]
    }
    system("printf '" printf_str "'")
}
