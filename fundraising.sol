// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Import the stable coin token contract interface (assuming ERC-20)
import "./IERC20.sol";

// TODO: Use OpenZeppelin libs
contract FundraisingPlatform {
    address public owner;
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
    event StableCoinAdded(uint256 projectId, address stableCoin);
    event MaxCapacityUpdated(uint256 projectId, uint256 newMaxCapacity);
    event StableCoinTransferred(uint256 projectId, address indexed investor, address stableCoin, uint256 amount);
    event FundsTransferred(uint256 projectId, address indexed client, address stableCoin, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only contract owner can perform this action");
        _;
    }

    modifier onlyClient() {
        require(clients[msg.sender], "Only authorized clients can perform this action");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function addClient(address client) external onlyOwner {
        require(client != address(0), "Invalid client address");
        require(!clients[client], "Client already exists");
        clients[client] = true;
        emit ClientAdded(client);
    }

    function createProject(
        string memory name,
        uint256 maxCapacity
    ) external onlyClient {
        require(maxCapacity > 0, "Invalid max capacity");

        projectId++;
        projects[projectId] = Project(name, maxCapacity);
        emit ProjectCreated(projectId, name, maxCapacity);
    }

    function addStableCoin(uint256 projectId, address stableCoin) external onlyClient {
        require(stableCoin != address(0), "Invalid stable coin address");
        projects[projectId].acceptedStableCoins[stableCoin] = true;
        emit StableCoinAdded(projectId, stableCoin);
    }

    function updateMaxCapacity(uint256 projectId, uint256 newMaxCapacity) external onlyClient {
        require(projects[projectId].maxCapacity > 0, "Invalid project ID");
        require(newMaxCapacity > 0, "Invalid max capacity");

        projects[projectId].maxCapacity = newMaxCapacity;
        emit MaxCapacityUpdated(projectId, newMaxCapacity);
    }

    function transferStableCoins(uint256 projectId, address stableCoin, uint256 amount) external {
        require(projects[projectId].maxCapacity > 0, "Invalid project ID");
        require(amount > 0, "Invalid transfer amount");
        require(projects[projectId].acceptedStableCoins[stableCoin], "Invalid stable coin for the project");

        IERC20 stableCoinToken = IERC20(stableCoin);
        stableCoinToken.transferFrom(msg.sender, address(this), amount);
        projects[projectId].investorTransfers[msg.sender] += amount;
        emit StableCoinTransferred(projectId, msg.sender, stableCoin, amount);
    }

    function transferFunds(uint256 projectId, address stableCoin, uint256 amount) external onlyClient {
        require(projects[projectId].maxCapacity > 0, "Invalid project ID");
        require(amount > 0, "Invalid transfer amount");
        require(projects[projectId].investorTransfers[msg.sender] >= amount, "Insufficient funds");
        require(projects[projectId].acceptedStableCoins[stableCoin], "Invalid stable coin for the project");

        IERC20 stableCoinToken = IERC20(stableCoin);
        stableCoinToken.transfer(msg.sender, amount);
        projects[projectId].investorTransfers[msg.sender] -= amount;
        emit FundsTransferred(projectId, msg.sender, stableCoin, amount);
    }
}
