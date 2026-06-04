//
// Created by moham on 04/06/2026.
//
#include "Persistence.h"

#include <fstream>

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

