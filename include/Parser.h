#pragma once

#include <functional>
#include <memory>
#include <string>
#include <unordered_map>
#include <vector>
#include "Command.h"


class Parser {
public:
    Parser();

    // Convert a raw CLI line into a command object.
    std::unique_ptr<Command> parse(const std::string& line) const;

private:
    using ParseFunction =
        std::function<std::unique_ptr<Command>(const std::string&)>;

    using OneArgCreator =
        std::function<std::unique_ptr<Command>(const std::string&)>;

    using NoArgCreator =
        std::function<std::unique_ptr<Command>()>;

    struct OneArgRegistration {
        std::string name;
        OneArgCreator creator;
    };

    struct NoArgRegistration {
        std::string name;
        NoArgCreator creator;
    };

    // Command name -> parser function
    std::unordered_map<std::string, ParseFunction> parsers;

    // Register command groups
    void registerOneKeyCommands(const std::vector<OneArgRegistration>& commands);
    void registerNoArgCommands(const std::vector<NoArgRegistration>& commands);
    void registerFileCommands(const std::vector<OneArgRegistration>& commands);
    void registerSetCommand();

    // Parsing helpers
    static std::unique_ptr<Command> parseSet(const std::string& args);

    static std::unique_ptr<Command> parseOneKeyCommand(
        const std::string& args,
        const OneArgCreator& creator
    );

    static std::unique_ptr<Command> parseNoArgCommand(
        const std::string& args,
        const NoArgCreator& creator
    );

    static std::unique_ptr<Command> parseFileCommand(
        const std::string& args,
        const OneArgCreator& creator
    );

    static std::string trim(const std::string& str);
};