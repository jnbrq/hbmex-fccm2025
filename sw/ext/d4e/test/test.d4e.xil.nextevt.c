#include <fcntl.h>
#include <unistd.h>
#include <sys/stat.h>
#include <sys/types.h>

#include <stdint.h>
#include <stdlib.h>
#include <stdio.h>

int main(int argc, char **argv) {
    if (argc != 2) {
        printf("usage: %s <dev_file>\n", argv[0]);
        return EXIT_FAILURE;
    }

    const char *devfpath = argv[1];

    uint32_t data;

    {
        int fd = open(devfpath, O_RDONLY);
        if (fd < 0) {
            perror("open");
            return EXIT_FAILURE;
        }
        read(fd, &data, 4);
        close(fd);
    }

    printf("next event = 0x%x\n", data);

    return EXIT_SUCCESS;
}

