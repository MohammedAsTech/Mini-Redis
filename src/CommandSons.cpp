#include "CommandSons.h"

#include "Database.h"
#include "Persistence.h"

#include <cstdlib>
#include <iostream>

void SetCommand::execute(Database& db,
                         Persistence& persistence) {
    db.set(key, value);
    std::cout << "OK" << std::endl;
}

void GetCommand::execute(Database& db,
                         Persistence& persistence) {
    auto result = db.get(key);

    if (result.has_value()) {
        std::cout << result.value() << std::endl;
    }
    else {
        std::cout << "(nil)" << std::endl;
    }
}

void DelCommand::execute(Database& db,
                         Persistence& persistence) {
    if (db.del(key)) {
        std::cout << "deleted" << std::endl;
    }
    else {
        std::cout << "not found" << std::endl;
    }
}

void ExistsCommand::execute(Database& db,
                            Persistence& persistence) {
    std::cout << (db.exists(key) ? "true" : "false")
              << std::endl;
}

void KeysCommand::execute(Database& db,
                          Persistence& persistence) {
    auto allKeys = db.keys();

    for (const auto& key : allKeys) {
        std::cout << key << std::endl;
    }
}

void SaveCommand::execute(Database& db,
                          Persistence& persistence) {
    persistence.saveToFile(db, filename);
    std::cout << "Database saved" << std::endl;
}

void LoadCommand::execute(Database& db,
                          Persistence& persistence) {
    persistence.loadFromFile(db, filename);
    std::cout << "Database loaded" << std::endl;
}

void ExitCommand::execute(Database& db,
                          Persistence& persistence) {
    std::cout << "Goodbye" << std::endl;
    std::exit(0);
}
void RenameCommand::execute(Database& db,
                            Persistence& persistence) {
    if (db.renameKey(key, newKey)) {
        std::cout << "renamed" << std::endl;
    } else {
        std::cout << "not found" << std::endl;
    }
}
