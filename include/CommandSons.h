//
// Created by moham on 02/06/2026.
//

#ifndef COMMANDSONS_H
#define COMMANDSONS_H
#include "Command.h"
class GetCommand : public Command {
public:
    GetCommand(const std::string& key);

};
class SetCommand : public Command {

public:
    SetCommand(const std::string& key,
           const std::string& value);
};
class DelCommand : public Command {
public:
    DelCommand(const std::string& key);
};
class SaveCommand : public Command {
public:
    SaveCommand(const std::string& filename);

};
class ExistsCommand : public Command {
public:
    ExistsCommand(const std::string& key);
};
class LoadCommand : public Command {
public:
    LoadCommand(const std::string& filename);
};
class ExitCommand : public Command {
};
class KeysCommand : public Command {
};
class InvalidCommand : public Command{
};
#endif //COMMANDSONS_H
