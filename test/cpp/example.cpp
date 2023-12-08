
#include "cpp/example.hpp"

#include <iostream>

using namespace my_example;

Example::Example() { std::cout << "Created example" << std::endl; }

void Example::print_something() { print_something("something"); }

void Example::print_something(const std::string &txt) {
  std::cout << txt << std::endl;
}
