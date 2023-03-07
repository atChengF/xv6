#include "sysinfo.h"
#include "syscall.h"
#include "spinlock.h"
#include "types.h"
#include "riscv.h"
#include "proc.h"

struct sysinfo * sysinfo;
struct spinlock info_lk;
extern int argaddr(int n, uint64 *ip);
extern int copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len);
struct proc;
void sysinfo_init(){
    initlock(&info_lk, "info_lk");
}

uint64 sys_sysinfo(){
    uint64 addr;
    if(argaddr(0, &addr) < 0) return -1;
    struct proc* p = myproc();
    if(copyout(p->pagetable, addr, (char *) sysinfo, sizeof(sysinfo)) < 0) return -1; 
    return 0;
}


void add_mem(uint64 num){
    acquire(info_lk);
    sysinfo->freemem += num;
    release(info_lk);
}

void sub_mem(uint64 num){
    acquire(info_lk);
    sysinfo->freemem -= num;
    release(info_lk);
}

void sub_nproc(uint64 num){
    acquire(info_lk);
    sysinfo->nproc -= num;
    release(info_lk);
}

void add_nproc(uint64 num){
    acquire(info_lk);
    sysinfo->nproc += num;
    release(info_lk);
}
