// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
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

    modifier onlyClient() {
        require(clients[msg.sender], "Only authorized clients can perform this action");
        _;
    }

    function addClient(address _client) external onlyOwner {
        require(_client != address(0), "Invalid client address");
        clients[_client] = true;
        emit ClientAdded(_client);
    }

    function createProject(string memory _name, uint256 _maxCapacity) external onlyClient {
        require(_maxCapacity > 0, "Invalid max capacity");

        projectId++;
        projects[projectId].name = _name;
        projects[projectId].maxCapacity = _maxCapacity;
        emit ProjectCreated(projectId, _name, _maxCapacity);
    }

    function updateMaxCapacity(uint256 _projectId, uint256 _newMaxCapacity) external onlyClient {
        require(projects[_projectId].maxCapacity > 0, "Invalid project ID");
        require(_newMaxCapacity > 0, "Invalid max capacity");

        projects[_projectId].maxCapacity = _newMaxCapacity;
        emit MaxCapacityUpdated(_projectId, _newMaxCapacity);
    }

    function addStableCoin(uint256 _projectId, address _stableCoin) external onlyClient {
        require(projects[_projectId].maxCapacity > 0, "Invalid project ID");
        require(_stableCoin != address(0), "Invalid stable coin address");

        projects[_projectId].acceptedStableCoins[_stableCoin] = true;
    }

    function transferStableCoins(uint256 _projectId, address _stableCoin, uint256 _amount) external {
        require(projects[_projectId].maxCapacity > 0, "Invalid project ID");
        require(_amount > 0, "Invalid transfer amount");

        require(projects[_projectId].acceptedStableCoins[_stableCoin], "Invalid stable coin for the project");

        IERC20(_stableCoin).safeTransferFrom(msg.sender, address(this), _amount);
        projects[_projectId].investorTransfers[msg.sender] += _amount;
        emit StableCoinTransferred(_projectId, msg.sender, _stableCoin, _amount);
    }

    function transferFunds(uint256 _projectId, address _stableCoin, uint256 _amount) external onlyClient {
        require(projects[_projectId].maxCapacity > 0, "Invalid project ID");
        require(_amount > 0, "Invalid transfer amount");
        require(projects[_projectId].investorTransfers[msg.sender] >= _amount, "Insufficient funds");

        require(projects[_projectId].acceptedStableCoins[_stableCoin], "Invalid stable coin for the project");

        IERC20(_stableCoin).safeTransfer(msg.sender, _amount);
        projects[_projectId].investorTransfers[msg.sender] -= _amount;
        emit FundsTransferred(_projectId, msg.sender, _stableCoin, _amount);
    }
}
