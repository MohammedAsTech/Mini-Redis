#pragma once

#include <functional>
#include <memory>
#include <string>
#include <unordered_map>
#include <vector>

class ICommand;

class Parser {
public:
    Parser();

    std::unique_ptr<ICommand> parse(const std::string& line) const;

private:
    using ParseFunction =
        std::function<std::unique_ptr<ICommand>(const std::string&)>;

    using OneArgCreator =
        std::function<std::unique_ptr<ICommand>(const std::string&)>;

    using NoArgCreator =
        std::function<std::unique_ptr<ICommand>()>;

    struct OneArgRegistration {
        std::string name;
        OneArgCreator creator;
    };

    struct NoArgRegistration {
        std::string name;
        NoArgCreator creator;
    };

    std::unordered_map<std::string, ParseFunction> parsers;

    void registerOneKeyCommands(const std::vector<OneArgRegistration>& commands);
    void registerNoArgCommands(const std::vector<NoArgRegistration>& commands);
    void registerFileCommands(const std::vector<OneArgRegistration>& commands);
    void registerSetCommand();

    static std::unique_ptr<ICommand> parseSet(const std::string& args);

    static std::unique_ptr<ICommand> parseOneKeyCommand(
        const std::string& args,
        const OneArgCreator& creator
    );

    static std::unique_ptr<ICommand> parseNoArgCommand(
        const std::string& args,
        const NoArgCreator& creator
    );

    static std::unique_ptr<ICommand> parseFileCommand(
        const std::string& args,
        const OneArgCreator& creator
    );

    static std::string trim(const std::string& str);
};