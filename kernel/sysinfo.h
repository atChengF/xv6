struct sysinfo {
  uint64 freemem;   // amount of free memory (bytes) // 这个不太好处理，按字节算，还是按页为单位来计算呢？
  uint64 nproc;     // number of process // 这个好处理
};

void sysinfo_init();
uint64 sys_sysinfo();


void add_mem(uint64 num);

void sub_mem(uint64 num);
void sub_nproc(uint64 num);

void add_nproc(uint64 num);