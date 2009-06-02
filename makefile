TARGET = bin/encoder
CC     = cc
SRC    = src/encoder.m
OBJ    = $(SRC:.m=.o)
CFLAGS = -W
RM     = rm -rf


make: $(OBJ)
	$(CC) -o $(TARGET) $^ -framework QTKit -framework Foundation -framework AppKit

all: make

clean:
	$(RM) $(OBJ)

fclean: clean
	$(RM) $(TARGET)

re: fclean make
