#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"
#include "kernel/fs.h"
#include "kernel/fcntl.h"

int main(int argc, char *argv[])
{
    int fd = open("a", O_RDONLY);
    struct dirent de;
    struct stat st;
    memset(de.name, 0, 14);
    fstat(fd, &st);
    printf("%d \n", st.type);
    while(read(fd, &de, sizeof(de)) != 0){
        if(de.inum == 0) continue;
        fprintf(1, "%d %d %s \n", strlen(de.name), de.inum, de.name);
    }
    
    exit(0);
}