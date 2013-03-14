

typedef struct
{
	uint32_t priority;
	uint32_t endT;
	uint32_t next;
} timeblkval;

typedef struct
{
	uint32_t size;
	uint32_t free;
	timeblkval *data;
} timeblk;

void TBdel(timeblk *blk);
void TBgrow(timeblk *blk);
uint32_t TBgetFree(timeblk *blk);
void TBinsert(timeblk *blk, uint32_t startT, uint32_t endT, uint32_t priority);
void TBset(timeblk *blk, uint32_t startT, uint32_t endT, uint32_t priority);
timeblk *TBnew();
void TBPrint(timeblk *blk);
