#include "Parser.h"

#include "CommandSons.h"
#include "Command.h"
#include <vector>
#include <cctype>
#include <sstream>
using namespace std;

Parser::Parser() {

    std::vector<OneArgRegistration> oneKeyCommands = {
        {"GET", [](const std::string& key) -> std::unique_ptr<Command> {
            return std::make_unique<GetCommand>(key);
        }},
        {"DEL", [](const std::string& key) -> std::unique_ptr<Command> {
            return std::make_unique<DelCommand>(key);
        }},
        {"EXISTS", [](const std::string& key) -> std::unique_ptr<Command> {
            return std::make_unique<ExistsCommand>(key);
        }}
    };

    registerOneKeyCommands(oneKeyCommands);

    std::vector<NoArgRegistration> noArgCommands = {
        {"KEYS", []() -> std::unique_ptr<Command> {
            return std::make_unique<KeysCommand>();
        }},
        {"EXIT", []() -> std::unique_ptr<Command> {
            return std::make_unique<ExitCommand>();
        }}
    };

    registerNoArgCommands(noArgCommands);

    std::vector<OneArgRegistration> fileCommands = {
        {"SAVE", [](const std::string& filename) -> std::unique_ptr<Command> {
            return std::make_unique<SaveCommand>(filename);
        }},
        {"LOAD", [](const std::string& filename) -> std::unique_ptr<Command> {
            return std::make_unique<LoadCommand>(filename);
        }}
    };

    registerFileCommands(fileCommands);

    registerSetCommand();
}
std::unique_ptr<Command> Parser::parse(const std::string& line) const {
    std::string cleanedLine = trim(line);

    if (cleanedLine.empty()) {
        return std::make_unique<InvalidCommand>();
    }

    std::istringstream iss(cleanedLine);

    std::string commandName;
    iss >> commandName;

    std::string args;
    std::getline(iss, args);
    args = trim(args);

    auto it = parsers.find(commandName);

    if (it == parsers.end()) {
        return std::make_unique<InvalidCommand>();
    }

    return it->second(args);
}
// Registers commands like GET, DEL, EXISTS.
void Parser::registerOneKeyCommands(
    const std::vector<OneArgRegistration>& commands
) {
    for (const auto& command : commands) {
        parsers[command.name] =
            [creator = command.creator](const std::string& args) {
                return parseOneKeyCommand(args, creator);
        };
    }
}

// Registers commands like KEYS, EXIT.
void Parser::registerNoArgCommands(
    const std::vector<NoArgRegistration>& commands
) {
    for (const auto& command : commands) {
        parsers[command.name] =
            [creator = command.creator](const std::string& args) {
                return parseNoArgCommand(args, creator);
        };
    }
}
// Registers commands like SAVE, LOAD.
void Parser::registerFileCommands(
    const std::vector<OneArgRegistration>& commands
) {
    for (const auto& command : commands) {
        parsers[command.name] =
            [creator = command.creator](const std::string& args) {
                return parseFileCommand(args, creator);
        };
    }
}
// SET is registered separately because it has key + multi-word value.
void Parser::registerSetCommand() {
    parsers["SET"] = [](const std::string& args) {
        return parseSet(args);
    };
}

// Parses: SET key value-with-spaces
std::unique_ptr<Command> Parser::parseSet(const std::string& args) {
    std::istringstream iss(trim(args));

    std::string key;
    if (!(iss >> key)) {
        return std::make_unique<InvalidCommand>();
    }

    std::string value;
    std::getline(iss, value);
    value = trim(value);

    if (value.empty()) {
        return std::make_unique<InvalidCommand>();
    }

    return std::make_unique<SetCommand>(key, value);
}
// Parses exactly one argument.
std::unique_ptr<Command> Parser::parseOneKeyCommand(
    const std::string& args,
    const OneArgCreator& creator
) {
    std::istringstream iss(trim(args));

    std::string key;
    std::string extra;

    if (!(iss >> key)) {
        return std::make_unique<InvalidCommand>();
    }

    if (iss >> extra) {
        return std::make_unique<InvalidCommand>();
    }

    return creator(key);
}
// Parses commands that should have no arguments.
std::unique_ptr<Command> Parser::parseNoArgCommand(
    const std::string& args,
    const NoArgCreator& creator
) {
    if (!trim(args).empty()) {
        return std::make_unique<InvalidCommand>();
    }

    return creator();
}

// Same syntax as one-key command, but the argument means filename.
std::unique_ptr<Command> Parser::parseFileCommand(
    const std::string& args,
    const OneArgCreator& creator
) {
    return parseOneKeyCommand(args, creator);
}