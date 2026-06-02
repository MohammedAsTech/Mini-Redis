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

class Database {
private:
    unordered_map<string,string> db;
public:
    Database() = default;
    ~Database() = default;
    // the default versions of C'tor and D'tor is enough because we call the map's  C'tor and D'tor.
    void set(const string& key,const string& value) ;

    optional<string> get(const string& key) const ; //returns the value with the Key key,if not found returns nullopt(have to check)

    void del(const string& key); //deletes the value with the Key key

    bool exists(const string& key) const;//checks if key is in the database

    vector<string> keys() const; //returns all the keys

};

#endif //DATABASE_H
