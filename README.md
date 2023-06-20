# FundraisingPlatform Smart Contract

The FundraisingPlatform is a Solidity smart contract that allows clients to create fundraising projects where investors can transfer stable coins. The contract provides functionality for creating projects, accepting multiple stable coins, transferring stable coins from investors, and transferring funds from projects to clients.

## Features

- Multiple clients can create fundraising projects.
- Each project has a name, maximum capacity, and list of accepted stable coins.
- Investors can transfer stable coins to a selected project.
- Clients can transfer funds from projects to their own account.
- Access control ensures that only authorized clients can perform specific actions.

## Usage

1. Deploy the FundraisingPlatform contract on an Ethereum network.
2. Add clients by calling the `addClient` function, specifying the client address.
3. Clients can create projects using the `createProject` function, providing the project name and maximum capacity.
4. Add accepted stable coins to a project using the `addStableCoin` function, specifying the project ID and stable coin address.
5. Investors can transfer stable coins to a project by calling the `transferStableCoins` function, providing the project ID, stable coin address, and transfer amount.
6. Clients can transfer funds from a project to their own account using the `transferFunds` function, specifying the project ID, stable coin address, and transfer amount.

