#include "kernel/types.h"
#include "user/user.h"

int main(int argc, char * argv[]){
    if (argc != 1) {
        fprintf(2, "usage: no args needed");
        exit(0);
    }

    int p[2];
    pipe(p);


    if(fork() != 0) {
        //依次写入 2 - 35
        for(int i = 2; i <= 35; i ++) {
            write(p[1], &i, 4);
        }
        close(p[0]);
        close(p[1]);
        int status;
        wait(&status);

        exit(0);

    } else {
        while(1){
            //关闭 父节点的 读文件描述符号
            close(p[1]);
            int rfd = p[0];
            pipe(p);
            //判断fork()的条件
            int prime;
            int cnt = read(rfd, &prime, 4);
            if(cnt == 0){
                close(rfd);
                close(p[0]);
                close(p[1]);
                exit(0);
            } 
            fprintf(1, "prime %d \n", prime);
            if(fork() != 0) {
                //父节点处理，就是当前节点
                int input;
                cnt = read(rfd, &input, 4);
                while(cnt != 0) {
                    if(input % prime != 0) write(p[1], &input, 4);
                    cnt = read(rfd, &input, 4);
                }

                close(rfd);
                close(p[0]);
                close(p[1]);

                int status;
                wait(&status);
                exit(0);

            }
            //子节点处理
            //关闭 rfd
            close(rfd);
            //while循环进入下一个子节点
        }
        
    }


}