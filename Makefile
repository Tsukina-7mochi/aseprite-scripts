LUA = lua
LIB = ./lib
LIB_TEST = $(LIB)/test.lua
LIB_NEBLUA = $(LIB)/neblua.lua
LUA_PATH = "./?.lua;./?/init.lua;./src/?.lua;./src/?/init.lua"

build: $(LIB_NEBLUA) 
	LUA_PATH=$(LUA_PATH) $(LUA) build.lua

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
	LUA_PATH=$(LUA_PATH) $(LUA) ./src/pkg/test.lua
