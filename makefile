CC := cc
CXX := g++
SHELL := /bin/bash

# Final exectuable
TARGET_EXEC := main


# Define Directorys
# binarys will be output to BIN_DIR. and object files will be ouput to BUILD_DIR
# source files will be found in SRC_DIR, header files will be found in INC_DIR
BIN_DIR := ./bin
SRC_DIR := ./src
INC_DIR := ./include
BUILD_DIR := ./build

# Find all C and C++ source file in SRC_DIR that we want to compile
# the values are like: ./src/main.cpp
SRCS := $(shell find $(SRC_DIR) -name "*.cpp" -or -name "*.c")

# Prepends BUILD_DIR and appends .o to every src file
# $(var:pattern=replacement) is Makefile pattern substitution expression which substitute var to replacement according pattern
# % is used to match the stem, here % matches the whole string
# As an example, ./src/hello.cpp turns into ./build/./src/hello.cpp.o
OBJS := $(SRCS:%=$(BUILD_DIR)/%.o)

# String substitution (for suffix % can be omitted).
# This equals to DEPS := $(OBJS:%.o=.%d), and % here represents the whole file name without .o
# As an example, % for ./build/hello.cpp.o matches ./build/hello.cpp, and turns into ./build/hello.cpp.d
DEPS := $(OBJS:.o=.d)

# Add folder in ./src to INC_DIRS
# Since every folder contains header files need to be passed to GCC so that it can find header files
INC_DIR += $(shell find $(SRC_DIR) -type d)
# Add a prefix to INC_DIR. So the folder moduleA would become -ImoduleA.
# Passing -ImoduleA to GCC, so that GCC will search the moduleA folder to find header files
INC_FLAGS := $(addprefix -I, $(INC_DIR))


# Define Libraries
LIBS := m
# Add a prefix to LIBS. So the library m (for math) will become -lm
# Passing -lm to linker (ld), so that linker will link the library m during compilation
LIB_FLAGS := $(addprefix -l, $(LIBS))



# Get the final CFLAGS and CPP Flags for compile objective files
# The -MMD and -MP flags together generate Makefiles for us!
# These files will have .d suffix instead of .o as the output.
CFLAGS := $(INC_FLAGS) -MMD -MP -std=c17 -g
CPPFLAGS := $(INC_FLAGS) -MMD -MP -std=c++17 -g


# The followings are Makefile Pattern Rules
# 
# Pattern Rules are like:
# Target-Pattern: Prerequisite-Pattern
#     <tab> command
#
# Target-Pattern is the pattern of the target file
# Target-Pattern is the pattern of the prerequisite file
#
# For example, the following rule is a Pattern Rule:
#
# %.o: %.c
#     gcc -c $< -o $@
# 
# For a give objective file, main.o, the rule matches main, so when exectuing, the rule turns to
#
# main.o: main.c
#     gcc -c $< -o $@
# 
# and $< and $@ are automatic variable, which represent current the first prerequisite and target file
# so finally, the after matching main.o, the rule turns to
#
# main.o: main.c
#     gcc -c main.c -o main.o
#
#
# Then, the final problem is where are the target, like main.o, comes from to match the pattern rule?
# Like we know, DEPS := $(OBJS:%.o=.%d) will matches all element from OBJS, but where are the target comes from
# *The answer is the target is the prerequisite of final rule*
#
# For example, we have a final program hello, which has the folloing rule to built it:
#
# hello: hello.o print.o test.o
#     gcc $^ -o $@
#
# $^ and $@ are automatic variable, which represent all prerequist and target, this is hello.o, print.o, test.o and hello
# So the hello rule means before making hello, we need to have hello.o, print.o and test.o
#
# If we don't have these files, the Make will find the rule that builds them, 
# i.e. find the rules whose target are hello.o, print.o and test,o
# Since we don't have a plicit rule whose target are them, the Make will try the Pattern Rules
# And luckily, there is a rule that is:
#
# %.o: %.c
#     gcc -c $< -o $@
# 
# The pattern %.o matches hello.o, print.o and test.o. So this rule is called first to build hello rule's prerequisite
# Thus, the target used to match the Pattern Rule is actually come from other rule's prerequisite.
#
# Usually, we need a final rule that plicitly declare all objective files are prerequisite
# to enable the Make automatically matches Pattern Rule
# That is the rule below:

# The final build step.
$(BIN_DIR)/$(TARGET_EXEC): $(OBJS)
	@mkdir -p $(dir $@)
	$(CXX) $(OBJS) $(LIB_FLAGS) -o $@ $(LDFLAGS)

# Pattern Rule for build C files
$(BUILD_DIR)/%.c.o: %.c
	@mkdir -p $(dir $@)
	$(CC) $(CFLAGS) $(CFLAGS) -c $< -o $@

# Pattern Rule for build C++ files
$(BUILD_DIR)/%.cpp.o: %.cpp
	@mkdir -p $(dir $@)
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) -c $< -o $@




# Target echo will print Makefile variables
# $(foreach <var>, <list>, <text>) is a Makefile builtin function which loops over <list>, storing variable in <var>, and <var> is passed to <text>
# $(sort <list>) is a Makefile builtin function which sorts <list> according to lexicographical order
# $(if <condition>, <then-part>, <else-part>) is a Makefile builtin function which run commands according to condition
# $(filter-out <pattern>, <text>) is a Makefile builtin function and returns a list of elements which didn't match the pattern
# $(origin <variable>) is a Makefile builtin function which returns the name of the variable, not the value
# $(info <text>) is a Makefile builtin function which prints text to terminal
.PHONY: echo
echo:
	$(foreach var, $(sort $(.VARIABLES)),\
        $(if $(filter-out environment% default automatic,$(origin $(var))),\
            $(info $(var): $($(var)))))


.PHONY: clean
clean:
	rm -rf ./build ./bin


.DEFAULT_GOAL: all
all: $(BIN_DIR)/$(TARGET_EXEC)


# Include the .d makefiles. The - at the front suppresses the errors of missing Makefiles.
# Initially, all the .d files will be missing the first time of compiling, and we don't want those
# errors to show up.
-include $(DEPS)