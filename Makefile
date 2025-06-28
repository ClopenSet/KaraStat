# Target executable name
TARGET = karastat

# Directories
HOME_DIR = $(HOME)
LIBKRBN_STANDALONE_DIR = ./externals/Karabiner-Lite
LIBKRBN_BUILD_DIR = $(LIBKRBN_STANDALONE_DIR)/build/Debug
LIBKRBN_VENDOR_SRC_DIR = $(LIBKRBN_STANDALONE_DIR)/deps/vendor/vendor/src
SQLITE_SWIFT_REPO_DIR = ./externals/SQLite.swift

# Compiler and flags
SWIFTC = swiftc
SWIFT_FLAGS = -O \
  -I$(LIBKRBN_STANDALONE_DIR)/include \
  -I$(LIBKRBN_STANDALONE_DIR)/deps/vendor/vendor/include \
  -import-objc-header src/Bridging-Header.h

LDFLAGS = -L$(LIBKRBN_BUILD_DIR) -lkrbn -lc++ -lsqlite3

SOURCES = \
    src/main.swift \
    src/DatabaseManager.swift \
    $(wildcard $(SQLITE_SWIFT_REPO_DIR)/Sources/SQLite/*.swift) \
    $(wildcard $(SQLITE_SWIFT_REPO_DIR)/Sources/SQLite/Core/*.swift) \
    $(wildcard $(SQLITE_SWIFT_REPO_DIR)/Sources/SQLite/Extensions/*.swift) \
    $(wildcard $(SQLITE_SWIFT_REPO_DIR)/Sources/SQLite/Schema/*.swift) \
    $(wildcard $(SQLITE_SWIFT_REPO_DIR)/Sources/SQLite/Typed/*.swift) \
    $(LIBKRBN_VENDOR_SRC_DIR)/pqrs/osx/workspace/PQRSOSXWorkspaceImpl.swift \
    $(LIBKRBN_VENDOR_SRC_DIR)/pqrs/osx/process_info/PQRSOSXProcessInfoImpl.swift \
    $(LIBKRBN_VENDOR_SRC_DIR)/pqrs/osx/frontmost_application_monitor/PQRSOSXFrontmostApplicationMonitorImpl.swift

# Default target: ensure libkrbn is built before main target
all: $(LIBKRBN_BUILD_DIR)/libkrbn.a $(TARGET)

# Build libkrbn.a if needed
$(LIBKRBN_BUILD_DIR)/libkrbn.a:
	@echo "Building Karabiner-Lite..."
	$(MAKE) -C $(LIBKRBN_STANDALONE_DIR)

# Build main target
$(TARGET): $(SOURCES) src/Bridging-Header.h $(LIBKRBN_BUILD_DIR)/libkrbn.a
	@echo "Compiling and linking executable: $(TARGET)"
	$(SWIFTC) $(SWIFT_FLAGS) $(SOURCES) $(LDFLAGS) -o $(TARGET)
	@echo "Build complete! Run with: ./$(TARGET)"

# Clean rule
clean:
	@echo "Cleaning main project..."
	rm -f $(TARGET)
	rm -rf "$(HOME_DIR)/Library/Application Support/karastat"
	@echo "Cleaning Karabiner-Lite..."
	$(MAKE) -C $(LIBKRBN_STANDALONE_DIR) clean

libkrbn: $(LIBKRBN_BUILD_DIR)/libkrbn.a

.PHONY: all clean
