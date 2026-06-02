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
void Database::del(const string &key) {
    if(!exists(key))
        return;
    db.erase(key);
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



