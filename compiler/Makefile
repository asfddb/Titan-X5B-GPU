CXX = g++
CXXFLAGS = -Wall -Wextra -O2 -std=c++17

TARGET = titan-cc

all: $(TARGET)

$(TARGET): titan_cc.cpp
	$(CXX) $(CXXFLAGS) -o $(TARGET) titan_cc.cpp

clean:
	rm -f $(TARGET) *.bin
