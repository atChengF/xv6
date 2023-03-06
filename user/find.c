#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"
#include "kernel/fs.h"
#include "kernel/fcntl.h"

void find(const char *path, const char *file)
{
    char buf[512], *p;
    int fd = open(path, O_RDONLY);
    if(fd < 0){
        fprintf(2, "err : open \n");
        return;
    } 
    struct stat st;
    struct dirent de;
    const char * p1 = path + strlen(path) - strlen(file);
    if(fstat(fd, &st) < 0){
        fprintf(2 ,"err : fstat \n");
        close(fd);
        return;
    } 

   switch(st.type){
        case T_FILE:
            if(strcmp(p1, file) == 0) printf("%s \n", path);
            break;
        case T_DIR:
            if(strlen(path) + 1 + DIRSIZ + 1 > sizeof buf){
                printf("ls: path too long\n");
                break;
            }
            strcpy(buf, path);
            p = buf + strlen(buf);
            *p ++ = '/';
            while(read(fd, &de, sizeof(de)) == sizeof(de)){
                if(de.inum == 0)
                    continue;
                if(strcmp(".", de.name) == 0) continue;
                if(strcmp("..", de.name) == 0) continue;
                memmove(p, de.name, DIRSIZ);
                p[DIRSIZ] = 0;
                if(stat(buf, &st) < 0){
                    printf("ls: cannot stat %s\n", buf);
                    continue;
                }
                find(buf, file);
            }
            break;
    }
    close(fd);
    return;
}

int main(int argc, char *argv[])
{
    if (argc != 3)
    {
        fprintf(2, "Usage: find <dir> <file>\n");
        exit(1);
    }

    find(argv[1], argv[2]);

    exit(0);
}