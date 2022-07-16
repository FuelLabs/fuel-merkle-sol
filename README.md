# Fuel Solidity Merkle Trees

<!-- Disable markdownlint for long lines. -->
<!-- markdownlint-disable-file MD013 -->

![ci](https://github.com/fuellabs/fuel-v2-contracts/workflows/Node.js%20Tests%20and%20Coverage/badge.svg?branch=master)
[![NPM Package](https://img.shields.io/npm/v/fuel-merkle-sol)](https://www.npmjs.org/package/fuel-merkle-sol)

A Solidity implementation of a binary Merkle tree (specifically, a Merkle Mountain Range), a sparse Merkle tree, and a Merkle sum tree.

## Building From Source

### Dependencies

| dep     | version                                                  |
| ------- | -------------------------------------------------------- |
| Node.js | [>=v14.0.0](https://nodejs.org/en/blog/release/v14.0.0/) |

### Building

Install dependencies:

```sh
npm ci
```

Build and run tests:

```sh
npm run build
npm test
```

## Contributing

Code must be formatted and linted.

```sh
npm run format
npm run lint
```

## License

The primary license for this repo is `Apache-2.0`, see [`LICENSE`](./LICENSE).
