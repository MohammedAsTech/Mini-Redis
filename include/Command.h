//
// Created by moham on 02/06/2026.
//

#ifndef COMMAND_H

#define COMMAND_H
class Command {
protected:
    std::string commandName;
    std::string key;
    std::string value;

public:
    Command() = default;

    Command(const std::string& commandName)
        : commandName(commandName) {}

    Command(const std::string& commandName,
            const std::string& key)
        : commandName(commandName),
          key(key) {}

    Command(const std::string& commandName,
            const std::string& key,
            const std::string& value)
        : commandName(commandName),
          key(key),
          value(value) {}

    virtual ~Command() = default;
};


#endif //COMMAND_H
