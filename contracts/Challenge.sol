//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Token is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        // Mint 100 tokens to msg.sender
        // Similar to how
        // 1 dollar = 100 cents
        // 1 token = 1 * (10 ** decimals)
        _mint(msg.sender, 100 * 10**uint(decimals()));
    }
}

contract Ownable {
    address public owner;
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    function changeOwner(address newOwner) external onlyOwner {
        require(newOwner != address(0), "zero address");
        owner = newOwner;
    }
}

contract ContractA is Ownable {
    using SafeERC20 for IERC20;

    ContractB public b;

    constructor() {
        owner = msg.sender;
    }

    function deposit(IERC20 token, uint amount) public {
        require(address(b) != address(0), "Contract B is not set");
        require(amount > 0, "You need to deposit at least some tokens");
        token.safeTransferFrom(msg.sender, address(this), amount);
        b.addRecord(msg.sender, address(token), amount);
    }

    function setB(ContractB newB) external onlyOwner {
        require(address(newB) != address(0), "zero address");
        b = newB;
    }
}

contract ContractB is Ownable {
    ContractA public a; // mutable address of Contract A

    struct Record {
        address user;
        address token;
        uint amount;
    }

    Record[] public records;

    constructor() {
        owner = msg.sender;
    }

    function recordsLength() external view returns (uint) {
        return records.length;                             
    }                                                       

    function _addRecord(address _user, address _token, uint _amount) internal {
        require(_amount > 0, "You need to deposit at least some tokens");
        records.push(Record({
            user: _user,
            token: _token,
            amount: _amount
        }));
    }

    // AND also include another function that allows an admin user 
    // (the deployer of this contract) to manually add in new deposits
    function ownerAddRecord(
        address _user,
        address _token,
        uint _amount
    ) external onlyOwner {
        _addRecord(_user, _token, _amount);
    }

    // add record from contract A
    function addRecord(
        address _user,
        address _token,
        uint _amount
    ) public {
        //contract B should only be writable by 1 admin user (the deployer) and contract A
        require(msg.sender == address(a), "invalid writer");
        _addRecord(_user, _token, _amount);
    }

    function setA(ContractA newA) external onlyOwner {
        require(address(newA) != address(0), "zero address");
        a = newA;
    }
}
