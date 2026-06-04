#ifndef PERSISTENCE_H
#define PERSISTENCE_H

#include <string>

class Database;

class Persistence {
public:
    Persistence();
    ~Persistence();

    void saveToFile(const Database& db,
                    const std::string& filename) const;

    void loadFromFile(Database& db,
                      const std::string& filename) const;
};

#endif // PERSISTENCE_H