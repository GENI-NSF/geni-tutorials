CC = gcc
CFLAGS = 
PKTLST_OBJECTS = packetFunctions.o pingPlusListener.o 
PKTSND_OBJECTS = packetFunctions.o pingPlus.o

all : pingPlusListener pingPlus

pingPlusListener : $(PKTLST_OBJECTS)
	$(CC) $(CFLAGS) $(PKTLST_OBJECTS) -o pingPlusListener

pingPlus : $(PKTSND_OBJECTS)
	$(CC) $(CFLAGS) $(PKTSND_OBJECTS) -o pingPlus

%.o : %.c packetFunction.h
	$(CC) $(CFLAGS) -c $<

clean :
	rm -f *.o pingPlusListener pingPlus
