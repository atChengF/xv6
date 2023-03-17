struct buf {
  int valid;   // has data been read from disk?
  int disk;    // does disk "own" buf?
  uint dev;    // 设备号
  uint blockno; // 块号
  struct sleeplock lock; // 控制并发
  uint refcnt;      // 引用次数
  struct buf *prev; // LRU cache list
  struct buf *next; // 下一个
  uchar data[BSIZE]; // 缓存内容
};

