CROSS_COMPILE?=

LIBDIR_APP_LOADER?=app_loader/lib
INCDIR_APP_LOADER?=app_loader/include
BINDIR?=

CFLAGS+= -Wall -I$(INCDIR_APP_LOADER) -D__DEBUG -O2 -mtune=cortex-a8 -march=armv7-a
LDFLAGS+=-L$(LIBDIR_APP_LOADER) -lprussdrv -lpthread
OBJDIR=obj
TARGET=stepperxy



_OBJ = stepperxy.o
OBJ = $(patsubst %,$(OBJDIR)/%,$(_OBJ))


$(OBJDIR)/%.o: %.c 
	@mkdir -p obj
	$(CROSS_COMPILE)gcc $(CFLAGS) -c -o $@ $< 

$(TARGET): $(OBJ) stepperxy.bin
	$(CROSS_COMPILE)gcc $(CFLAGS) -o $@ $< $(LDFLAGS)


stepperxy.bin: stepperxy.p
	../pru2/am335x_pru_package/pru_sw/utils/pasm  -b stepperxy.p
	
	
	
.PHONY: clean

clean:
	rm -rf $(OBJDIR)/ *~  $(INCDIR_APP_LOADER)/*~  $(TARGET) *.bin
