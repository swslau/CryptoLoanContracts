// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "./LoanStructure.sol";
import "./AddressManagement.sol";

contract CollateralizedLoanGateway is AddressManagement {
    address collateralizedLoanProxy;
    address payable transactionsProxy;
    address addressManagement;
    address airnodeAdmin;

    constructor(address _collateralizedLoanProxy, address payable _transactionsProxy, address _addressManagement, address _airnodeAdmin, address admin_) AddressManagement(admin_) {
        collateralizedLoanProxy = _collateralizedLoanProxy;
        transactionsProxy = _transactionsProxy;
        addressManagement = _addressManagement;
        airnodeAdmin = _airnodeAdmin;
    }

    fallback() external payable {}

    receive() external payable {}

    modifier AuthenticateSender(address _address) {
        if(msg.sender == _address) {
            _;
        } else {
            revert("Unauthorized");
        }
    }

    modifier AuthenticateAirnodeAdmin {
        if(msg.sender == airnodeAdmin) {
            _;
        } else {
            revert("Unauthorized");
        }
    }

    /**
     * @dev Trigger the event when agreement of the collateralized loan is made
     */
    event LoanInitiated(uint256 _loanId, address _lender, uint256 _initiatedTime);

    /**
     * @dev Trigger the event when borrower raised a request for loan
     */
    event LoanRequested(uint256 _loanId, address _requester, uint256 _requestedTime);

    /**
     * @dev Trigger the event when the loan is cancelled
     */
    event LoanCancelled(uint256 _loanId, address _lender, uint256 _cancelTime);

    /**
     * @dev Trigger the event when loan is disbursed to borrower
     */
    event LoanDisbursed(uint256 _loanId, address _lender, uint256 _nextRepaymentDeadline, uint256 _disburseTime);

    /**
     * @dev Trigger the event when repayment is made by the borrower
     */
    event LoanRepaid(uint256 _loanId, address _borrower, uint256 _repaidTime);

    /**
     * @dev Trigger the event when borrower defaults on a particular loan
     */
    event LoanDefaulted(uint256 _loanId, address _borrower, uint256 _checkTime);

    /**
     * @dev Trigger the event when borrower defaults and collateralized ether is sent to the lender
     */
    event CollateralSentToLender(uint256 _loanId, address _lender, uint256 _sentTime);

    /**
     * @dev Trigger the event when borrower has fully repaid the loan
     */
    event LoanFullyRepaid(uint256 _loanId, address _borrower, uint256 _repaidTime);

    /**
     * @dev Trigger the event when collateral is paid back to the borrower
     */
    event CollateralPaidback(uint256 _loanId, address _borrower, uint256 _paidTime);
    
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

    function getCollateralizedLoanProxy() external view isAdmin returns (address) {
        return collateralizedLoanProxy;
    }

    function getTransactionsProxy() external view isAdmin returns (address) {
        return transactionsProxy;
    }

    function getAddressManagement() external view isAdmin returns (address) {
        return addressManagement;
    }

    function getAirnodeAdmin() external view isAdmin returns (address) {
        return airnodeAdmin;
    }

    function changeCollateralizedLoanProxy(address _collateralizedLoanProxy) external isAdmin {
        collateralizedLoanProxy = _collateralizedLoanProxy;
    }

    function changeTransactionsProxy(address payable _transactionsProxy) external isAdmin {
        transactionsProxy = _transactionsProxy;
    }

    function changeAddressManagement(address _addressManagement) external isAdmin {
        addressManagement = _addressManagement;
    }

    function changeAirnodeAdmin(address _airnodeAdmin) external isAdmin {
        airnodeAdmin = _airnodeAdmin;
    }

    function functionCallToCollateralizedLoanProxy(bytes memory payload) internal returns (bytes memory)
    {
        (bool success, bytes memory returnData) = collateralizedLoanProxy.call(payload);
        require(success, "call to collateralizedLoanProxy failed");
        return returnData;
    }

    function functionCallToTransactionsProxy(bytes memory payload) internal returns (bytes memory)
    {
        (bool success, bytes memory returnData) = transactionsProxy.call(payload);
        require(success, "call to transactionsProxy failed");
        return returnData;
    }
    
    /**
        Endpoints from CollateralizedLoan
     */
    function initiateLoan(address _lender, uint256 _loanAmount, uint256 _collateralAmount, uint256 _loanTerm, uint256 _apr, uint256 _repaymentSchedule, uint256 _monthlyRepayment, uint256 _remainingPaymentCount, uint256 _ltv, uint256 _marginLTV, uint256 _liquidationLTV)
    AuthenticateSender(_lender)
    external
    {
        bytes memory payload = abi.encodeWithSignature("initiateLoan(address,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256)", _lender, _loanAmount, _collateralAmount, _loanTerm, _apr, _repaymentSchedule, _monthlyRepayment, _remainingPaymentCount, _ltv, _marginLTV, _liquidationLTV);
        uint256 newLoanId = abi.decode(functionCallToCollateralizedLoanProxy(payload), (uint256));
        emit LoanInitiated(newLoanId, _lender, block.timestamp);
    }

    function requestLoan(address _requester, uint256 _loanId)
    AuthenticateSender(_requester)
    external
    {
        bytes memory payload = abi.encodeWithSignature("requestLoan(address,uint256)", _requester, _loanId);

        functionCallToCollateralizedLoanProxy(payload);
        
        emit LoanRequested(_loanId, _requester, block.timestamp);
    }

    function cancelLoan(address _lender, uint256 _loanId)
    AuthenticateSender(_lender)
    external
    {
        bytes memory payload = abi.encodeWithSignature("cancelLoan(address,uint256)", _lender, _loanId);
        functionCallToCollateralizedLoanProxy(payload);
        emit LoanCancelled(_loanId, _lender, block.timestamp);
    }

    function disburseLoan(address _lender, uint256 _loanId, uint256 _nextRepaymentDeadline)
    AuthenticateSender(_lender)
    external
    {
        bytes memory payload1 = abi.encodeWithSignature("getLoanDetails(uint256)", _loanId);
        LoanStructure.Loan memory loan = abi.decode(functionCallToCollateralizedLoanProxy(payload1), (LoanStructure.Loan));

        bytes memory payload1a = abi.encodeWithSignature("checkFiatBalanceAmount(address)", loan.lender);
        uint256 lenderFiatBalance = abi.decode(functionCallToTransactionsProxy(payload1a), (uint256));
        
        bytes memory payload1b = abi.encodeWithSignature("checkEtherBalanceAmount(address)", loan.borrower);
        uint256 borrowerEtherBalance = abi.decode(functionCallToTransactionsProxy(payload1b), (uint256));

        if(_lender != loan.lender) {
            revert("Loan is not disbursed by the loan lender");
        }

        if(lenderFiatBalance < uint256(loan.loanAmount)) {
            revert("Lender does not have enough fiat balance");
        }

        if(borrowerEtherBalance < uint256(loan.collateralAmount)) {
            revert("Borrower does not have enough Ether balance");
        }

        bytes memory payload2 = abi.encodeWithSignature("transferFiatMoneyToAnotherAddress(address,address,uint256)", loan.lender, loan.borrower, uint(loan.loanAmount));
        functionCallToTransactionsProxy(payload2);

        emit FiatMoneyTransferredBetweenAddress(loan.lender, loan.borrower, uint(loan.loanAmount));

        bytes memory payload3 = abi.encodeWithSignature("storeCollateralToVault(address,uint256,uint256)", loan.borrower, _loanId, uint(loan.collateralAmount));
        functionCallToTransactionsProxy(payload3);

        emit EtherCollateralized(loan.borrower, _loanId, uint(loan.loanAmount));

        bytes memory payload4 = abi.encodeWithSignature("updateDisbursedLoanDetails(address,uint256,uint256)", _lender, _loanId, _nextRepaymentDeadline);
        functionCallToCollateralizedLoanProxy(payload4);

        emit LoanDisbursed(_loanId, _lender, _nextRepaymentDeadline, block.timestamp);
    }

    function makeRepaymentByBorrower(address _borrower, uint256 _loanId, uint256 _payValue, uint256 _nextRepaymentDeadline)
    AuthenticateSender(_borrower)
    external
    {
        bytes memory payload1 = abi.encodeWithSignature("getLoanDetails(uint256)", _loanId);
        LoanStructure.Loan memory loan = abi.decode(functionCallToCollateralizedLoanProxy(payload1), (LoanStructure.Loan));

        if(_payValue != loan.monthlyRepaymentAmount) {
            revert("Repayment value is not same as agreed monthly repayment amount");
        }

        if(_borrower != loan.borrower) {
            revert("Repayment is not made by the loan borrower");
        }

        bytes memory payload1a = abi.encodeWithSignature("checkFiatBalanceAmount(address)", loan.borrower);
        uint256 borrowerFiatBalance = abi.decode(functionCallToTransactionsProxy(payload1a), (uint256));

        if(borrowerFiatBalance < uint256(loan.monthlyRepaymentAmount)) {
            revert("Borrower does not have enough fiat balance");
        }

        bytes memory payload2 = abi.encodeWithSignature("transferFiatMoneyToAnotherAddress(address,address,uint256)", loan.borrower, loan.lender, _payValue);
        functionCallToTransactionsProxy(payload2);

        emit FiatMoneyTransferredBetweenAddress(loan.borrower, loan.lender, _payValue);

        bytes memory payload3 = abi.encodeWithSignature("updateNextLoanRepaymentDetails(uint256,uint256)", _loanId, _nextRepaymentDeadline);
        bool isFullyRepaid = abi.decode(functionCallToCollateralizedLoanProxy(payload3), (bool));

        if(isFullyRepaid) {
            bytes memory payload4 = abi.encodeWithSignature("releaseCollateralFromVault(address,uint256,uint256)", _borrower, _loanId, uint(loan.collateralAmount));
            functionCallToTransactionsProxy(payload4);

            emit EtherReleasedFromVault(_borrower, _loanId, uint(loan.collateralAmount));

            emit LoanFullyRepaid(_loanId, loan.borrower, block.timestamp);
        } else {
            emit LoanRepaid(_loanId, _borrower, block.timestamp);
        }
    }

    // Scheduled batch job for checking the defaulted loans
    function checkBorrowerDefault(uint256 _nextRepaymentDeadline) external
    AuthenticateAirnodeAdmin
    {
        bytes memory payload1 = abi.encodeWithSignature("getDefaultedLoanIds(uint256)", _nextRepaymentDeadline);
        uint256[] memory defaultedLoanIds = abi.decode(functionCallToCollateralizedLoanProxy(payload1), (uint256[]));
        for(uint256 i = 0; i < defaultedLoanIds.length; i++) {
            bytes memory payload2 = abi.encodeWithSignature("getLoanDetails(uint256)", defaultedLoanIds[i]);
            LoanStructure.Loan memory loan = abi.decode(functionCallToCollateralizedLoanProxy(payload2), (LoanStructure.Loan));
            
            bytes memory payload3 = abi.encodeWithSignature("releaseCollateralFromVault(address,uint256,uint256)", loan.lender, defaultedLoanIds[i], uint(loan.collateralAmount));
            functionCallToTransactionsProxy(payload3);

            emit EtherReleasedFromVault(loan.lender, defaultedLoanIds[i], uint(loan.collateralAmount));

            bytes memory payload4 = abi.encodeWithSignature("recordLoanDefaultEvent(uint256)", defaultedLoanIds[i]);
            functionCallToCollateralizedLoanProxy(payload4);

            emit LoanDefaulted(defaultedLoanIds[i], loan.borrower, block.timestamp);
            emit CollateralSentToLender(defaultedLoanIds[i], loan.lender, block.timestamp);
        }
    }

    function recordLoanDefaultEvent(uint256 _loanId) external
    AuthenticateAirnodeAdmin
    {
        bytes memory payload1 = abi.encodeWithSignature("getLoanDetails(uint256)", _loanId);
        LoanStructure.Loan memory loan = abi.decode(functionCallToCollateralizedLoanProxy(payload1), (LoanStructure.Loan));

        if(loan.loanStatus != LoanStructure.LoanStatus.LoanRepaying) {
            revert("Loan is not at LoanRepaying status");
        }

        bytes memory payload2 = abi.encodeWithSignature("recordLoanDefaultEvent(uint256)", _loanId);
        functionCallToCollateralizedLoanProxy(payload2);

        emit LoanDefaulted(_loanId, loan.borrower, block.timestamp);
    }

    function recordLoanFullyRepaidEvent(uint256 _loanId) external
    AuthenticateAirnodeAdmin
    {
        bytes memory payload1 = abi.encodeWithSignature("getLoanDetails(uint256)", _loanId);
        LoanStructure.Loan memory loan = abi.decode(functionCallToCollateralizedLoanProxy(payload1), (LoanStructure.Loan));

        if(loan.loanStatus != LoanStructure.LoanStatus.LoanRepaying) {
            revert("Loan is not at LoanRepaying status");
        }

        bytes memory payload2 = abi.encodeWithSignature("recordLoanFullyRepaidEvent(uint256)", _loanId);
        functionCallToCollateralizedLoanProxy(payload2);

        emit LoanFullyRepaid(_loanId, loan.borrower, block.timestamp);
    }

    // Scheduled batch job for liquidating loans
    function liquidateLoan(uint256[] memory loanIds, uint256[] memory collateralInUSD, uint256[] memory collateralPayables) external
    AuthenticateAirnodeAdmin
    {
        for(uint256 i = 0; i < loanIds.length; i++) {
            bytes memory payload1 = abi.encodeWithSignature("getLoanDetails(uint256)", loanIds[i]);
            LoanStructure.Loan memory loan = abi.decode(functionCallToCollateralizedLoanProxy(payload1), (LoanStructure.Loan));
            
            uint256 grossRemainingRepaymentAmount = loan.remainingRepaymentCount * loan.monthlyRepaymentAmount;
            
            bytes memory payload2 = abi.encodeWithSignature("getCollateralValueFromVault(uint256)", loanIds[i]);
            uint256 collateralAmount = abi.decode(functionCallToTransactionsProxy(payload2), (uint256));
            
            if(collateralInUSD[i] >= grossRemainingRepaymentAmount) {
                // Set loan as fully repaid, transfer grossRemainingRepaymentAmount to lender
                // and send remaining amount (collateralAmount - grossRemainingRepaymentAmount) to borrower

                bytes memory payload3 = abi.encodeWithSignature("deductCollateralValueFromVault(uint256,uint256)", loanIds[i], collateralAmount);
                functionCallToTransactionsProxy(payload3);

                bytes memory payload4 = abi.encodeWithSignature("storeFiatMoney(address,uint256)", loan.lender, grossRemainingRepaymentAmount);
                functionCallToTransactionsProxy(payload4);

                bytes memory payload5 = abi.encodeWithSignature("transferEther(address,uint256)", loan.borrower, collateralPayables[i]);
                functionCallToTransactionsProxy(payload5);
                emit EtherTransferred(loan.borrower, collateralPayables[i] * 1 wei);

                bytes memory payload6 = abi.encodeWithSignature("recordLoanFullyRepaidEvent(uint256)", loanIds[i]);
                functionCallToCollateralizedLoanProxy(payload6);

                emit LoanFullyRepaid(loanIds[i], loan.borrower, block.timestamp);
            } else {
                // Set loan as defaulted and send collateral to lender

                bytes memory payload3 = abi.encodeWithSignature("releaseCollateralFromVault(address,uint256,uint256)", loan.lender, loanIds[i], uint(loan.collateralAmount));
                functionCallToTransactionsProxy(payload3);

                emit EtherReleasedFromVault(loan.lender, loanIds[i], uint(loan.collateralAmount));

                bytes memory payload4 = abi.encodeWithSignature("recordLoanDefaultEvent(uint256)", loanIds[i]);
                functionCallToCollateralizedLoanProxy(payload4);

                emit LoanDefaulted(loanIds[i], loan.borrower, block.timestamp);
                emit CollateralSentToLender(loanIds[i], loan.lender, block.timestamp);
            }
        }
    }

    function getLoanDetails(uint256 _loanId) external
    returns (LoanStructure.Loan memory)
    {
        bytes memory payload = abi.encodeWithSignature("getLoanDetails(uint256)", _loanId);
        return abi.decode(functionCallToCollateralizedLoanProxy(payload), (LoanStructure.Loan));
    }

    function getLenderLoans(address _lender) external
    AuthenticateSender(_lender)
    returns (LoanStructure.Loan[] memory)
    {
        bytes memory payload = abi.encodeWithSignature("getLenderLoans(address)", _lender);
        return abi.decode(functionCallToCollateralizedLoanProxy(payload), (LoanStructure.Loan[]));
    }

    function getBorrowerLoans(address _borrower) external
    AuthenticateSender(_borrower)
    returns (LoanStructure.Loan[] memory)
    {
        bytes memory payload = abi.encodeWithSignature("getBorrowerLoans(address)", _borrower);
        return abi.decode(functionCallToCollateralizedLoanProxy(payload), (LoanStructure.Loan[]));
    }

    /**
        Endpoints from Transactions
     */

    function storeEther(address payable _address) public payable
    AuthenticateSender(_address)
    {
        transactionsProxy.transfer(msg.value);
        bytes memory payload = abi.encodeWithSignature("storeEther(address,uint256)", _address, msg.value);
        functionCallToTransactionsProxy(payload);
        emit EtherStored(_address, msg.value);
    }

    function storeFiatMoney(address _address, uint256 _value) public
    AuthenticateSender(_address)
    {
        bytes memory payload = abi.encodeWithSignature("storeFiatMoney(address,uint256)", _address, _value);
        functionCallToTransactionsProxy(payload);
        emit FiatMoneyStored(_address, _value);
    }

    function withdrawEther(address payable _address, uint256 _value) external
    AuthenticateSender(_address)
    {
        bytes memory payload = abi.encodeWithSignature("withdrawEther(address,uint256)", _address, _value);
        functionCallToTransactionsProxy(payload);
        emit EtherWithdrawn(_address, _value);
    }

    // Trigger when the user requested transfer fund to bank
    function withdrawFiatMoney(address _address, uint256 _value) external
    AuthenticateAirnodeAdmin
    {
        bytes memory payload = abi.encodeWithSignature("withdrawFiatMoney(address,uint256)", _address, _value);
        functionCallToTransactionsProxy(payload);
        emit FiatMoneyWithdrawn(_address, _value);
    }

    function checkEtherBalanceAmount(address _address) public
    AuthenticateSender(_address)
    returns (uint256)
    {
        bytes memory payload = abi.encodeWithSignature("checkEtherBalanceAmount(address)", _address);
        return abi.decode(functionCallToTransactionsProxy(payload), (uint256));
    }

    function checkFiatBalanceAmount(address _address) public
    AuthenticateSender(_address)
    returns (uint256)
    {
        bytes memory payload = abi.encodeWithSignature("checkFiatBalanceAmount(address)", _address);
        return abi.decode(functionCallToTransactionsProxy(payload), (uint256));
    }

    function transferFiatMoneyBackToBank(address _requester, string memory _bankAccountNo, uint256 _value) external
    AuthenticateSender(_requester)
    {
        bytes memory payload = abi.encodeWithSignature("transferFiatMoneyBackToBank(address,string,uint256)", _requester, _bankAccountNo, _value);
        functionCallToTransactionsProxy(payload);
        emit FiatMoneyTransferredToBank(_requester, _bankAccountNo, _value);
    }

    // Trigger when the loan is defaulted
    function transferEther(address payable _lender, uint256 _value) public
    AuthenticateAirnodeAdmin
    {
        bytes memory payload = abi.encodeWithSignature("transferEther(address,uint256)", _lender, _value);
        functionCallToTransactionsProxy(payload);
        emit EtherTransferred(_lender, _value * 1 wei);
    }

    /* For testing */
    function add1() external returns (uint256) {
        bytes memory payload = abi.encodeWithSignature("add1(uint256,uint256)", 3, 5);
        return abi.decode(functionCallToCollateralizedLoanProxy(payload), (uint256));
    }

    function add2() external returns (uint256) {
        bytes memory payload = abi.encodeWithSignature("add2(uint256,uint256)", 2, 4);
        return abi.decode(functionCallToTransactionsProxy(payload), (uint256));
    }

}