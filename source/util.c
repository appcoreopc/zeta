#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "util.h"

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

