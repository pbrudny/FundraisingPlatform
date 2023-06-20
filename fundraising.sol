// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Import the stable coin token contract interface (assuming ERC-20)
import "./IERC20.sol";

contract FundraisingPlatform {
    address public owner;
    uint256 public projectId;

    struct Project {
        string name;
        uint256 maxCapacity;
        address stableCoin; //we need stable coin address? Maybe we need multiple stable coins per project?
        mapping(address => uint256) investorTransfers;
    }

    mapping(address => bool) public clients;
    mapping(uint256 => Project) public projects;

    event ClientAdded(address client);
    event ProjectCreated(uint256 projectId, string name, uint256 maxCapacity, address stableCoin);
    event MaxCapacityUpdated(uint256 projectId, uint256 newMaxCapacity);
    event StableCoinTransferred(uint256 projectId, address indexed investor, uint256 amount);
    event FundsTransferred(uint256 projectId, address indexed client, uint256 amount);

    // TODO: maybe I should use ready modifier
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
        clients[client] = true; // this way it is cheaper to check clients
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

    // allow client to update max capacity
    function updateMaxCapacity(uint256 projectId, uint256 newMaxCapacity) external onlyClient {
        //make sure the projectId is correct
        require(projects[projectId].stableCoin != address(0), "Invalid project ID");
        require(newMaxCapacity > 0, "Invalid max capacity");

        projects[projectId].maxCapacity = newMaxCapacity;
        emit MaxCapacityUpdated(projectId, newMaxCapacity);
    }

    function transferStableCoins(uint256 projectId, uint256 amount) external {
        require(projects[projectId].stableCoin != address(0), "Invalid project ID");
        require(amount > 0, "Invalid transfer amount");

        IERC20 stableCoinToken = IERC20(projects[projectId].stableCoin);

        // to do the real transfer on stablecoin
        // so that fundraising contract address gets funds
        stableCoinToken.transferFrom(msg.sender, address(this), amount);

        //to keep track of investments
        projects[projectId].investorTransfers[msg.sender] += amount;
        emit StableCoinTransferred(projectId, msg.sender, amount);
    }

    // what is that function for?
    function transferFunds(uint256 projectId, uint256 amount) external onlyClient {
        require(projects[projectId].stableCoin != address(0), "Invalid project ID");
        require(amount > 0, "Invalid transfer amount");
        require(projects[projectId].investorTransfers[msg.sender] >= amount, "Insufficient funds");

        IERC20 stableCoinToken = IERC20(projects[projectId].stableCoin);
        // client transfer coins from smart-contract account to his own
        stableCoinToken.transfer(msg.sender, amount);

        //it has to update the state of funds for given client's project
        projects[projectId].investorTransfers[msg.sender] -= amount;
        emit FundsTransferred(projectId, msg.sender, amount);
    }
}
