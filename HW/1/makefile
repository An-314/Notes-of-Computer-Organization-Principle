# Compiler & flags
CC       := gcc
CFLAGS   := -std=c11 -Wall -Wextra -Wconversion -Wsign-conversion -O2
CPPFLAGS := -Iinclude
LDFLAGS  :=

# Sources
SRC_LIB   := $(wildcard src/*.c)
MAIN      := main.c
HEADERS   := $(wildcard include/*.h)

# Build dirs
BUILD_DIR := builds

# --- Auto-discover tests ---
TEST_SRCS := $(wildcard tests/test_*.c)
TEST_BINS := $(patsubst tests/%.c,$(BUILD_DIR)/%,$(TEST_SRCS))

# Default target
.DEFAULT_GOAL := all

# Aggregate targets
all: $(BUILD_DIR)/demo tests

# Build demo executable
$(BUILD_DIR)/demo: $(SRC_LIB) $(MAIN) $(HEADERS) | $(BUILD_DIR)
	$(CC) $(CPPFLAGS) $(CFLAGS) $(MAIN) $(SRC_LIB) -o $@ $(LDFLAGS)

# Build all test executables
tests: $(TEST_BINS)

# Pattern rule to build each test_xxx
$(BUILD_DIR)/test_%: tests/test_%.c $(SRC_LIB) $(HEADERS) | $(BUILD_DIR)
	$(CC) $(CPPFLAGS) $(CFLAGS) $^ -o $@ $(LDFLAGS)

# One-click run all tests
test: $(TEST_BINS)
	@set -e; \
	for t in $^; do \
	  echo "== Running $${t} =="; \
	  "$${t}"; \
	done; \
	echo "All tests passed."

# Ensure build dir exists (order-only prerequisite)
$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

clean:
	rm -rf $(BUILD_DIR)

.PHONY: all tests test clean clangd

# Generate compile_commands.json for clangd
clangd:
	bear -- make -j $(BUILD_DIR)/demo $(TEST_BINS)
