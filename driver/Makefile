CC      = gcc
CXX     = g++
CFLAGS  = -Wall -Wextra -O2 -DTITAN_SIM_BUILD
CXXFLAGS= -Wall -Wextra -O2 -std=c++17 -DTITAN_SIM_BUILD
PYTHON  = python3
TCC     = ../compiler/titan_compiler.py
KERNEL  = ../compiler/kernels/matmul.py

BUILD   = build

all: legacy titan_x6

# ----------------------------------------------------------------------------
# Titan X6 software stack (Phase 5): driver + runtime + compiled kernels
# ----------------------------------------------------------------------------
titan_x6: $(BUILD)/test_driver.elf $(BUILD)/test_matmul.elf kernels

$(BUILD):
	mkdir -p $(BUILD)

$(BUILD)/titan_x6_drv.o: titan_x6_drv.c titan_x6_drv.h titan_x6_gpu_model.h | $(BUILD)
	$(CC) $(CFLAGS) -c $< -o $@

$(BUILD)/titan_x6_gpu_model.o: titan_x6_gpu_model.c titan_x6_gpu_model.h titan_x6_isa.h titan_x6_drv.h | $(BUILD)
	$(CC) $(CFLAGS) -c $< -o $@

$(BUILD)/titan_runtime.o: titan_runtime.cpp titan_runtime.h titan_x6_drv.h titan_x6_isa.h | $(BUILD)
	$(CXX) $(CXXFLAGS) -c $< -o $@

$(BUILD)/test_matmul.o: test_matmul.cpp titan_runtime.h | $(BUILD)
	$(CXX) $(CXXFLAGS) -c $< -o $@

$(BUILD)/test_matmul.elf: $(BUILD)/titan_x6_drv.o $(BUILD)/titan_x6_gpu_model.o \
                          $(BUILD)/titan_runtime.o $(BUILD)/test_matmul.o
	$(CXX) $(CXXFLAGS) -o $@ $^ -lm

# Mission 1 driver checkpoint: pure-C init + VRAM allocation test
$(BUILD)/test_driver.o: test_driver.c titan_x6_drv.h | $(BUILD)
	$(CC) $(CFLAGS) -c $< -o $@

$(BUILD)/test_driver.elf: $(BUILD)/titan_x6_drv.o $(BUILD)/titan_x6_gpu_model.o \
                          $(BUILD)/test_driver.o
	$(CC) $(CFLAGS) -o $@ $^ -lm

.PHONY: driver-test
driver-test: $(BUILD)/test_driver.elf
	./$(BUILD)/test_driver.elf

# --- kernels compiled by the Titan Compute Compiler -------------------------
kernels: $(BUILD)/matmul_scalar.tbin $(BUILD)/matmul_wmma_i8.tbin $(BUILD)/matmul_wmma_fp8.tbin

$(BUILD)/matmul_scalar.tbin: $(KERNEL) $(TCC) | $(BUILD)
	$(PYTHON) $(TCC) $(KERNEL) -o $@ --backend scalar

$(BUILD)/matmul_wmma_i8.tbin: $(KERNEL) $(TCC) | $(BUILD)
	$(PYTHON) $(TCC) $(KERNEL) -o $@ --backend tensor --dtype int8

$(BUILD)/matmul_wmma_fp8.tbin: $(KERNEL) $(TCC) | $(BUILD)
	$(PYTHON) $(TCC) $(KERNEL) -o $@ --backend tensor --dtype fp8

# --- run --------------------------------------------------------------------
test: titan_x6
	./$(BUILD)/test_driver.elf
	$(PYTHON) ../compiler/test_compiler_isa.py
	$(PYTHON) $(TCC) --selftest
	./$(BUILD)/test_matmul.elf $(BUILD)

# ----------------------------------------------------------------------------
# Legacy Titan X5 firmware demo
# ----------------------------------------------------------------------------
legacy: demo.elf

demo.elf: titan_x5_driver.o demo.o
	$(CC) -Wall -Wextra -O2 -o demo.elf titan_x5_driver.o demo.o

titan_x5_driver.o: titan_x5_driver.c titan_x5_driver.h
	$(CC) -Wall -Wextra -O2 -c titan_x5_driver.c

demo.o: demo.c titan_x5_driver.h
	$(CC) -Wall -Wextra -O2 -c demo.c

clean:
	rm -rf $(BUILD) *.o demo.elf

.PHONY: all titan_x6 kernels test legacy clean
