#include <iostream>
#include <string>

int main() {
    std::string line;

    while (true) {
        std::cout << "> ";

        std::getline(std::cin, line);

        if (line == "EXIT") {
            std::cout << "Goodbye" << std::endl;
            break;
        }

        if (line.empty()) {
            continue;
        }

        std::cout << "Unknown command" << std::endl;
    }

    return 0;
}
