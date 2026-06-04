//
// Created by moham on 02/06/2026.
//

#ifndef COMMAND_H
#define COMMAND_H

#include <string>

class Database;
class Persistence;

class Command {
protected:
    std::string key;

public:
    Command() = default;

    explicit Command(const std::string& key)
        : key(key) {}

    virtual ~Command() = default;

    const std::string& getKey() const {
        return key;
    }

    virtual void execute(Database& db,
                         Persistence& persistence) = 0;
};

#endif // COMMAND_H