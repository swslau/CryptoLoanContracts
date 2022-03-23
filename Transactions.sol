// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./AddressManagement.sol";

/**
 * @title Transactions
 * @dev Log the transaction records of the collateralized loan
 */
contract Transactions is AddressManagement {

    constructor(address admin_) AddressManagement(admin_) { }

    /**
     * @dev Trigger the event when Ether is stored in the contract
     */
    event EtherStored(address indexed _address, uint256 _value);

    /**
     * @dev Trigger the event when fiat money is stored in the contract
     */
    event FiatMoneyStored(address indexed _address, uint256 _value);

    /**
     * @dev Trigger the event when Ether is withdrawn in the contract
     */
    event EtherWithdrawn(address indexed _address, uint256 _value);

    /**
     * @dev Trigger the event when fiat money is withdrawn in the contract
     */
    event FiatMoneyWithdrawn(address indexed _address, uint256 _value);

    /**
     * @dev Trigger the event when Ether is successfully transferred
     */
    event EtherReceived(address indexed _from, uint256 _value);
    
    /**
     * @dev Trigger the event when fiat money is successfully transferred from one to another address
     */
    event FiatMoneyTransferredBetweenAddress(address indexed _from, address indexed _to, uint256 _value);
    
    /**
     * @dev Trigger the event when fiat money is successfully transferred from one to another address
     */
    event FiatMoneyTransferredToBank(address indexed _address, string indexed _bankAccountNo, uint256 _value);
    
    /**
     * @dev Trigger the event when Ether is successfully transferred
     */
    event EtherTransferred(address indexed _to, uint256 _value);

    /**
     * @dev Trigger the event when collateral is stored in vault
     */
    event EtherCollateralized(address indexed _address, uint256 indexed _loanId, uint256 _value);

    /**
     * @dev Trigger the event when collateral is released from vault
     */
    event EtherReleasedFromVault(address indexed _address, uint256 indexed _loanId, uint256 _value);
    
    /**
     * @dev Balance of Ether (in gas) to be tracked in the smart contract
     *      wallet address => etherBalance
     */
    mapping(address => uint256) etherBalances;
    
    /**
     * @dev Balance of fiat money to be tracked in the smart contract
     *      wallet address => fiatBalance
     */
    mapping(address => uint256) fiatBalances;

    /**
     * @dev Place for storing the collateral
     *      loanId => collateralValue
     */
    mapping(uint256 => uint256) collateralVault;
    
    /**
     * @dev Check if the account have enough balance to proceed the transaction in fiat money
     * @param _value Value of fiat money to be transferred
     */
    modifier CheckEnoughFiatBalance(uint256 _value) {
        require(fiatBalances[msg.sender] >= _value);
        _;
    }
    
    /**
     * @dev Check if the account have enough balance to proceed the transaction in Ether
     * @param _value Value of Ether to be transferred (in wei)
     */
    modifier CheckEnoughEtherBalance(uint256 _value) {
        require(etherBalances[msg.sender] >= _value);
        _;
    }
    
    /**
     * @dev Authenticate the address of the sender, see if it is coming from the Collateralized Loan Gateway
     */
    modifier AuthenticateSender {
        require(msg.sender == super.getContractAddress("CollateralizedLoanGateway"));
        _;
    }

    /**
     * @dev Fallback function
     */
    fallback() external payable {
    }

    /**
     * @dev A receive function for wallet to send ether to this contract
     */
    receive() external payable {
        emit EtherReceived(msg.sender, msg.value);
    }
    
    /**
     * @dev Store Ether to the account if it is created before
     * @param _address Address of the account
     * @param _value Value of Ether (in wei)
     */
    function storeEther(address _address, uint256 _value) external
    AuthenticateSender
    {
        etherBalances[_address] += _value;
        emit EtherStored(_address, _value);
    }
    
    /**
     * @dev Store fiat money to the account if it is created before
     * @param _address Address of the account
     * @param _value Value of fiat money to be stored (in USD)
     */
    function storeFiatMoney(address _address, uint256 _value) external
    AuthenticateSender
    {
        fiatBalances[_address] += _value;
        emit FiatMoneyStored(_address, _value);
    }

    /**
     * @dev Withdraw Ether from the contract
     * @param _address Address of the account
     * @param _value Value of Ether to be stored (in wei)
     */
    function withdrawEther(address payable _address, uint256 _value) external payable
    AuthenticateSender
    {
        if(etherBalances[_address] >= _value) {
            etherBalances[_address] -= _value;
            
            // This line is necessary if this contract is used standalone
            // but since gateway is used, the ether is locked there instead of here
            // transferEther(_address, _value);

            emit EtherWithdrawn(_address, _value);
        } else {
            revert("withdrawEther: Not enough Ether balance in the address");
        }
    }

    /**
     * @dev Withdraw fiat money from the contract (when off-chain fund transfer request is detected)
     * @param _address Address of the account
     * @param _value Value of fiat money to be withdrawn (in USD)
     */
    function withdrawFiatMoney(address _address, uint256 _value) external
    AuthenticateSender
    {
        if(fiatBalances[_address] >= _value) {
            fiatBalances[_address] -= _value;
            emit FiatMoneyWithdrawn(_address, _value);
        } else {
            revert("withdrawFiatMoney: Not enough fiat balance in the address");
        }
    }

    /**
     * @dev Check the last account balance in Ether
     * @param _address Address of the account
     */
    function checkEtherBalanceAmount(address _address) external view
    AuthenticateSender returns(uint256)
    {
        return etherBalances[_address];
    }

    /**
     * @dev Check the last account balance in fiat money
     * @param _address Address of the account
     */
    function checkFiatBalanceAmount(address _address) external view
    AuthenticateSender returns(uint256)
    {
        return fiatBalances[_address];
    }

    /**
     * @dev Transfer fiat money
     * @param _from Address of the sender of fiat money
     * @param _to Address of the receiver of fiat money
     * @param _value Value of fiat money to be transferred (in USD)
     */
    function transferFiatMoneyToAnotherAddress(address _from, address _to, uint256 _value) external
    AuthenticateSender
    {
        if(fiatBalances[_from] < _value) {
            revert("transferFiatMoneyToAnotherAddress: Not enough fiat balance in the from address");
        }
        fiatBalances[_from] -= _value;
        fiatBalances[_to] += _value;
        emit FiatMoneyTransferredBetweenAddress(_from, _to, _value);
    }

    /**
     * @dev Transfer fiat money back to bank
     * @param _requester Address of the requester
     * @param _bankAccountNo Account number of the requester
     * @param _value Value of fiat money to be transferred (in USD)
     */
    function transferFiatMoneyBackToBank(address _requester, string memory _bankAccountNo, uint256 _value) external
    AuthenticateSender
    {
        if(fiatBalances[_requester] < _value) {
            revert("transferFiatMoneyBackToBank: Not enough fiat balance in requester address");
        }
        emit FiatMoneyTransferredToBank(_requester, _bankAccountNo, _value);
    }
    
    /**
     * @dev Transfer Ether from contract to wallet address
     * @param _to Address of the receiver of Ether
     * @param _value Value of Ether to be transferred (in wei)
     */
    function transferEther(address payable _to, uint256 _value) public payable
    AuthenticateSender
    {
        bool sent = _to.send(_value * 1 wei);
        require(sent, "transferEther: Failed to send Ether");
        emit EtherTransferred(_to, _value * 1 wei);
    }

    /**
     * @dev Transfer Ether to collateral vault
     * @param _address Address of the borrower
     * @param _loanId Id of the loan
     * @param _collateralAmount Amount of the collateral (in wei)
     */
    function storeCollateralToVault(address _address, uint256 _loanId, uint256 _collateralAmount) external
    AuthenticateSender
    {
        etherBalances[_address] -= _collateralAmount;
        collateralVault[_loanId] += _collateralAmount;
        emit EtherCollateralized(_address, _loanId, _collateralAmount);
    }

    /**
     * @dev Release Ether from collateral vault
     * @param _address Address of the borrower
     * @param _loanId Id of the loan
     * @param _collateralAmount Amount of the collateral (in wei)
     */
    function releaseCollateralFromVault(address _address, uint256 _loanId, uint256 _collateralAmount) external
    AuthenticateSender
    {
        collateralVault[_loanId] -= _collateralAmount;
        etherBalances[_address] += _collateralAmount;
        emit EtherReleasedFromVault(_address, _loanId, _collateralAmount);
    }

    /**
     * @dev Get collateral value from collateral vault
     * @param _loanId Id of the loan
     */
    function getCollateralValueFromVault(uint256 _loanId) external view
    AuthenticateSender
    returns (uint256)
    {
        return collateralVault[_loanId];
    }

    /**
     * @dev Deduct collateral value from collateral vault
     * @param _loanId Id of the loan
     * @param _collateralAmount Collateral amount to be deducted
     */
    function deductCollateralValueFromVault(uint256 _loanId, uint256 _collateralAmount) external
    AuthenticateSender
    {
        collateralVault[_loanId] -= _collateralAmount;
    }

    /* For testing */
    function add2(uint8 a, uint8 b) external view
    AuthenticateSender
    returns (uint8) {
        return a + b;
    }
}