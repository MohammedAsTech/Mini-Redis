#include "Database.h"

#include <optional>
#include <stdexcept>

void Database::set(const string& key,const string& value) {
        db[key] =  value;
}
optional<string> Database::get(const string& key) const {
    if(exists(key))
        return db.find(key)->second;
    return nullopt;
}
bool Database::del(const string &key) {
    if(!exists(key))
        return false;
    db.erase(key);
    return true;
}
bool Database::exists(const string &key) const {
    auto it = db.find(key);
    if(it != db.end())
        return true;
    return false;
}
vector<string> Database::keys() const {
 vector<string> res;
for(const auto& it:db) {
    res.push_back(it.first);
}
    return res;
}
void Database::clear() {
    db.clear();
}

void Database::replaceEntries(
    const std::unordered_map<std::string, std::string>& newEntries
) {
    db = newEntries;
}

bool Database::renameKey(const string& oldKey,
                         const string& newKey) {
    auto oldIt = db.find(oldKey);

    if (oldIt == db.end()) {
        return false;
    }

    if (db.find(newKey) != db.end()) {
        throw std::runtime_error("target already exists");
    }

    db[newKey] = oldIt->second;
    db.erase(oldIt);

    return true;
}
void Database::addToHistory(const string& commandLine) {
    history.push_back(commandLine);
}

const vector<string>& Database::getHistory() const {
    return history;
}


