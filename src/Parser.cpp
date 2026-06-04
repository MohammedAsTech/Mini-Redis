#include "Parser.h"

#include "Command.h"
#include "CommandSons.h"

#include <cctype>
#include <functional>
#include <memory>
#include <sstream>
#include <string>

namespace {

// Remove leading and trailing spaces.
std::string trim(const std::string& str) {
    std::size_t start = 0;

    while (start < str.size() &&
           std::isspace(static_cast<unsigned char>(str[start]))) {
        ++start;
    }

    std::size_t end = str.size();

    while (end > start &&
           std::isspace(static_cast<unsigned char>(str[end - 1]))) {
        --end;
    }

    return str.substr(start, end - start);
}

}

// Base interface for parsing strategies.
class CommandParser {
public:
    virtual ~CommandParser() = default;

    virtual std::unique_ptr<Command>
    parse(const std::string& args) const = 0;
};

// GET / DEL / EXISTS
class OneKeyCommandParser : public CommandParser {
public:
    using Creator =
        std::function<std::unique_ptr<Command>(const std::string&)>;

    explicit OneKeyCommandParser(Creator creator)
        : creator(std::move(creator)) {}

    std::unique_ptr<Command> parse(
        const std::string& args
    ) const override {
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

private:
    Creator creator;
};

// KEYS / EXIT
class NoArgCommandParser : public CommandParser {
public:
    using Creator =
        std::function<std::unique_ptr<Command>()>;

    explicit NoArgCommandParser(Creator creator)
        : creator(std::move(creator)) {}

    std::unique_ptr<Command> parse(
        const std::string& args
    ) const override {
        if (!trim(args).empty()) {
            return std::make_unique<InvalidCommand>();
        }

        return creator();
    }

private:
    Creator creator;
};

// SAVE / LOAD
class FileCommandParser : public OneKeyCommandParser {
public:
    using OneKeyCommandParser::OneKeyCommandParser;
};

// SET key value...
class SetCommandParser : public CommandParser {
public:
    std::unique_ptr<Command> parse(
        const std::string& args
    ) const override {
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
};

Parser::Parser() {
    registerCommands();
}

// Main parser entry point.
std::unique_ptr<Command> Parser::parse(
    const std::string& line
) const {
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

    return it->second->parse(args);
}

// Build the command registry.
void Parser::registerCommands() {

    parsers["SET"] =
        std::make_unique<SetCommandParser>();

    parsers["GET"] =
        std::make_unique<OneKeyCommandParser>(
            [](const std::string& key)
            -> std::unique_ptr<Command> {
                return std::make_unique<GetCommand>(key);
            }
        );

    parsers["DEL"] =
        std::make_unique<OneKeyCommandParser>(
            [](const std::string& key)
            -> std::unique_ptr<Command> {
                return std::make_unique<DelCommand>(key);
            }
        );

    parsers["EXISTS"] =
        std::make_unique<OneKeyCommandParser>(
            [](const std::string& key)
            -> std::unique_ptr<Command> {
                return std::make_unique<ExistsCommand>(key);
            }
        );

    parsers["KEYS"] =
        std::make_unique<NoArgCommandParser>(
            []() -> std::unique_ptr<Command> {
                return std::make_unique<KeysCommand>();
            }
        );

    parsers["EXIT"] =
        std::make_unique<NoArgCommandParser>(
            []() -> std::unique_ptr<Command> {
                return std::make_unique<ExitCommand>();
            }
        );

    parsers["SAVE"] =
        std::make_unique<FileCommandParser>(
            [](const std::string& filename)
            -> std::unique_ptr<Command> {
                return std::make_unique<SaveCommand>(filename);
            }
        );

    parsers["LOAD"] =
        std::make_unique<FileCommandParser>(
            [](const std::string& filename)
            -> std::unique_ptr<Command> {
                return std::make_unique<LoadCommand>(filename);
            }
        );
}