//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";

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

contract ContractA {
    address public admin;
    ContractB public b;

    constructor() {
        admin = msg.sender;
    }

     modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin");
        _;
     }

    function deposit(IERC20 token, uint amount) public {
        //TODO: test
        require(address(b) != address(0x0), "B is not set");
        require(amount > 0, "You need to deposit at least some tokens");
        require(token.allowance(msg.sender, address(this)) >= amount, "allowance too low");
        _safeTransferFrom(token, msg.sender, address(this), amount);
        b.record(msg.sender, address(token), amount);
    }

    function _safeTransferFrom(
        IERC20 token,
        address sender,
        address receipent,
        uint amount
    ) private {
        bool sent = token.transferFrom(sender, receipent, amount);
        require(sent, "Token transfer failed");
    }

    function changeAdmin(address newAdmin) external onlyAdmin {
        //TODO: this needed?
        require(newAdmin != address(0x0), "New admin must not be empty");
        admin = newAdmin;
    }

    function setB(ContractB newB) external onlyAdmin {
        require(address(newB) != address(0x0), "New B must not be empty");
        b = newB;
    }
}

contract ContractB {
    address public admin;
    ContractA public a;

    struct Record {
        address user;
        address token;
        uint amount;
    }

    Record[] public records;

    constructor() {
        admin = msg.sender;
    }

    function getRecord(uint _index) public view returns(Record memory) {
        return records[_index];
    }

    function countRecord() public view returns(uint) {
        return records.length;
    }


    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin");
        _;
    }

    // only ContractA use record() and admin use manualDeposit()
    function record(
        address _user,
        address _token,
        uint _amount
    ) public {
        // contract B should only be writable by 1 admin user (the deployer) and contract A
        require(msg.sender == address(a), "invalid writer");
        require(_amount > 0, "You need to deposit at least some tokens");

        records.push(Record({
            user: _user,
            token: _token,
            amount: _amount
        }));
    }

    function changeAdmin(address newAdmin) external onlyAdmin {
        //TODO: this needed?
        require(newAdmin != address(0x0), "New admin must not be empty");
        admin = newAdmin;
    }

    function setA(ContractA newA) external onlyAdmin {
        require(address(newA) != address(0x0), "New A must not be empty");
        a = newA;
    }
}
