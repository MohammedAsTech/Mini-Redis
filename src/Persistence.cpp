//
// Created by moham on 04/06/2026.
//
#include "Persistence.h"

#include <unordered_map>
#include <fstream>
#include <stdexcept>
#include <string>

#include "Database.h"

Persistence::~Persistence() = default;
Persistence::Persistence() = default;

void Persistence::saveToFile(const Database &db, const std::string &filename) const {
    std::ofstream out_file(filename);
    if (!out_file.is_open()) {
        throw std::runtime_error("File error");
    }

    for (const auto& pair : db.entries()) {
        out_file << pair.first
            << " = "
            << pair.second
            << '\n';
    }
}

void Persistence::loadFromFile(
    Database& db,
    const std::string& filename
) const {
    std::ifstream in(filename);

    if (!in.is_open()) {
        throw std::runtime_error("File error");
    }

    std::unordered_map<std::string, std::string> temp;

    std::string line;

    while (std::getline(in, line)) {

        std::size_t pos = line.find(" = ");

        if (pos == std::string::npos) {
            throw std::runtime_error("Corrupted file");
        }

        std::string key = line.substr(0, pos);
        std::string value = line.substr(pos + 3);

        temp[key] = value;
    }

    db.replaceEntries(temp);
}