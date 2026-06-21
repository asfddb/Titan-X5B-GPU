CC=gcc
CFLAGS=-Wall -Wextra -O2

all: demo.elf

demo.elf: titan_x5_driver.o demo.o
	$(CC) $(CFLAGS) -o demo.elf titan_x5_driver.o demo.o

titan_x5_driver.o: titan_x5_driver.c titan_x5_driver.h
	$(CC) $(CFLAGS) -c titan_x5_driver.c

demo.o: demo.c titan_x5_driver.h
	$(CC) $(CFLAGS) -c demo.c

clean:
	rm -f *.o demo.elf
