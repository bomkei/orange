#pragma once

#include "hardware.h"

class OrangeDriver {

  Hardware hardware;

public:
  OrangeDriver();
  ~OrangeDriver();

  int main(int argc, char** argv);
  
};