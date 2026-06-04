# Mini Redis

A Redis-inspired in-memory key-value database built in Modern C++.

This project recreates a simplified version of Redis to demonstrate software engineering fundamentals including object-oriented design, design patterns, parsing, persistence, and memory-safe programming.

---

## What is Redis?

Redis is a high-performance in-memory database commonly used for:

- Caching
- Session storage
- Real-time applications
- Message queues
- Fast key-value lookups

Unlike traditional databases, Redis stores data primarily in memory, allowing extremely fast access times.

---

## What does this project implement?

This Mini Redis supports a subset of Redis-like functionality.

### Data Operations

- `SET` – Create or update values
- `GET` – Retrieve values
- `DEL` – Delete keys
- `EXISTS` – Check whether a key exists
- `KEYS` – Display all stored keys
- `RENAME` – Rename existing keys

### Persistence

- `SAVE` – Save database state to disk
- `LOAD` – Restore database state from disk

### Utility

- `HISTORY` – Display recently executed commands
- `EXIT` – Terminate the application

---

## Example Session

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

## Architecture

The project is divided into four main components.

### Database

Stores key-value pairs using:

```cpp
std::unordered_map<std::string, std::string>
```

### Parser

Converts raw user input into executable command objects.

Example:

```text
SET username Mohammed
```

becomes:

```cpp
SetCommand("username", "Mohammed")
```

### Command System

Uses the **Command Design Pattern**.

Each command is implemented as an independent class:

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

### Persistence

Responsible for saving and loading database contents from disk.

---

## Time Complexity

| Command | Average Complexity |
|----------|----------|
| SET | O(1) |
| GET | O(1) |
| DEL | O(1) |
| EXISTS | O(1) |
| RENAME | O(1) |
| KEYS | O(n) |
| SAVE | O(n) |
| LOAD | O(n) |
| HISTORY | O(h), h ≤ 20 |
| EXIT | O(1) |

> `n` = number of stored keys

---

## Error Handling

The application handles:

- Unknown commands
- Invalid command syntax
- Missing files
- Corrupted files
- Invalid rename operations
- Invalid persistence paths

Example outputs:

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

## Testing

The project includes:

- 200+ automated integration tests
- Parser validation tests
- Persistence tests
- Stress tests
- AddressSanitizer checks
- Valgrind memory checks

Valgrind result:

```text
All heap blocks were freed -- no leaks are possible
ERROR SUMMARY: 0 errors
```

---

## Build

### Linux

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

## Skills Demonstrated

- Modern C++
- STL
- Object-Oriented Programming
- Design Patterns
- Parsing
- File I/O
- Memory Management
- Testing
- Software Architecture
- Complexity Analysis

---

## Future Improvements

- TTL (Time-To-Live) support
- Transactions
- Networking support
- Multi-database support
- Concurrent access
- Snapshot persistence

---

## Author

**Mohammed AbuSalih**

Computer Science Student

Built as a learning project to explore database internals, software architecture, and modern C++ design.
