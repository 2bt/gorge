LIB = -lsfml-graphics -lsfml-window -lsfml-system
SRC = $(wildcard src/*.cpp)
OBJ = $(SRC:src/%.cpp=obj/%.o)
TARGET = shooter

all: $(TARGET)


obj/%.o: src/%.cpp
	@mkdir -p $(@D)
	g++ --std=c++11 -Wall -O2 -c $< -o $@



$(TARGET): Makefile $(OBJ)
	g++ --std=c++11 -Wall $(OBJ) $(LIB) -o $@

clean:
	rm -rf obj
	rm -rf $(TARGET)
