// SPDX-License-Identifier: MIT


// Current Version of solidity
pragma solidity ^0.8.2;

// Spooder Interface
interface SpooderToken {
    function allowance() external view returns (uint);
    function totalSupply() external view returns (uint);
    function decimals() external view returns (uint);
    function devWallet1() external view returns (address);
    function devWallet2() external view returns (address);
    function lpWallet() external view returns (address);
    function taxWallet() external view returns (address);
    function balanceOf(address) external returns(uint);
    function transfer(address, uint) external returns(bool);
    function transferFrom(address, address, uint) external returns(bool);
    function approve(address, uint) external returns (bool);
}

// Main Contract
contract SpooderWeb {
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;
    
    uint public totalSupply = 100000000 * 10 ** 18;
    string public name = "Spooder Web";
    string public symbol = "WEB";
    uint public decimals = 18;
    uint public totalWebbed = 0;
    // Tax Wallet
    address public taxWallet = 0x8AdDB7a081589332fAD85Fc7ec82346a592a182b;
    // Web Wallet
    address public webWallet = 0xc3aD2641e14E0D87F29f6c1cAC5579B502bc511e;
    // SPOOD Contract address
    address public contractSPOOD = 0xba51A671F55fddCFbb2B470A8619dB528a8Dc558;
    address public contractWEB;
    address[] public usersWebbed;
    address public user;
    uint public userReward;
    uint public rewardVectorLength = 0;
    uint256 public minWebSPOOD = 100000 * (10 ** 18);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    
    event Web(address indexed from, uint value);
    event UnWeb(address indexed to, uint value);
    event UpdateRewards(uint value);

    constructor() {
        // Web Wallet
        balances[webWallet] = 100000000 * 10 ** 18;
        contractWEB = address(this);
    }

    // EXECUTE THESE FUNCTIONS TO PROVIDE LP
    function WebSPOOD(uint value) public returns(bool) {
        // Require provide amount balance of SPOOD
        require(SpooderToken(contractSPOOD).balanceOf(msg.sender) >= value, 'Insuficient Balance');
        require(msg.sender != webWallet,'Webbing Wallet Cannot Web or UnWeb Tokens');
        // Require minimum Web transaction size
        require(value >= minWebSPOOD, 'Amount is below WebPools minimum transaction size');
        
        // approve contract address for Webbing value on user wallet first
        
        // Transfer SPOOD to Webbing Wallet
        SpooderToken(contractSPOOD).transferFrom(msg.sender, webWallet, value);
        // Transfer WEB to user
        balances[msg.sender] += value;
        balances[webWallet] -= value;
        // Increase total Webbed
        totalWebbed += value;
        // Make sure address has been added to reward list
        bool webCheck = false;
        if (usersWebbed.length == 0) {
            usersWebbed.push(msg.sender);
        }
        for (uint i = 0; i < usersWebbed.length; i++) {
            user = usersWebbed[i];
            if (user == msg.sender) {
                webCheck = true;
                break;
            }
        }
        if (webCheck == false) {
            // Put new address at end
            usersWebbed.push(msg.sender);
        }
        emit Web(msg.sender, value);
        return true;
    }
    // EXECUTE THIS FUNCTION TO REMOVE LP
    function UnWebSPOOD(uint value) public returns(bool) {
        // Require UnWeb amount balance of WEB
        require(balanceOf(msg.sender) >= value, 'Insuficient Balance');
        require(msg.sender != webWallet,'Webbing Wallet Cannot Web or UnWeb Tokens');
        
        // approve contract address on SPOOD Web wallet after deployment

        // Trasnfer SPOOD to user
        SpooderToken(contractSPOOD).transferFrom(webWallet, msg.sender, value);
        // Transfer WEB to Webbing Wallet
        balances[webWallet] += value;
        balances[msg.sender] -= value;
        // Decrease total webbed
        totalWebbed -= value;
        emit UnWeb(msg.sender, value);
        return true;
    }
    
    // EXECUTE THIS FUNCTION TO SEND SPOOD FROM TAX WALLET AND DISRIBUTE AS WEB
    // CALL FROM TAX WALLET
    // ADD TAX-WEB WALLET CONNECTION CONTRACT TO ALSO DISTRIBUTE LP TOKENS
    function updateRewards(uint value) public returns(bool) {
        require(msg.sender == taxWallet,'Only the Tax Wallet can distribute webbing rewards');
        rewardVectorLength = usersWebbed.length;
        require(rewardVectorLength > 0,'No Webbers');
        
        // approve contract address for SPOOD transfer value from tax wallet first
        
        // Transfer SPOOD from tax wallet to Webbing wallet
        SpooderToken(contractSPOOD).transferFrom(taxWallet, webWallet, value);
        
        // Distribute rewards through WEB
        for (uint i = 0; i < rewardVectorLength; i++) {
            // Calculate percantage of reward per wallet
            user = usersWebbed[i];
            userReward = uint(value*balanceOf(user)/totalWebbed);
            // Transfer WEB to user
            balances[user] += userReward;
            balances[webWallet] -= userReward;
            // Increase total webbed
            totalWebbed += userReward;
        }
        emit UpdateRewards(value);
        return true;
    }
    
    function balanceOf(address owner) public returns(uint) {
        return balances[owner];
    }
    
    function transfer(address to, uint value) public returns(bool) {
        require(balanceOf(msg.sender) >= value, 'Insuficient Balance');
        // Only allow transfers between Staking Wallet and user, no user to user transfers.
        if (msg.sender != webWallet) {
            require(to == webWallet,'You can only send SILK to and from the SPOOD Staking Wallet');
        }
        balances[to] += value;
        balances[msg.sender] -= value;
        emit Transfer(msg.sender, to, value);
        return true;
    }
    
    function transferFrom(address from, address to, uint value) public returns(bool) {
        require(balanceOf(from) >= value, 'balance too low');
        require(allowance[from][msg.sender] >= value, 'allowance too low');
        // Only allow transfers between Staking Wallet and user, no user to user transfers.
        if (msg.sender != webWallet) {
            require(to == webWallet,'You can only send SILK to and from the SPOOD Staking Wallet');
        }
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

    function setMinSPOOD(uint256 newMin) public returns (bool)  {
        require(msg.sender == webWallet,'Only the Web Wallet can change Web Minimums');
        minWebSPOOD = newMin;
        return true;
    }
    
}
