// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Import the stable coin token contract interface (assuming ERC-20)
import "./IERC20.sol";

contract FundraisingPlatform {
    address public owner; //for Presail
    uint256 public projectId;

    struct Project {
        string name;
        uint256 maxCapacity; //that should be editable
        address stableCoin; //we need stable coin address
        mapping(address => uint256) investorTransfers;
    }

    mapping(address => bool) public clients;
    mapping(uint256 => Project) public projects;

    event ClientAdded(address client);
    event ProjectCreated(uint256 projectId, string name, uint256 maxCapacity, address stableCoin);
    event StableCoinTransferred(uint256 projectId, address indexed investor, uint256 amount);
    event FundsTransferred(uint256 projectId, address indexed client, uint256 amount);

    // TODO: maybe I should you ready function
    modifier onlyOwner() {
        require(msg.sender == owner, "Only contract owner can perform this action");
        _;
    }

    modifier onlyClient() {
        require(clients[msg.sender], "Only authorized clients can perform this action");
        _;
    }

    //TODO: is that all we need/
    constructor() {
        owner = msg.sender;
    }

    function addClient(address client) external onlyOwner {
        require(client != address(0), "Invalid client address");
        require(!clients[client], "Client already exists");
        clients[client] = true; // this way is
        emit ClientAdded(client);
    }

    function createProject(
        string memory name,
        uint256 maxCapacity,
        address stableCoin
    ) external onlyClient {
        require(maxCapacity > 0, "Invalid max capacity");
        require(stableCoin != address(0), "Invalid stable coin address");

        projectId++;
        projects[projectId] = Project(name, maxCapacity, stableCoin);
        emit ProjectCreated(projectId, name, maxCapacity, stableCoin);
    }

    // TODO: make sure that only proper client could do actions
    function transferStableCoins(uint256 projectId, uint256 amount) external {
        require(projects[projectId].stableCoin != address(0), "Invalid project ID");
        require(amount > 0, "Invalid transfer amount");

        IERC20 stableCoinToken = IERC20(projects[projectId].stableCoin);
        stableCoinToken.transferFrom(msg.sender, address(this), amount);
        projects[projectId].investorTransfers[msg.sender] += amount;
        emit StableCoinTransferred(projectId, msg.sender, amount);
    }

    function transferFunds(uint256 projectId, uint256 amount) external onlyClient {
        require(projects[projectId].stableCoin != address(0), "Invalid project ID");
        require(amount > 0, "Invalid transfer amount");
        require(projects[projectId].investorTransfers[msg.sender] >= amount, "Insufficient funds");

        IERC20 stableCoinToken = IERC20(projects[projectId].stableCoin);
        stableCoinToken.transfer(msg.sender, amount);
        projects[projectId].investorTransfers[msg.sender] -= amount;
        emit FundsTransferred(projectId, msg.sender, amount);
    }
}
