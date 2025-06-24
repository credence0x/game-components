# Game Components Test - Dojo

This package contains Dojo-based tests and mocks for the game components library.

## Purpose

This package is designed to test components using Dojo's model storage system. It includes:

- Dojo-based mock contracts for minigame and metagame components
- Test models using Dojo's storage system
- Integration tests with Dojo world functionality

## Dependencies

- Dojo framework
- Starknet
- OpenZeppelin contracts

## Structure

- `src/minigame/` - Minigame component tests using Dojo models
- `src/metagame/` - Metagame component tests using Dojo models

## Usage

Use this package when you need to test components in a Dojo environment or when your contract implementations use Dojo models for storage.

```bash
cd packages/test_dojo
scarb build
```

To run Dojo tests:
```bash
sozo test
``` 