# ===========================================================================
# OpenGL-ASM NASM Project
# ===========================================================================

# Project configuration
PROJECT     := GLASM
SRC_DIR     := src
BUILD_DIR   := build

# Source files
SOURCES     := main.asm
INC_FILES   :=
MAC_FILES   :=

# ===========================================================================
# OS-specific configuration
# ===========================================================================

ifdef SystemRoot
    # Windows-specific settings
		# WARN: Windows platform was not tested
    ASM_DEFINE  := -D WINDOWS
    ASMFLAGS    := -f win64 -I$(SRC_DIR)/
    EXE_EXT     := .exe
		LINKFLAGS   := -mconsole -lglfw3 -lopengl32 -lgdi32 -luser32 -lkernel32
else
    UNAME_S := $(shell uname -s)
    ifeq ($(UNAME_S),Darwin)
        # macOS-specific settings
        ASM_DEFINE  := -D MACOS
        ASMFLAGS    := -f macho64 -I$(SRC_DIR)/
				LINKFLAGS   := -lglfw -framework Cocoa -framework IOKit -framework CoreFoundation -framework CoreVideo -framework OpenGL
    else
        # Linux-specific settings
				# WARN: Linux platform was not tested
        ASM_DEFINE  := -D LINUX
        ASMFLAGS    := -f elf64 -I$(SRC_DIR)/
        LINKFLAGS   := -no-pie -lglfw -lGL -lX11 -lpthread -lXrandr -lXi -ldl -lm
    endif
    EXE_EXT :=
endif

# ===========================================================================
# File paths and targets
# ===========================================================================

SRC_PATHS   := $(addprefix $(SRC_DIR)/, $(SOURCES))
INC_PATHS   := $(addprefix $(SRC_DIR)/, $(INC_FILES))
MAC_PATHS   := $(addprefix $(SRC_DIR)/, $(MAC_FILES))
OBJS        := $(SOURCES:%.asm=$(BUILD_DIR)/%.o)
TARGET      := $(BUILD_DIR)/$(PROJECT)$(EXE_EXT)

# ===========================================================================
# Build rules
# ===========================================================================

.PHONY: all clean help check-files

# Default target
all: check-files $(TARGET)

# Help command
help:
	@echo "Available targets:"
	@echo "  all    - Build the project (default)"
	@echo "  clean  - Remove build artifacts"
	@echo "  help   - Display this help message"

# Check if source files exist
check-files:
	@for file in $(SRC_PATHS) $(INC_PATHS) $(MAC_PATHS); do \
		if [ ! -f $$file ]; then \
			echo "Error: Source file '$$file' not found!"; \
			echo "Make sure the file exists in the '$(SRC_DIR)' directory."; \
			exit 1; \
		fi; \
	done

# Linking
$(TARGET): $(OBJS)
	@echo "Linking   : $@"
	@gcc $(LINKFLAGS) -o $@ $^

# Assembly compilation
$(BUILD_DIR)/%.o: $(SRC_DIR)/%.asm $(INC_PATHS) $(MAC_PATHS) | $(BUILD_DIR)
	@echo "Assembling: $<"
	@if [ -f $< ]; then \
		nasm $(ASMFLAGS) $(ASM_DEFINE) -o $@ $<; \
	else \
		echo "Error: Source file '$<' not found!"; \
		exit 1; \
	fi;

# Create build directory if it doesn't exist
$(BUILD_DIR):
	@mkdir -p $@
	@echo "Created directory: $(BUILD_DIR)"

# Clean build artifacts
clean:
	@rm -rf $(BUILD_DIR)
	@echo "Cleaned build directory"
