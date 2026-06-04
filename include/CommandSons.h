#ifndef COMMANDSONS_H
#define COMMANDSONS_H

#include "Command.h"

#include <string>

class Database;
class Persistence;

class GetCommand : public Command {
public:
    explicit GetCommand(const std::string& key)
        : Command(key) {}

    void execute(Database& db,
                 Persistence& persistence) override;
};

class SetCommand : public Command {
private:
    std::string value;

public:
    SetCommand(const std::string& key,
               const std::string& value)
        : Command(key),
          value(value) {}

    void execute(Database& db,
                 Persistence& persistence) override;
};

class DelCommand : public Command {
public:
    explicit DelCommand(const std::string& key)
        : Command(key) {}

    void execute(Database& db,
                 Persistence& persistence) override;
};

class ExistsCommand : public Command {
public:
    explicit ExistsCommand(const std::string& key)
        : Command(key) {}

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
    KeysCommand() = default;

    void execute(Database& db,
                 Persistence& persistence) override;
};

class ExitCommand : public Command {
public:
    ExitCommand() = default;

    void execute(Database& db,
                 Persistence& persistence) override;
};

class HistoryCommand : public Command {
public:
    HistoryCommand() = default;

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