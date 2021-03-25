# Fuel Solidity Contracts

<!-- Disable markdownlint for long lines. -->
<!-- markdownlint-disable-file MD013 -->

![ci](https://github.com/fuellabs/fuel-sol/workflows/Node.js%20Tests%20and%20Coverage/badge.svg?branch=master)
[![codecov](https://codecov.io/gh/fuellabs/fuel-sol/branch/master/graph/badge.svg?token=FVXeaaBA3d)](https://codecov.io/gh/fuellabs/fuel-sol)

The Fuel Solidity smart contract architecture.

## Dependencies

- [Node.js](https://nodejs.org/en/blog/release/v14.0.0/)

## Install

```sh
npm install
```

## Tasks

Build the project

```sh
npm run build
```

Run tests

```sh
npm test
```

Lint solidity and typescript code

```sh
npm run lint
```

Check file formatting

```sh
npm run format
```

Generate code coverage

```sh
npm run coverage
```

## License

The primary license for this repo is `Apache-2.0`, see [`LICENSE`](./LICENSE).

### Exceptions

- [`SafeCast.sol`](./contracts/utils/SafeCast.sol) is licensed under `MIT` (as indicated in the SPDX header) by [OpenZeppelin](https://github.com/OpenZeppelin/openzeppelin-contracts).
