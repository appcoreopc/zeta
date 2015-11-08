#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "util.h"

/**
MurmurHash2, 64-bit version for 64-bit platforms
All hail Austin Appleby
*/
uint64_t murmur_hash_64a(const void* key, size_t len, uint64_t seed)
{
    const uint64_t m = 0xc6a4a7935bd1e995;
    const int r = 47;

    uint64_t h = seed ^ (len * m);

    uint64_t* data = (uint64_t*)key;
    uint64_t* end = data + (len/8);

    while (data != end)
    {
        uint64_t k = *data++;

        k *= m;
        k ^= k >> r;
        k *= m;

        h ^= k;
        h *= m;
    }

    uint8_t* tail = (uint8_t*)data;

    switch (len & 7)
    {
        case 7: h ^= ((uint64_t)tail[6]) << 48;
        case 6: h ^= ((uint64_t)tail[5]) << 40;
        case 5: h ^= ((uint64_t)tail[4]) << 32;
        case 4: h ^= ((uint64_t)tail[3]) << 24;
        case 3: h ^= ((uint64_t)tail[2]) << 16;
        case 2: h ^= ((uint64_t)tail[1]) << 8;
        case 1: h ^= ((uint64_t)tail[0]);
                h *= m;
        default:
        break;
    }

    h ^= h >> r;
    h *= m;
    h ^= h >> r;

    return h;
}

/**
Read a text file into a malloc'ed string
*/
char* read_file(const char* file_name)
{
    printf("reading file \"%s\"\n", file_name);

    FILE* file = fopen(file_name, "r");

    if (!file)
    {
        printf("failed to open file\n");
        return NULL;
    }

    // Get the file size in bytes
    fseek(file, 0, SEEK_END);
    size_t len = ftell(file);
    fseek(file, 0, SEEK_SET);

    printf("%ld bytes\n", len);

    char* buf = malloc(len+1);

    // Read into the allocated buffer
    int read = fread(buf, 1, len, file);

    if (read != len)
    {
        printf("failed to read file");
        return NULL;
    }

    // Add a null terminator to the string
    buf[len] = '\0';

    // Close the input file
    fclose(file);

    return buf;
}

/**
Read a line from standard input into a malloc'ed string
*/
char* read_line()
{
    size_t cap = 256;
    size_t len = 0;
    char* buf = malloc(cap+1);

    for (;;)
    {
        char ch = getchar();

        if (ch == '\0')
            return 0;

        if (ch == '\n')
            break;

        buf[len] = ch;
        len++;

        if (len == cap)
        {
            cap *= 2;
            char* new_buf = malloc(cap+1);
            strncpy(new_buf, buf, len);
            free(buf);
            buf = new_buf;
        }
    }

    // Add a null terminator to the string
    buf[len] = '\0';

    return buf;
}

