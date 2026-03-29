// Tests: switch/case indentation (Google: IndentCaseLabels=true)

enum class Color { kRed, kGreen, kBlue };

void describe(Color c) {
  switch (c) {
    case Color::kRed:
      return;
    case Color::kGreen:
      break;
    case Color::kBlue: {
      int x = 1;
      break;
    }
    default:
      break;
  }
}

int classify(int x) {
  switch (x) {
    case 0:
      return -1;
    case 1:
    case 2:
      return 0;
    default:
      if (x > 10) {
        return 2;
      }
      return 1;
  }
}
