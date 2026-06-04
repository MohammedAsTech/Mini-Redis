#include "Parser.h"
#include "Database.h"
#include "Persistence.h"
#include "Command.h"
#include <exception>
#include <iostream>
#include <string>

int main() {
    Database db;
    Persistence persistence;
    Parser parser;

    std::string line;

    while (std::getline(std::cin, line)) {
        try {
            auto command = parser.parse(line);
            command->execute(db, persistence);
        }
        catch (const std::exception& e) {
            std::cout << e.what() << std::endl;
        }
    }

    return 0;
}