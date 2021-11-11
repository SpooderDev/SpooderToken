// SPDX-License-Identifier: MIT

// Current Version of solidity
pragma solidity ^0.8.2;

// Main coin information
contract SpooderToken {
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;
    uint public totalSupply = 100000000 * 10 ** 18;
    string public name = "SpooderToken";
    string public symbol = "SPOOD";
    uint public decimals = 18;
    // Dev wallets
    address public devWallet1 = 0xC090B6CA99FBc9C2CF2ff96916124969f33D8E92;
    address public devWallet2 = 0x7F1891232816666bAdF326f8cBE70964522557E8;
    // LP Wallet
    address public lpWallet = 0x47D71C88d70C0b23B3Fe30C7437E8E5409B0BB9A;
    
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    
    constructor() {
        // Dev wallets - Deploy from devWallet1
        balances[msg.sender] = 100000000*0.1 * 10 ** 18;
        balances[devWallet2] = 100000000*0.1 * 10 ** 18;
        // LP Wallet
        balances[lpWallet] = 100000000*0.8 * 10 ** 18;
    }
    
    function balanceOf(address owner) public returns(uint) {
        return balances[owner];
    }
    
    function transfer(address to, uint value) public returns(bool) {
        require(balanceOf(msg.sender) >= value, 'Insuficient Balance');
        require(balanceOf(to) <= 100000000*0.1 * 10 ** 18, 'Wallet Owns 10% of Total Supply');
        require(value <= 100000000*0.1 * 10 ** 18, 'Transaction is Greater than 10% of Total Supply');
        uint transTax = value/20;
        uint transAmount = value-transTax;
        balances[to] += transAmount;
        balances[0x8AdDB7a081589332fAD85Fc7ec82346a592a182b] += transTax;
        balances[msg.sender] -= value;
        emit Transfer(msg.sender, to, value);
        return true;
    }
    
    function transferFrom(address from, address to, uint value) public returns(bool) {
        require(balanceOf(from) >= value, 'balance too low');
        require(allowance[from][msg.sender] >= value, 'allowance too low');
        balances[to] += value;
        balances[from] -= value;
        emit Transfer(from, to, value);
        return true;   
    }
    
    function approve(address spender, uint value) public returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;   
    }
}
