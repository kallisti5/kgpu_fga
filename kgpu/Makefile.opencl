SRCFOLDER := src/
INCLUDEFOLDER := inc/
OBJFOLDER := obj/

SRCFILES := $(wildcard src/*.c)
CUDAFILES := $(wildcard src/*.cu)

CC := gcc
NVIDIA := nvcc
KGPUFLAGS := -O2 -D__KGPU__

obj-m += kgpu.o
ccflags-y += -I`pwd`/include
kgpu-objs := src/main.o src/kgpu_kutils.o src/kgpu_log.o

all:
	@echo "Aqui"

src/kgpu:
	make -C /lib/modules/$(shell uname -r)/build M=`pwd` modules ccflags-y=$(ccflags-y)
	$(if $(BUILD_DIR), cp kgpu.ko $(BUILD_DIR)/ ) 

src/helper: src/kgpu_log
	$(CC) $(KGPUFLAGS) -c src/helper.c $(ccflags-y)
	$(CC) $(KGPUFLAGS) -c src/service.c $(ccflags-y)
	$(NVIDIA) $(KGPUFLAGS) -c -arch=sm_20 src/gpuops.cu $(ccflags-y)
	$(NVIDIA) -link $(KGPUFLAGS) -arch=sm_20 service.o helper.o kgpu_log_user.o gpuops.o -o helper -ldl
	$(if $(BUILD_DIR), cp helper $(BUILD_DIR)/ )

src/kgpu_log:
	$(CC) $(KGPUFLAGS) -c src/kgpu_log.c -o kgpu_log_user.o $(ccflags-y)
	ar -rcs kgpu_log.a kgpu_log_user.o
	$(if $(BUILD_DIR), cp kgpu_log.a $(BUILD_DIR)/ )

clean:
	make -C /lib/modules/$(shell uname -r)/build M=`pwd` clean
	rm -f helper
	rm -f kgpu_log.a
	rm -f *.o
