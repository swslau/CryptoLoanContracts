// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Transactions
 * @dev Log the transaction records of the collateralized loan
 */
contract Transactions {

    // address addressManagement;

    // constructor(address _addressManagement) {
    //     addressManagement = _addressManagement;
    // }

    /**
     * @dev Trigger the event when Ether balance of an wallet address is initiated
     */
    event EtherBalanceInitiated(address _address);

    /**
     * @dev Trigger the event when Fiat balance of an wallet address is initiated
     */
    event FiatBalanceInitiated(address _address);

    /**
     * @dev Trigger the event when Ether is stored in the contract
     */
    event EtherStored(address _address, uint256 _value);

    /**
     * @dev Trigger the event when fiat money is stored in the contract
     */
    event FiatMoneyStored(address _address, uint256 _value);

    /**
     * @dev Trigger the event when Ether is withdrawn in the contract
     */
    event EtherWithdrawn(address _address, uint256 _value);

    /**
     * @dev Trigger the event when fiat money is withdrawn in the contract
     */
    event FiatMoneyWithdrawn(address _address, uint256 _value);

    /**
     * @dev Trigger the event when Ether is successfully transferred
     */
    event EtherReceived(address _from, uint256 _value);
    
    /**
     * @dev Trigger the event when fiat money is successfully transferred from one to another address
     */
    event FiatMoneyTransferredBetweenAddress(address _from, address _to, uint256 _value);
    
    /**
     * @dev Trigger the event when fiat money is successfully transferred from one to another address
     */
    event FiatMoneyTransferredToBank(address _address, string _bankAccountNo, uint256 _value);
    
    /**
     * @dev Trigger the event when Ether is successfully transferred
     */
    event EtherTransferred(address _to, uint256 _value);

    /**
     * @dev Trigger the event when collateral is stored in vault
     */
    event EtherCollateralized(address _address, uint256 _loanId, uint256 _value);

    /**
     * @dev Trigger the event when collateral is released from vault
     */
    event EtherReleasedFromVault(address _address, uint256 _loanId, uint256 _value);
    
    /**
     * @dev Balance of Ether (in gas) to be tracked in the smart contract
     */
    mapping(address => uint256) etherBalances;
    
    /**
     * @dev Balance of fiat money to be tracked in the smart contract
     */
    mapping(address => uint256) fiatBalances;
    
    /**
     * @dev Indicator to check if the Ether balance of an account has been initiated
     */
    mapping(address => bool) createdEtherBalances;

    /**
     * @dev Place for storing the collateral, loanId => collateralValue
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
     * @param _value Value of Ether to be transferred
     */
    modifier CheckEnoughEtherBalance(uint256 _value) {
        require(etherBalances[msg.sender] >= _value);
        _;
    }
    
    /**
     * @dev Authenticate the address of the sender, see if it is coming from the Collateralized Loan Gateway
     */
    modifier AuthenticateSender {
        address addressManagement = 0x54698d5ff8C093Cb051631982D12B718b28c95f7;
        (, bytes memory result) = addressManagement.call(abi.encodeWithSignature("getContractAddress(string)", "CollateralizedLoanGateway"));
        require(msg.sender == abi.decode(result, (address)));
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
     * @dev Initiate the Ether balance of an account if it is not created before
     * @param _address Address of the account to be initiated
     */
    function initiateEtherBalance(address _address) internal
    AuthenticateSender returns(bool)
    {
        if(!createdEtherBalances[_address]) {
            etherBalances[_address] = 0;
            createdEtherBalances[_address] = true;
            emit EtherBalanceInitiated(_address);
            return true;
        }
        return false;
    }
    
    /**
     * @dev Store Ether to the account if it is created before
     * @param _address Address of the account
     */
    function storeEther(address _address, uint256 _value) external payable
    AuthenticateSender
    {
        if(createdEtherBalances[_address]) {
            etherBalances[_address] += _value;
        } else {
            initiateEtherBalance(_address);
            etherBalances[_address] += _value;
        }
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
        if(createdEtherBalances[_address] && etherBalances[_address] >= _value) {
            etherBalances[_address] -= _value;
            transferEther(_address, _value);
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
    function checkEtherBalanceAmount(address _address) external
    AuthenticateSender returns(uint256)
    {
        return etherBalances[_address];
    }

    /**
     * @dev Check the last account balance in fiat money
     * @param _address Address of the account
     */
    function checkFiatBalanceAmount(address _address) external
    AuthenticateSender returns(uint256)
    {
        return fiatBalances[_address];
    }

    /**
     * @dev Transfer fiat money
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
     * @param _collateralAmount Amount of the collateral in wei
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
     * @param _collateralAmount Amount of the collateral in wei
     */
    function releaseCollateralFromVault(address _address, uint256 _loanId, uint256 _collateralAmount) external
    AuthenticateSender
    {
        collateralVault[_loanId] -= _collateralAmount;
        etherBalances[_address] += _collateralAmount;
        emit EtherReleasedFromVault(_address, _loanId, _collateralAmount);
    }

    /* For testing */
    function add2(uint a, uint b) external
    AuthenticateSender
    returns (uint256) {
        return a + b;
    }
}