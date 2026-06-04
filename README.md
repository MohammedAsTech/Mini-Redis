# \# Mini Redis

# 

# A lightweight Redis-inspired in-memory key-value database implemented in modern C++.

# 

# This project was built to demonstrate:

# 

# \* Object-Oriented Design

# \* Design Patterns (Command Pattern)

# \* Parsing and Command Dispatch

# \* File Persistence

# \* Error Handling

# \* Modern C++ Memory Management

# \* Unit / Integration Testing

# \* Clean Software Architecture

# 

# \---

# 

# \# Features

# 

# \## Core Database Operations

# 

# | Command | Description                       |

# | ------- | --------------------------------- |

# | SET     | Create or update a key-value pair |

# | GET     | Retrieve a value by key           |

# | DEL     | Delete a key                      |

# | EXISTS  | Check if a key exists             |

# | KEYS    | List all keys                     |

# | RENAME  | Rename an existing key            |

# 

# \## Persistence

# 

# | Command | Description                      |

# | ------- | -------------------------------- |

# | SAVE    | Save database contents to disk   |

# | LOAD    | Load database contents from disk |

# 

# \## Utility Commands

# 

# | Command | Description             |

# | ------- | ----------------------- |

# | HISTORY | Display command history |

# | EXIT    | Terminate the program   |

# 

# \---

# 

# \# Example Session

# 

# ```text

# SET name Mohammed

# OK

# 

# GET name

# Mohammed

# 

# EXISTS name

# true

# 

# RENAME name username

# renamed

# 

# GET username

# Mohammed

# 

# SAVE db.txt

# Database saved

# 

# LOAD db.txt

# Database loaded

# ```

# 

# \---

# 

# \# Architecture

# 

# The system is divided into four major components:

# 

# \## Database

# 

# Responsible for storing all key-value pairs.

# 

# Internally uses:

# 

# ```cpp

# std::unordered\_map<std::string, std::string>

# ```

# 

# which provides average O(1) access time.

# 

# Responsibilities:

# 

# \* Store data

# \* Delete data

# \* Rename keys

# \* Manage history

# \* Expose database entries for persistence

# 

# \---

# 

# \## Parser

# 

# Responsible for converting raw user input into executable commands.

# 

# Example:

# 

# ```text

# SET name Mohammed

# ```

# 

# becomes

# 

# ```cpp

# SetCommand("name", "Mohammed")

# ```

# 

# The parser uses a registry-based dispatch mechanism:

# 

# ```cpp

# unordered\_map<string, unique\_ptr<CommandParser>>

# ```

# 

# allowing commands to be added without modifying existing parsing logic.

# 

# This follows the Open/Closed Principle.

# 

# \---

# 

# \## Command System

# 

# Uses the Command Design Pattern.

# 

# Each command is represented as an independent class.

# 

# Examples:

# 

# ```cpp

# SetCommand

# GetCommand

# DelCommand

# ExistsCommand

# SaveCommand

# LoadCommand

# RenameCommand

# HistoryCommand

# ```

# 

# All commands inherit from:

# 

# ```cpp

# class Command

# ```

# 

# and implement:

# 

# ```cpp

# virtual void execute(

# &#x20;   Database\& db,

# &#x20;   Persistence\& persistence

# ) = 0;

# ```

# 

# Benefits:

# 

# \* Encapsulation of behavior

# \* Easy extensibility

# \* Separation of parsing and execution

# \* Cleaner testing

# 

# \---

# 

# \## Persistence

# 

# Responsible for saving and loading database state.

# 

# Responsibilities:

# 

# \* Serialize database contents

# \* Deserialize database contents

# \* Validate file integrity

# \* Report corrupted files

# 

# \---

# 

# \# Design Pattern

# 

# \## Command Pattern

# 

# This project intentionally uses the Command Pattern.

# 

# Structure:

# 

# ```text

# User Input

# &#x20;    |

# &#x20;    v

# &#x20;  Parser

# &#x20;    |

# &#x20;    v

# &#x20;Command Object

# &#x20;    |

# &#x20;    v

# &#x20;execute()

# &#x20;    |

# &#x20;    v

# &#x20;Database / Persistence

# ```

# 

# Advantages:

# 

# \* Low coupling

# \* High cohesion

# \* Easy feature additions

# \* Better testability

# \* Cleaner architecture

# 

# \---

# 

# \# Supported Commands

# 

# \## SET

# 

# Creates or updates a key.

# 

# ```text

# SET username Mohammed

# ```

# 

# Output:

# 

# ```text

# OK

# ```

# 

# \### Complexity

# 

# Average:

# 

# ```text

# O(1)

# ```

# 

# Worst Case:

# 

# ```text

# O(n)

# ```

# 

# due to hash collisions.

# 

# \---

# 

# \## GET

# 

# Retrieves a value.

# 

# ```text

# GET username

# ```

# 

# Output:

# 

# ```text

# Mohammed

# ```

# 

# If missing:

# 

# ```text

# (nil)

# ```

# 

# \### Complexity

# 

# Average:

# 

# ```text

# O(1)

# ```

# 

# Worst Case:

# 

# ```text

# O(n)

# ```

# 

# \---

# 

# \## DEL

# 

# Deletes a key.

# 

# ```text

# DEL username

# ```

# 

# Output:

# 

# ```text

# deleted

# ```

# 

# \### Complexity

# 

# Average:

# 

# ```text

# O(1)

# ```

# 

# Worst Case:

# 

# ```text

# O(n)

# ```

# 

# \---

# 

# \## EXISTS

# 

# Checks if a key exists.

# 

# ```text

# EXISTS username

# ```

# 

# Output:

# 

# ```text

# true

# ```

# 

# \### Complexity

# 

# Average:

# 

# ```text

# O(1)

# ```

# 

# Worst Case:

# 

# ```text

# O(n)

# ```

# 

# \---

# 

# \## KEYS

# 

# Returns all keys.

# 

# ```text

# KEYS

# ```

# 

# Output:

# 

# ```text

# name

# email

# username

# ```

# 

# \### Complexity

# 

# ```text

# O(n)

# ```

# 

# where n is the number of stored keys.

# 

# \---

# 

# \## RENAME

# 

# Renames a key.

# 

# ```text

# RENAME oldKey newKey

# ```

# 

# Output:

# 

# ```text

# renamed

# ```

# 

# \### Complexity

# 

# Average:

# 

# ```text

# O(1)

# ```

# 

# Worst Case:

# 

# ```text

# O(n)

# ```

# 

# \---

# 

# \## SAVE

# 

# Persists the database to disk.

# 

# ```text

# SAVE db.txt

# ```

# 

# Output:

# 

# ```text

# Database saved

# ```

# 

# \### Complexity

# 

# ```text

# O(n)

# ```

# 

# All entries must be written to disk.

# 

# \---

# 

# \## LOAD

# 

# Loads database contents from disk.

# 

# ```text

# LOAD db.txt

# ```

# 

# Output:

# 

# ```text

# Database loaded

# ```

# 

# \### Complexity

# 

# ```text

# O(n)

# ```

# 

# All entries must be reconstructed.

# 

# \---

# 

# \## HISTORY

# 

# Displays the last executed commands.

# 

# History capacity:

# 

# ```text

# 20 commands

# ```

# 

# Implemented using:

# 

# ```cpp

# std::deque<std::string>

# ```

# 

# \### Complexity

# 

# Insertion:

# 

# ```text

# O(1)

# ```

# 

# Display:

# 

# ```text

# O(h)

# ```

# 

# where:

# 

# ```text

# h <= 20

# ```

# 

# \---

# 

# \## EXIT

# 

# Terminates the application.

# 

# ```text

# EXIT

# ```

# 

# Output:

# 

# ```text

# Goodbye

# ```

# 

# \### Complexity

# 

# ```text

# O(1)

# ```

# 

# \---

# 

# \# Error Handling

# 

# The application handles:

# 

# \* Unknown commands

# \* Invalid command syntax

# \* Missing files

# \* Corrupted files

# \* Invalid rename operations

# \* Invalid persistence paths

# 

# Examples:

# 

# ```text

# Unknown command

# ```

# 

# ```text

# Invalid command usage

# ```

# 

# ```text

# File error

# ```

# 

# ```text

# Corrupted file

# ```

# 

# \---

# 

# \# Memory Management

# 

# The project uses:

# 

# ```cpp

# std::unique\_ptr

# ```

# 

# for ownership management.

# 

# Benefits:

# 

# \* No manual memory management

# \* No memory leaks

# \* RAII-compliant design

# 

# \---

# 

# \# Testing

# 

# The project includes:

# 

# \* 200 automated integration tests

# \* Parser validation tests

# \* Persistence tests

# \* History tests

# \* Stress tests

# \* Valgrind memory checks

# \* AddressSanitizer checks

# 

# Validation includes:

# 

# ```text

# 0 memory leaks

# 0 invalid reads

# 0 invalid writes

# ```

# 

# Valgrind result:

# 

# ```text

# All heap blocks were freed -- no leaks are possible

# ERROR SUMMARY: 0 errors

# ```

# 

# \---

# 

# \# Build

# 

# ```bash

# g++ -std=c++17 \\

# &#x20;   -Wall -Wextra \\

# &#x20;   -pedantic \\

# &#x20;   src/\*.cpp \\

# &#x20;   -Iinclude \\

# &#x20;   -o mini\_redis

# ```

# 

# Run:

# 

# ```bash

# ./mini\_redis

# ```

# 

# \---

# 

# \# Future Improvements

# 

# Potential extensions:

# 

# \* Expiration (TTL)

# \* Transactions

# \* Publish / Subscribe

# \* Multiple databases

# \* Network server mode

# \* Concurrent access

# \* Snapshot persistence

# \* AOF logging

# \* Custom hashing strategies

# 

# \---

# 

# \# Skills Demonstrated

# 

# \* C++

# \* STL

# \* OOP

# \* SOLID Principles

# \* Design Patterns

# \* Parsing

# \* File I/O

# \* Memory Management

# \* Testing

# \* Software Architecture

# \* Data Structures

# \* Complexity Analysis

# 

# \---

# 

# \# Author

# 

# Mohammed AbuSalih

# 

# Computer Science Student

# 

# Project Goal:

# 

# Build a Redis-inspired database while emphasizing software engineering practices, clean architecture, extensibility, and modern C++ design.

# 

