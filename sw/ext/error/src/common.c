#include <error/common.h>

#include <stdlib.h>
#include <stdio.h>

void e_print(const char *msg)
{
    fprintf(stderr, "%s\n", msg);
}

void e_die()
{
    exit(EXIT_FAILURE);
}

