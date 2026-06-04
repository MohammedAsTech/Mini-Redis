//
// Created by moham on 02/06/2026.
//

#ifndef DATABASE_H

#define DATABASE_H
#include <optional>
#include <string>
#include <unordered_map>
#include <vector>
using namespace std;
using std::string;
using std::vector;
#include <deque>

class Database {
private:
    unordered_map<string,string> db;
    std::deque<std::string> history;
    static constexpr std::size_t MAX_HISTORY = 20;
public:
    Database() = default;
    ~Database() = default;
    // the default versions of C'tor and D'tor is enough because we call the map's  C'tor and D'tor.
    void set(const string& key,const string& value) ;

    optional<string> get(const string& key) const ; //returns the value with the Key key,if not found returns nullopt(have to check)

    bool del(const string& key); //deletes the value with the Key key

    bool exists(const string& key) const;//checks if key is in the database

    vector<string> keys() const; //returns all the keys

    const std::unordered_map<std::string, std::string>& entries()const {
        return db;
    }

    void clear();

    void replaceEntries(
        const std::unordered_map<std::string, std::string>& newEntries
    );

    bool renameKey(const std::string& oldKey,
               const std::string& newKey); //rename OldKey to newKey

    void addToHistory(const std::string& commandLine);

    const std::deque<std::string>& getHistory() const;

};

#endif //DATABASE_H
