#include "kernel/types.h"
#include "user/user.h"

int main(int argc, char *argv[])
{
    
    // p1 p -> c , p2 c -> p wirte
    int p1[2], p2[2];
    pipe(p1);
    pipe(p2);
    char c[1];
    
    int pid = fork();
    if (pid == 0) {
       
        read(p1[0], c, 1);
        if(c[0] == 'a') printf("%d: received ping\n", getpid());
       
        write(p2[1], c, 1);
        
        close(p1[0]);
        close(p2[0]);
        close(p1[1]);
        close(p2[1]);

        exit(0);
        
    } else {
        c[0] = 'a';
        write(p1[1], c, 1);
        read(p2[0], c, 1);
        sleep(1);
        if(c[0] == 'a') printf("%d: received pong\n", getpid());

        close(p1[0]);
        close(p2[0]);
        close(p1[1]);
        close(p2[1]);

        exit(0);
    }
}