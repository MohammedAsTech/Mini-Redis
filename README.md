# Mini Redis

> A Redis-inspired in-memory key-value database implemented in Modern C++ using the Command Design Pattern.

![Language](https://img.shields.io/badge/language-C%2B%2B17-blue)
![Architecture](https://img.shields.io/badge/design-command%20pattern-green)
![Testing](https://img.shields.io/badge/tests-200%2B-success)
![Memory](https://img.shields.io/badge/valgrind-clean-success)

---

## Overview

Mini Redis is a lightweight Redis-inspired database built from scratch in C++.

The project focuses on software engineering principles rather than raw feature count, emphasizing:

- Object-Oriented Design
- Design Patterns
- Memory Safety
- Extensibility
- File Persistence
- Automated Testing
- Clean Architecture

The database stores key-value pairs in memory and supports common Redis-style operations such as insertion, retrieval, deletion, persistence, and history tracking.

---

## Features

### Database Operations

| Command | Description |
|----------|-------------|
| `SET` | Insert or update a key-value pair |
| `GET` | Retrieve a value |
| `DEL` | Delete a key |
| `EXISTS` | Check whether a key exists |
| `KEYS` | Display all stored keys |
| `RENAME` | Rename an existing key |

### Persistence

| Command | Description |
|----------|-------------|
| `SAVE` | Save database to disk |
| `LOAD` | Load database from disk |

### Utility Commands

| Command | Description |
|----------|-------------|
| `HISTORY` | Show command history |
| `EXIT` | Exit the application |

---

# Example Session

```text
SET name Mohammed
OK

GET name
Mohammed

EXISTS name
true

RENAME name username
renamed

GET username
Mohammed

SAVE db.txt
Database saved

LOAD db.txt
Database loaded
```

---

# Project Structure

```text
MiniRedisProject/
│
├── include/
│   ├── Command.h
│   ├── CommandSons.h
│   ├── Database.h
│   ├── Parser.h
│   └── Persistence.h
│
├── src/
│   ├── CommandSons.cpp
│   ├── Database.cpp
│   ├── Parser.cpp
│   ├── Persistence.cpp
│   └── main.cpp
│
├── tests/
│   ├── test_mini_redis_200.sh
│   └── test_report_200.txt
│
├── README.md
└── CMakeLists.txt
```

---

# Architecture

The system is composed of four main components.

## Database

Responsible for storing all key-value pairs.

Internally:

```cpp
std::unordered_map<std::string, std::string>
```

Responsibilities:

- Store data
- Delete data
- Rename keys
- Manage command history
- Expose entries for persistence

---

## Parser

Converts raw user input into executable command objects.

Example:

```text
SET username Mohammed
```

becomes:

```cpp
SetCommand("username", "Mohammed")
```

The parser uses a registry-based dispatch mechanism:

```cpp
std::unordered_map<std::string,
                   std::unique_ptr<ICommandParser>>
```

This allows new commands to be added without modifying existing parser logic.

---

## Command Layer

The project uses the **Command Design Pattern**.

Each command is represented by its own class:

```text
SetCommand
GetCommand
DelCommand
ExistsCommand
KeysCommand
RenameCommand
SaveCommand
LoadCommand
HistoryCommand
ExitCommand
```

All commands inherit from:

```cpp
class Command
```

and implement:

```cpp
virtual void execute(
    Database& db,
    Persistence& persistence
) = 0;
```

Benefits:

- Separation of concerns
- Extensibility
- Cleaner testing
- Low coupling
- High cohesion

---

## Persistence

Responsible for saving and loading the database.

Responsibilities:

- Serialize database contents
- Deserialize database contents
- Detect corrupted files
- Handle file-related errors

---

# Design Pattern

## Command Pattern

Workflow:

```text
User Input
     │
     ▼
   Parser
     │
     ▼
Command Object
     │
     ▼
 execute()
     │
     ▼
Database / Persistence
```

Advantages:

- Encapsulates behavior
- Makes commands independent
- Simplifies adding new features
- Improves maintainability

---

# Supported Commands

---

## SET

Insert or update a key.

### Syntax

```text
SET <key> <value>
```

### Example

```text
SET username Mohammed
```

### Output

```text
OK
```

### Complexity

| Case | Complexity |
|--------|------------|
| Average | O(1) |
| Worst | O(n) |

---

## GET

Retrieve a value.

### Syntax

```text
GET <key>
```

### Example

```text
GET username
```

### Output

```text
Mohammed
```

Missing key:

```text
(nil)
```

### Complexity

| Case | Complexity |
|--------|------------|
| Average | O(1) |
| Worst | O(n) |

---

## DEL

Delete a key.

### Syntax

```text
DEL <key>
```

### Complexity

| Case | Complexity |
|--------|------------|
| Average | O(1) |
| Worst | O(n) |

---

## EXISTS

Check whether a key exists.

### Syntax

```text
EXISTS <key>
```

### Complexity

| Case | Complexity |
|--------|------------|
| Average | O(1) |
| Worst | O(n) |

---

## KEYS

Display all keys.

### Syntax

```text
KEYS
```

### Complexity

```text
O(n)
```

where:

```text
n = number of stored keys
```

---

## RENAME

Rename a key.

### Syntax

```text
RENAME <oldKey> <newKey>
```

### Complexity

| Case | Complexity |
|--------|------------|
| Average | O(1) |
| Worst | O(n) |

---

## SAVE

Save database contents to disk.

### Syntax

```text
SAVE <filename>
```

### Complexity

```text
O(n)
```

All entries must be written.

---

## LOAD

Load database contents from disk.

### Syntax

```text
LOAD <filename>
```

### Complexity

```text
O(n)
```

All entries must be reconstructed.

---

## HISTORY

Display the last executed commands.

### Syntax

```text
HISTORY
```

History size:

```text
20 commands
```

### Complexity

| Operation | Complexity |
|------------|------------|
| Insert History Entry | O(1) |
| Print History | O(h) |

where:

```text
h ≤ 20
```

---

## EXIT

Exit the application.

### Syntax

```text
EXIT
```

### Complexity

```text
O(1)
```

---

# Error Handling

Handled cases include:

- Unknown commands
- Invalid syntax
- Missing files
- Corrupted files
- Invalid rename operations
- Invalid persistence paths

Examples:

```text
Unknown command
```

```text
Invalid command usage
```

```text
File error
```

```text
Corrupted file
```

---

# Memory Management

The project exclusively uses:

```cpp
std::unique_ptr
```

for ownership management.

Benefits:

- No manual memory management
- RAII-compliant design
- Automatic cleanup
- Memory-safe command dispatch

---

# Testing

The project includes:

- 200+ automated integration tests
- Parser validation tests
- Persistence tests
- History tests
- Stress tests
- AddressSanitizer checks
- Valgrind checks

---

## Valgrind Result

```text
All heap blocks were freed -- no leaks are possible
ERROR SUMMARY: 0 errors
```

---

# Build

## Linux

```bash
g++ -std=c++17 \
    -Wall -Wextra \
    -pedantic \
    src/*.cpp \
    -Iinclude \
    -o mini_redis
```

Run:

```bash
./mini_redis
```

---

# Future Improvements

Potential future features:

- TTL support
- Transactions
- Publish / Subscribe
- Multiple databases
- Networking support
- Concurrent access
- Snapshot persistence
- AOF logging
- Custom hashing strategies

---

# Skills Demonstrated

- Modern C++
- STL
- Object-Oriented Programming
- SOLID Principles
- Design Patterns
- Parsing
- File I/O
- Memory Management
- Testing
- Software Architecture
- Data Structures
- Complexity Analysis

---

# Author

**Mohammed AbuSalih**

Computer Science Student

Built as a portfolio project to demonstrate software engineering fundamentals, clean architecture, and modern C++ development practices.
