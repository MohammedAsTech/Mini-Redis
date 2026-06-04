//
// Created by moham on 02/06/2026.
//

#ifndef COMMANDSONS_H
#define COMMANDSONS_H

#include "Command.h"
#include <string>

// One-key commands: GET key, DEL key, EXISTS key
class GetCommand : public Command {
public:
    explicit GetCommand(const std::string& key)
        : Command("GET", key) {}
};

class DelCommand : public Command {
public:
    explicit DelCommand(const std::string& key)
        : Command("DEL", key) {}
};

class ExistsCommand : public Command {
public:
    explicit ExistsCommand(const std::string& key)
        : Command("EXISTS", key) {}
};

// SET key value
class SetCommand : public Command {
public:
    SetCommand(const std::string& key, const std::string& value)
        : Command("SET", key, value) {}
};

// File commands: SAVE filename, LOAD filename
class SaveCommand : public Command {
public:
    explicit SaveCommand(const std::string& filename)
        : Command("SAVE", filename) {}
};

class LoadCommand : public Command {
public:
    explicit LoadCommand(const std::string& filename)
        : Command("LOAD", filename) {}
};

// No-argument commands
class ExitCommand : public Command {
public:
    ExitCommand()
        : Command("EXIT") {}
};

class KeysCommand : public Command {
public:
    KeysCommand()
        : Command("KEYS") {}
};

// Used when parsing fails
class InvalidCommand : public Command {
public:
    InvalidCommand()
        : Command("INVALID") {}
};

#endif // COMMANDSONS_H