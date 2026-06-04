#pragma once

#include <memory>
#include <string>
#include <unordered_map>

class Command;
class CommandParser;

class Parser {
public:
    Parser();

    // Convert raw input into a command object.
    std::unique_ptr<Command> parse(const std::string& line) const;

private:
    using ParserPtr = std::unique_ptr<CommandParser>;

    // Command name -> parsing strategy
    std::unordered_map<std::string, ParserPtr> parsers;

    // Register all supported commands.
    void registerCommands();
};