LUA = lua
DIST = ./dist
LIB = ./lib
LIB_TEST = $(LIB)/test.lua
LIB_NEBLUA = $(LIB)/neblua.lua

build: build-psd build-lcd build-cur

build-psd: $(DIST) $(LIB_NEBLUA)
	DIST_DIR=$(DIST) $(LUA) ./psd/build.lua

build-lcd: $(DIST) $(LIB_NEBLUA)
	DIST_DIR=$(DIST) $(LUA) ./lcd-pixel-filter/build.lua

build-cur: $(DIST) $(LIB_NEBLUA)
	DIST_DIR=$(DIST) $(LUA) ./icon-and-cursor/build.lua

prepare: $(LIB_TEST) $(LIB_NEBLUA)

$(DIST):
	mkdir -p $(DIST)

$(LIB):
	mkdir -p $(LIB)

$(LIB_TEST): $(LIB)
	curl -sSL https://github.com/Tsukina-7mochi/lua-testing-library/releases/latest/download/test.lua > $(LIB_TEST)

$(LIB_NEBLUA): $(LIB)
	curl -sSL https://github.com/Tsukina-7mochi/neblua/releases/latest/download/neblua.lua > $(LIB_NEBLUA)

.PHONY: test
test: $(LIB_TEST)
	$(LUA) pkg/test.lua

.PHONY: clean
clean: 
	rm -rf $(DIST) 
