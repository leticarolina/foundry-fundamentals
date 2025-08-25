// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract ManualToken {
    //---------------OWNER
    address i_owner;
    modifier onlyOwner() {
        require(msg.sender == i_owner, "Only owner");
        _;
    }

    //---------------ERC STATES
    mapping(address => uint256) private s_balances; //how many tokens each address holds
    mapping(address => mapping(address => uint256)) private s_allowance; //how much "spender" can pull from "owner"
    uint256 private s_totalSupply;
    //function totalSupply same as the variable
    // function totalSupply() public pure returns (uint256) {
    //     return 100;
    // }

    //-----------EVENTS
    // Emitted on transfers (including mint from 0x0 and burn to 0x0 by convention).
    event Transfer(address indexed from, address indexed to, uint256 value);
    // Emitted when an approval (allowance) is set OR change
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    //----------CONSTRUCTOR
    //setting the owner of the contract and initialSupply Tokens to mint
    constructor(uint256 initialSupply) {
        i_owner = msg.sender;
        if (initialSupply > 0) {
            _mint(msg.sender, initialSupply);
        }
    }

    //----------- METADATA
    string public constant name = "Manual Token";
    uint8 public constant decimals = 18;
    string public constant symbol = "MT";

    //by creating the function it would do the same as the variables does
    // function name() public pure returns (string memory) {
    //     return "Manual Token";
    // }

    // function decimals() public pure returns (uint8) {
    //     return 18;
    // }

    //---------- CORE WRITE FUNCTIONS

    //Moves `amount` tokens from msg.sender to `to`.
    function transfer(address to, uint256 amount) public returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    //set spender’s allowance, Overwrites previous allowance.
    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    //Spender pulls `amount` tokens from `from` and sends to `to`,deducting from the spender's allowance
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public returns (bool) {
        _spendAllowance(from, msg.sender, amount);
        _transfer(from, to, amount);
        return true;
    }

    // function transfer(address _to, uint256 _amount) public {
    //     uint256 previousBalances = s_balances[msg.sender] + balanceOf(_to);
    //     s_balances[msg.sender] -= _amount;
    //     s_balances[_to] += _amount;
    //     require(balanceOf(msg.sender) + balanceOf(_to) == previousBalances);
    // }

    // -------------------- allowance change
    //Safer allowance change pattern (avoid the classic race condition).
    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) external returns (bool) {
        _approve(
            msg.sender,
            spender,
            s_allowance[msg.sender][spender] + addedValue
        );
        return true;
    }

    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) external returns (bool) {
        uint256 current = s_allowance[msg.sender][spender];
        require(
            current >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        _approve(msg.sender, spender, current - subtractedValue);
        return true;
    }

    // -------------------- Mint / Burn (onlyOwner modifier)
    //Owner mints new tokens to `to`. Increases totalSupply
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    //Owner burns tokens from `from`. Decreases totalSupply.
    //If burning from someone else, owner must have their approval first in a real token.
    function burn(address from, uint256 amount) external onlyOwner {
        _burn(from, amount);
    }

    //-----------GETTER FUNCTIONS
    function totalSupply() public view returns (uint256) {
        return s_totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return s_balances[account];
    }

    function allowance(
        address owner,
        address spender
    ) public view returns (uint256) {
        return s_allowance[owner][spender];
    }

    // -------------------- Internal helpers ------------
    // transfer logic with checks and event emission.
    function _transfer(address from, address to, uint256 amount) internal {
        require(to != address(0), "ERC20: transfer to the zero address");
        uint256 fromBal = s_balances[from];
        require(fromBal >= amount, "ERC20: transfer amount exceeds balance");

        // Effects
        s_balances[from] = fromBal - amount;
        s_balances[to] += amount;

        // Interaction-free, so no reentrancy risk here.
        emit Transfer(from, to, amount);
    }

    //Sets allowance and emits Approval.
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        s_allowance[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    //Deducts `amount` from `owner` -> `spender` allowance.
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        uint256 current = s_allowance[owner][spender];
        require(current >= amount, "ERC20: insufficient allowance");
        // Effects
        s_allowance[owner][spender] = current - amount;
        // (No event for spending allowance; spec doesn't require it.)
    }

    //Creates `amount` tokens for `to`, increasing totalSupply and emitting Transfer(0, to, amount).
    function _mint(address to, uint256 amount) internal {
        require(to != address(0), "ERC20: mint to the zero address");
        s_totalSupply += amount;
        s_balances[to] += amount;
        emit Transfer(address(0), to, amount);
    }

    //Logic for destrying `amount` tokens from `from`, decreasing totalSupply and emitting Transfer(from, 0, amount).
    function _burn(address from, uint256 amount) internal {
        require(from != address(0), "ERC20: burn from the zero address");
        uint256 fromBal = s_balances[from];
        require(fromBal >= amount, "ERC20: burn amount exceeds balance");
        s_balances[from] = fromBal - amount;
        s_totalSupply -= amount;
        emit Transfer(from, address(0), amount);
    }
}
