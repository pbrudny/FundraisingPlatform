// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract FundraisingPlatform is Ownable {
    using SafeERC20 for IERC20;

    uint256 public projectId;

    struct Project {
        string name;
        uint256 maxCapacity;
        mapping(address => bool) acceptedStableCoins;
        mapping(address => uint256) investorTransfers;
    }

    mapping(address => bool) public clients;
    mapping(uint256 => Project) public projects;

    event ClientAdded(address client);
    event ProjectCreated(uint256 projectId, string name, uint256 maxCapacity);
    event MaxCapacityUpdated(uint256 projectId, uint256 newMaxCapacity);
    event StableCoinTransferred(uint256 projectId, address indexed investor, address stableCoin, uint256 amount);
    event FundsTransferred(uint256 projectId, address indexed client, address stableCoin, uint256 amount);

    constructor() {}

    // Assumptions that we only add clients and clients could create projects themselves
    function addClient(address client) external onlyOwner {
        require(client != address(0), "Invalid client address");
        clients[client] = true;
        emit ClientAdded(client);
    }

    function createProject(string memory name, uint256 maxCapacity) external onlyClient {
        require(maxCapacity > 0, "Invalid max capacity");

        projectId++;
        projects[projectId] = Project(name, maxCapacity);
        emit ProjectCreated(projectId, name, maxCapacity);
    }

    function updateMaxCapacity(uint256 projectId, uint256 newMaxCapacity) external onlyClient {
        require(projects[projectId].maxCapacity > 0, "Invalid project ID");
        require(newMaxCapacity > 0, "Invalid max capacity");

        projects[projectId].maxCapacity = newMaxCapacity;
        emit MaxCapacityUpdated(projectId, newMaxCapacity);
    }

    function addStableCoin(uint256 projectId, address stableCoin) external onlyClient {
        require(projects[projectId].maxCapacity > 0, "Invalid project ID");
        require(stableCoin != address(0), "Invalid stable coin address");

        projects[projectId].acceptedStableCoins[stableCoin] = true;
    }

    function transferStableCoins(uint256 projectId, address stableCoin, uint256 amount) external {
        require(projects[projectId].maxCapacity > 0, "Invalid project ID");
        require(amount > 0, "Invalid transfer amount");

        require(projects[projectId].acceptedStableCoins[stableCoin], "Invalid stable coin for the project");

        IERC20(stableCoin).safeTransferFrom(msg.sender, address(this), amount);
        projects[projectId].investorTransfers[msg.sender] += amount;
        emit StableCoinTransferred(projectId, msg.sender, stableCoin, amount);
    }

    function transferFunds(uint256 projectId, address stableCoin, uint256 amount) external onlyClient {
        require(projects[projectId].maxCapacity > 0, "Invalid project ID");
        require(amount > 0, "Invalid transfer amount");
        require(projects[projectId].investorTransfers[msg.sender] >= amount, "Insufficient funds");

        require(projects[projectId].acceptedStableCoins[stableCoin], "Invalid stable coin for the project");

        IERC20(stableCoin).safeTransfer(msg.sender, amount);
        projects[projectId].investorTransfers[msg.sender] -= amount;
        emit FundsTransferred(projectId, msg.sender, stableCoin, amount);
    }

    function onlyClient() internal view {
        require(clients[msg.sender], "Only authorized clients can perform this action");
    }
}
