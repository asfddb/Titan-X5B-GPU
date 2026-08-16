# ============================================================================
# Copyright (c) 2026 Adhiraj
#
# This file is part of the Titan X6 GPU project.
#
# Licensed under CERN-OHL-S-2.0.
# ============================================================================
#
# DOOM frame path on the Titan X6.
#
#   make test     build and run the kernel self-test (no DOOM needed)
#   make kernel   just regenerate titan_blit.tbin
#   make clean
#
# Flags match driver/Makefile so the driver, GPU model and runtime are built
# exactly as their own tests build them. TITAN_SIM_BUILD links the whole stack
# into one process while still going through the ioctl entry points.
#
# Builds on Windows with mingw32-make and on Linux/Raspberry Pi with make.
# On a Pi 1:  make test TITAN_VRAM_MB=16 ARCHFLAGS='-mcpu=arm1176jzf-s -mfpu=vfp'

CC  = gcc
CXX = g++

# Host RAM the GPU model calloc()s as simulated VRAM. The blit needs well
# under 1 MiB; the stock 256 MiB is simply the default device size.
TITAN_VRAM_MB ?= 256

# Extra target flags, e.g. -mcpu=arm1176jzf-s on a Pi 1.
ARCHFLAGS ?=

DEFS     = -DTITAN_SIM_BUILD -DTITAN_VRAM_MB=$(TITAN_VRAM_MB)
CFLAGS   = -Wall -Wextra -O2 $(DEFS) $(ARCHFLAGS)
CXXFLAGS = -Wall -Wextra -O2 -std=c++17 $(DEFS) $(ARCHFLAGS)

DRV   = ../driver
BUILD = build

# Windows has no mkdir -p, no rm -rf, and needs the .exe suffix. Linux has no
# `if not exist`. Keep the divergence in one place.
ifeq ($(OS),Windows_NT)
  PYTHON ?= python
  EXE    := .exe
  MKDIR   = if not exist "$(BUILD)" mkdir "$(BUILD)"
  CLEAN   = if exist "$(BUILD)" rmdir /s /q "$(BUILD)"
else
  PYTHON ?= python3
  EXE    :=
  MKDIR   = mkdir -p $(BUILD)
  CLEAN   = rm -rf $(BUILD)
endif

STACK_OBJ = $(BUILD)/titan_x6_drv.o $(BUILD)/titan_x6_gpu_model.o \
            $(BUILD)/titan_runtime.o

TEST = $(BUILD)/test_blit$(EXE)
TBIN = $(BUILD)/titan_blit.tbin

.PHONY: all test kernel clean
all: test

# --- the Titan software stack ----------------------------------------------
$(BUILD)/titan_x6_drv.o: $(DRV)/titan_x6_drv.c
	@$(MKDIR)
	$(CC) $(CFLAGS) -c $< -o $@

$(BUILD)/titan_x6_gpu_model.o: $(DRV)/titan_x6_gpu_model.c
	@$(MKDIR)
	$(CC) $(CFLAGS) -c $< -o $@

$(BUILD)/titan_runtime.o: $(DRV)/titan_runtime.cpp
	@$(MKDIR)
	$(CXX) $(CXXFLAGS) -c $< -o $@

# --- DOOM frame path -------------------------------------------------------
$(BUILD)/titan_video.o: titan_video.c titan_video.h $(DRV)/titan_runtime.h
	@$(MKDIR)
	$(CC) $(CFLAGS) -c $< -o $@

$(BUILD)/test_blit.o: test_blit.c titan_video.h
	@$(MKDIR)
	$(CC) $(CFLAGS) -c $< -o $@

# The kernel is emitted straight from the encoding in driver/titan_x6_isa.h,
# so compiler/titan_compiler.py is not needed to build DOOM.
$(TBIN): gen_blit_kernel.py
	@$(MKDIR)
	$(PYTHON) gen_blit_kernel.py $@

kernel: $(TBIN)

# g++ links: the runtime is C++.
$(TEST): $(STACK_OBJ) $(BUILD)/titan_video.o $(BUILD)/test_blit.o
	$(CXX) $(CXXFLAGS) -o $@ $^ -lm

test: $(TEST) $(TBIN)
	$(TEST) $(TBIN)

clean:
	@$(CLEAN)
