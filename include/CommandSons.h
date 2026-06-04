#ifndef COMMANDSONS_H
#define COMMANDSONS_H

#include "Command.h"

#include <iostream>
#include <string>

class Database;
class Persistence;

class GetCommand : public Command {
private:
    std::string key;

public:
    explicit GetCommand(const std::string& key)
        : key(key) {}

    void execute(Database& db,
                 Persistence& persistence) override;
};

class SetCommand : public Command {
private:
    std::string key;
    std::string value;

public:
    SetCommand(const std::string& key,
               const std::string& value)
        : key(key),
          value(value) {}

    void execute(Database& db,
                 Persistence& persistence) override;
};

class DelCommand : public Command {
private:
    std::string key;

public:
    explicit DelCommand(const std::string& key)
        : key(key) {}

    void execute(Database& db,
                 Persistence& persistence) override;
};

class ExistsCommand : public Command {
private:
    std::string key;

public:
    explicit ExistsCommand(const std::string& key)
        : key(key) {}

    void execute(Database& db,
                 Persistence& persistence) override;
};

class SaveCommand : public Command {
private:
    std::string filename;

public:
    explicit SaveCommand(const std::string& filename)
        : filename(filename) {}

    void execute(Database& db,
                 Persistence& persistence) override;
};

class LoadCommand : public Command {
private:
    std::string filename;

public:
    explicit LoadCommand(const std::string& filename)
        : filename(filename) {}

    void execute(Database& db,
                 Persistence& persistence) override;
};

class KeysCommand : public Command {
public:
    void execute(Database& db,
                 Persistence& persistence) override;
};

class ExitCommand : public Command {
public:
    void execute(Database& db,
                 Persistence& persistence) override;
};
class RenameCommand : public Command {
private:
    std::string newKey;

public:
    RenameCommand(const std::string& oldKey,
                  const std::string& newKey)
        : Command(oldKey),
          newKey(newKey) {}

    void execute(Database& db,
                 Persistence& persistence) override;
};

#endif // COMMANDSONS_H