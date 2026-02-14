# Makefile for mkarchiso colorful C wrapper
# SPDX-License-Identifier: GPL-3.0-or-later

CC = gcc
CFLAGS = -Wall -Wextra -O2 -std=c11
TARGET = mkarchiso_wrapper
SOURCE = mkarchiso.c
PREFIX = /usr/local

.PHONY: all clean install uninstall

all: $(TARGET)

$(TARGET): $(SOURCE)
	@echo -e "\033[1;36m[BUILD]\033[0m Compiling colorful mkarchiso wrapper..."
	$(CC) $(CFLAGS) -o $(TARGET) $(SOURCE)
	@echo -e "\033[1;32m[SUCCESS]\033[0m ✓ Build complete! Binary: $(TARGET)"

clean:
	@echo -e "\033[1;33m[CLEAN]\033[0m Removing build artifacts..."
	rm -f $(TARGET)
	@echo -e "\033[1;32m[SUCCESS]\033[0m ✓ Clean complete!"

install: $(TARGET)
	@echo -e "\033[1;36m[INSTALL]\033[0m Installing $(TARGET) to $(PREFIX)/bin/..."
	install -Dm755 $(TARGET) $(PREFIX)/bin/$(TARGET)
	@echo -e "\033[1;32m[SUCCESS]\033[0m ✓ Installed to $(PREFIX)/bin/$(TARGET)"

uninstall:
	@echo -e "\033[1;33m[UNINSTALL]\033[0m Removing $(TARGET) from $(PREFIX)/bin/..."
	rm -f $(PREFIX)/bin/$(TARGET)
	@echo -e "\033[1;32m[SUCCESS]\033[0m ✓ Uninstall complete!"

help:
	@echo -e "\033[1;35mAcreetionOS mkarchiso Wrapper - Build System\033[0m"
	@echo ""
	@echo -e "\033[1;36mTargets:\033[0m"
	@echo "  all       - Build the mkarchiso wrapper (default)"
	@echo "  clean     - Remove build artifacts"
	@echo "  install   - Install to $(PREFIX)/bin/"
	@echo "  uninstall - Remove from $(PREFIX)/bin/"
	@echo "  help      - Show this help message"
	@echo ""
	@echo -e "\033[1;36mUsage:\033[0m"
	@echo "  make              # Build the wrapper"
	@echo "  make install      # Install (may require sudo)"
	@echo "  make clean        # Clean up"
