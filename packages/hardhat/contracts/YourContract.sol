pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

import "hardhat/console.sol";
import "./TestCoin.sol";
// import "@openzeppelin/contracts/access/Ownable.sol"; 
// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol



contract YourContract {
  uint SafetyAmount = 10; 
  

  struct Account { 
    uint256 deposited;
    uint256 borrowed;
    uint256 safety;
    uint256 interest;
  }

  mapping(address => Account) accounts;

  mapping(address => bool) acceptedTokens;

  function getAccount(address _account) public view returns (Account memory) {
    return accounts[_account];
  }

  function addCurrency(address _token) public {
    acceptedTokens[_token] = true;
  }

  function getAccountCollaterization (address _account) public view returns (uint quotient, uint remainder) {
        Account memory user_account = getAccount(_account);
        quotient  = user_account.deposited / user_account.borrowed;
        remainder = user_account.deposited - user_account.borrowed * quotient;
  }


  function canLiquidate (address _account) public view returns (bool isSafe) {
    (uint quitient, uint _remainder) = getAccountCollaterization(_account);
    if (quitient <= 0) {
      isSafe = true;
    } else {
      isSafe = false;
    }
    return isSafe;
  }


  //TODO Add in superfluid functionality here 
  function deposit(uint256 _amount, address _token) public {
    require(_amount > 0, "Must be depositing a positive amount");
    require(acceptedTokens[_token], "Must be depositing a token that is accepted");
    ERC20(_token).transferFrom(msg.sender, address(this), _amount);
    accounts[msg.sender].deposited += _amount;
  }

  //TODO: There is a better way of managing this instead of a seperate function
  function addSafety(uint256 _amount, address _token) public {
    require(_amount > 0, "Must be adding a positive amount");
    require(acceptedTokens[_token], "Must be depositing a token that is accepted");
    Account memory user_account = getAccount(msg.sender);
    require(user_account.safety < SafetyAmount, "Safety limit reached allready");
    ERC20(_token).transferFrom(msg.sender, address(this), _amount);
    accounts[msg.sender].safety += _amount;
  }

  function borrow(uint256 _amount, address _token) public {
    Account memory user_account = getAccount(msg.sender);
    require(acceptedTokens[_token], "Must be depositing a token that is accepted");
    require(_amount > 0, "Must be depositing a positive amount");
    require(user_account.deposited >= _amount, "Must have enough deposited to borrow");
    ERC20(_token).transferFrom(address(this), msg.sender, _amount);
    accounts[msg.sender].borrowed += _amount;
  }

  function repay(uint256 _amount, address _token) public {
    Account memory user_account = getAccount(msg.sender);
    require(acceptedTokens[_token], "Must be depositing a token that is accepted");
    require(_amount > 0, "Must be depositing a positive amount");
    require(user_account.borrowed >= _amount, "Cannot repay more than you have borrowed");
    ERC20(_token).transferFrom(msg.sender, address(this), _amount);
    accounts[msg.sender].borrowed -= _amount;
  }

  function withdraw(uint256 _amount, address _token) public {
    Account memory user_account = getAccount(msg.sender);
    require(acceptedTokens[_token], "Must be depositing a token that is accepted");
    require(_amount > 0, "Must be depositing a positive amount");
    require(user_account.deposited >= _amount, "Cannot withdraw more than you have deposited");
    ERC20(_token).transferFrom(address(this), msg.sender, _amount);
    accounts[msg.sender].deposited -= _amount;
  }

  event SetPurpose(address sender, string purpose);

  string public purpose = "Building Unstoppable Apps!!!";

  constructor() payable {
    // what should we do on deploy?
  }

  function setPurpose(string memory newPurpose) public {
      purpose = newPurpose;
      console.log(msg.sender,"set purpose to",purpose);
      emit SetPurpose(msg.sender, purpose);
  }

  // to support receiving ETH by default
  receive() external payable {}
  fallback() external payable {}
}
