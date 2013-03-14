
#import "common.h"
#import "defines.h"

#import "timeitem.h"


void TBdel(timeblk *blk)
{
	free(blk->data);
	blk->size = 0;
	delete blk;
}

void TBgrow(timeblk *blk)
{
	uint32_t size = blk->size+0x15;
	blk->data = (timeblkval *)realloc(blk->data, sizeof(timeblkval)*size);
	blk->size = size;
}

uint32_t TBgetFree(timeblk *blk)
{
	uint32_t free = blk->free;
	if(blk->free >= blk->size)
	{
		TBgrow(blk);
	}
	blk->free++;
	return free;
}

void TBinsert(timeblk *blk, uint32_t startT, uint32_t endT, uint32_t priority)
{
	timeblkval *data = blk->data;
	
	if(startT <= data[0].endT)
		startT = 0;
	if(endT <= data[0].endT)
		return;
	
	int ptr = 0, next;
	//uint32_t nEndT; //nStartT = data[ptr].endT, 
	for(; next = data[ptr].next; ptr = next)//, nStartT = nEndT)
	{
		uint32_t nEndT = data[next].endT;
		uint32_t nPriority = data[next].priority;
		
		if(startT > nEndT)
		{
			continue;
		}
		if(startT == nEndT)
		{
			startT = 0;
			continue;
		}
		if(priority > nPriority)
		{
			continue;
		}
		
		if(startT)
		{
			uint32_t free = TBgetFree(blk);
			data = blk->data;
			
			data[ptr].next = free;
			data[free].next = next;
			data[free].priority = nPriority;
			data[free].endT = startT;
			startT = 0;
			ptr = free;
			//continue;
		}
		
		if(endT < nEndT)
		{
			uint32_t free = TBgetFree(blk);
			data = blk->data;
			
			data[ptr].next = free;
			data[free].next = next;
			data[free].priority = priority;
			data[free].endT = endT;
			ptr = free;
			return;
		}
		else
		{
			data[next].priority = priority;
		}
		
	}
	
	
	
}

/*
void TBPrint(timeblk *blk)
{
	timeblkval *data = blk->data;
	uint32_t idx=0;
	NSLog(@"Starting at %d", data[idx].endT);
	while(idx=data[idx].next)
	{
		NSLog(@"Priority %08x until %d", data[idx].priority, data[idx].endT);
	}
}
*/

void TBset(timeblk *blk, uint32_t startT, uint32_t endT, uint32_t priority)
{
	timeblkval *data = blk->data;
	
	data[0].endT = startT;
	data[0].priority = 0; //nothing overrides
	data[0].next = 1;
	
	data[1].endT = endT;
	data[1].priority = priority;
	data[1].next = 0;
	blk->free = 2;
	
}

timeblk *TBnew()//uint32_t startT, uint32_t endT, uint32_t priority)
{
	timeblk *blk = new timeblk;
	uint32_t size = 0x10;
	timeblkval *data = (timeblkval *)malloc(sizeof(timeblkval)*size);
	blk->data = data;
	blk->size = size;
	blk->free = 0;

	return blk;
}

 
/*
void MergeTimeitem_continuous(timeitem *list, timeitem *merge)
{
	NSLog(@"merging the following:");
	printTimeitem(merge);
	return;
		
	uint32_t startT = merge->endT;
	merge = (timeitem*) merge->next;
	for(int i=0; merge && list; i++)
	{
		NSLog(@"%d %x %x", i, list, merge);
		insertTimeitem(list, startT, merge->endT, merge->prior);
		startT = merge->endT;
		merge = (timeitem*) merge->next;
	}
	NSLog(@"done");
}
*/

