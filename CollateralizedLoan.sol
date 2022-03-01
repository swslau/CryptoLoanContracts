// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import './LoanStructure.sol';

/**
 * @title CollateralizedLoan
 * @dev Allow the lending of loan in fiat currency with cryptocurrency as collateral
 */
contract CollateralizedLoan {

    // address addressManagement;

    // constructor(address _addressManagement) {
    //     addressManagement = _addressManagement;
    // }
    
    /**
     * @dev Trigger the event when agreement of the collateralized loan is made
     */
    event LoanInitiated(uint256 _loanId, address _lender, uint256 _initiatedime);

    /**
     * @dev Trigger the event when borrower raised a request for loan
     */
    event LoanRequested(uint256 _loanId, address _requester, uint256 _initiatedime);

    /**
     * @dev Trigger the event when agreement of the collateralized loan is made
     */
    event LoanAgreed(uint256 _loanId, address _borrower, address _lender, uint256 _agreedTime);
    
    /**
     * @dev Trigger the event when ether is deposited by borrower as collateral
     */
    event EtherDepositedACK(uint256 _loanId, address _borrower, uint256 _ethValue, uint256 _ackTime);

    /**
     * @dev Trigger the event when loan amount is deposited by lender
     */
    event LoanDepositedACK(uint256 _loanId, address _lender, uint256 _loanValue, uint256 _ackTime);

    /**
     * @dev Trigger the event when the loan is cancelled
     */
    event LoanCancelled(uint256 _loanId, address _lender, uint256 _cancelTime);

    /**
     * @dev Trigger the event when loan is disbursed to borrower
     */
    event LoanDisbursed(uint256 _loanId, address _lender, uint256 _disburseTime);

    /**
     * @dev Trigger the event when repayment is made by the borrower
     */
    event RepaymentMadeByBorrower(uint256 _loanId, address _borrower, uint256 _repaidTime);

    /**
     * @dev Trigger the event when borrower defaults on a particular loan
     */
    event BorrowerDefaults(uint256 _loanId, address _borrower, uint256 _checkTime);

    /**
     * @dev Trigger the event when borrower defaults and collateralized ether is sent to the lender
     */
    event CollateralSentToLender(uint256 _loanId, address _lender, uint256 _sentTime);

    /**
     * @dev Trigger the event when borrower has fully repaid the loan
     */
    event FullLoanRepaid(uint256 _loanId, uint256 _checkTime);

    /**
     * @dev Trigger the event when collateral is paid back to the borrower
     */
    event CollateralPaidback(uint256 _loanId, address _borrower, uint256 _paidTime);
    
    /**
     * @dev Mapping of loan by loanId
     */
    mapping(uint256 => LoanStructure.Loan) loanMap;

    /**
     * @dev Mapping of existence of loan by loanId
     */
    mapping(uint256 => bool) loanExistenceMap;

    /**
     * @dev Count of latest loanId
     */
    uint256 loanCount;

    /**
     * @dev Mapping of loanIds by lender address
     */
    mapping(address => uint256[]) lenderMap;

    /**
     * @dev Mapping of loanIds by borrower address
     */
    mapping(address => uint256[]) borrowerMap;

    /**
     * @dev Require the loan to be initiated and processed to a particular stage
     */
    modifier RequireLoanStatus(uint256 _loanId, LoanStructure.LoanStatus _loanStatus) {
        require(loanExistenceMap[_loanId] && loanMap[_loanId].loanStatus == _loanStatus);
        _;
    }

    /**
     * @dev Require the loan to be initiated and processed before a particular stage
     */
    modifier RequireLoanStatusBefore(uint256 _loanId, LoanStructure.LoanStatus _loanStatus) {
        require(loanExistenceMap[_loanId] && loanMap[_loanId].loanStatus < _loanStatus);
        _;
    }
    
    /**
     * @dev Authenticate the address of the sender, see if it is the address of the borrower of a loan
     */
    modifier AuthenticateBorrower(address _borrower, uint256 _loanId) {
        require(_borrower == loanMap[_loanId].borrower);
        _;
    }
    
    /**
     * @dev Authenticate the address of the sender, see if it is the address of the lender of a loan
     */
    modifier AuthenticateLender(address _lender, uint256 _loanId) {
        require(_lender == loanMap[_loanId].lender);
        _;
    }
    
    /**
     * @dev Authenticate the address of the sender, see if it is coming from the Collateralized Loan Gateway
     */
    modifier AuthenticateSender() {
        address addressManagement = 0x54698d5ff8C093Cb051631982D12B718b28c95f7;
        (, bytes memory result) = addressManagement.call(abi.encodeWithSignature("getContractAddress(string)", "CollateralizedLoanGateway"));
        require(msg.sender == abi.decode(result, (address)));
        _;
    }
    
    /**
     * @dev Initiate the loan offered from lender
     */
    function initiateLoan(address _lender, uint256 _loanAmount, uint256 _collateralAmount, uint256 _loanTerm, uint256 _apr, uint256 _repaymentSchedule, uint256 _monthlyRepaymentAmount, uint256 _remainingPaymentCount) external
    AuthenticateSender
    returns(uint256)
    {
        loanCount += 1;
        loanMap[loanCount] = LoanStructure.Loan({
            loanId: loanCount
            , loanAmount: _loanAmount
            , collateralAmount: _collateralAmount
            , borrower: address(0)
            , lender: _lender
            , borrowerAck: false
            , lenderAck: false
            , loanStatus: LoanStructure.LoanStatus.LoanInitiated
            , loanTerm: _loanTerm
            , apr: _apr
            , repaymentSchedule: _repaymentSchedule
            , monthlyRepaymentAmount: _monthlyRepaymentAmount
            , remainingRepaymentCount: _remainingPaymentCount
            , nextRepaymentDeadline: 0
            , createTime: block.timestamp
            , lastUpdateTime: block.timestamp
        });
        lenderMap[_lender].push(loanCount);
        loanExistenceMap[loanCount] = true;
        emit LoanInitiated(loanCount, _lender, loanMap[loanCount].createTime);
        return loanMap[loanCount].loanId;
    }

    /**
     * @dev The agreement on the loan is made between borrower and lender
     */
    function requestLoan(address _borrower, uint256 _loanId) external
    AuthenticateSender RequireLoanStatus(_loanId, LoanStructure.LoanStatus.LoanInitiated)
    {
        loanMap[_loanId].loanStatus = LoanStructure.LoanStatus.LoanRequested;
        loanMap[_loanId].borrower = _borrower;
        borrowerMap[_borrower].push(_loanId);
        emit LoanRequested(_loanId, _borrower, block.timestamp);
    }

    /**
     * @dev The agreement on the loan is made between borrower and lender
     */
    function agreeLoan(address _lender, uint256 _loanId, address _borrower) external
    AuthenticateSender AuthenticateLender(_lender, _loanId) RequireLoanStatus(_loanId, LoanStructure.LoanStatus.LoanRequested)
    {
        loanMap[_loanId].loanStatus = LoanStructure.LoanStatus.LoanAgreed;
        emit LoanAgreed(_loanId, _borrower, _lender, block.timestamp);
    }

    /**
     * @dev Ether is deposited and the action is acknowledged by the borrower
     */
    function ackEthDeposit(address _borrower, uint256 _loanId, uint256 _ethBalance) external
    AuthenticateSender AuthenticateBorrower(_borrower, _loanId) RequireLoanStatus(_loanId, LoanStructure.LoanStatus.LoanAgreed)
    {
        require(_ethBalance >= loanMap[_loanId].collateralAmount);
        loanMap[_loanId].borrowerAck = true;
        if(loanMap[_loanId].lenderAck) {
            loanMap[_loanId].loanStatus = LoanStructure.LoanStatus.LoanAcknowledged;
        }
        emit EtherDepositedACK(_loanId, _borrower, _ethBalance, block.timestamp);
    }

    /**
     * @dev Loan in fiat money is deposited and the action is acknowledged by the borrower
     */
    function ackLoan(address _lender, uint256 _loanId, uint256 _loanValue, uint256 _lenderFiatBalance) external
    AuthenticateSender AuthenticateLender(_lender, _loanId) RequireLoanStatus(_loanId, LoanStructure.LoanStatus.LoanAgreed)
    {
        require(_loanValue >= loanMap[_loanId].loanAmount, "Given loan value does not match the initiated loan amount");
        require(_lenderFiatBalance >= loanMap[_loanId].loanAmount, "Lender does not have enough fiat balance to acknowledge the loan");

        loanMap[_loanId].lenderAck = true;
        if(loanMap[_loanId].borrowerAck) {
            loanMap[_loanId].loanStatus = LoanStructure.LoanStatus.LoanAcknowledged;
        }
        emit LoanDepositedACK(_loanId, _lender, _loanValue, block.timestamp);
    }

    /**
     * @dev Loan is cancelled due to the disputes between borrower and lender,
     *      or the deposits are not acknowledged by both borrower and lender before the deadline
     */
    function cancelLoan(address _lender, uint256 _loanId) external
    AuthenticateSender AuthenticateLender(_lender, _loanId) RequireLoanStatusBefore(_loanId, LoanStructure.LoanStatus.LoanAcknowledged)
    {
        loanMap[_loanId].loanStatus = LoanStructure.LoanStatus.LoanCancelled;
        emit LoanCancelled(_loanId, _lender, block.timestamp);
    }

    function updateDisbursedLoanDetails(address _lender, uint256 _loanId, uint256 _nextRepaymentDeadline) external
    {
        loanMap[_loanId].loanStatus = LoanStructure.LoanStatus.LoanRepaying;
        loanMap[_loanId].nextRepaymentDeadline = _nextRepaymentDeadline;
        emit LoanDisbursed(_loanId, _lender, block.timestamp);
    }

    function recordRepaymentEvent(address _borrower, uint256 _loanId) external
    {
        emit RepaymentMadeByBorrower(_loanId, _borrower, block.timestamp);
    }

    function recordFullRepaymentEvent(uint256 _loanId) external
    {
        emit FullLoanRepaid(_loanId, block.timestamp);
    }

    function updateNextLoanRepayment(uint256 _loanId, uint256 _nextRepaymentDeadline) external
    returns(bool)
    {
        loanMap[_loanId].remainingRepaymentCount -= 1;
        if(loanMap[_loanId].remainingRepaymentCount == 0) {
            emit FullLoanRepaid(_loanId, block.timestamp);
            loanMap[_loanId].loanStatus = LoanStructure.LoanStatus.LoanCompleted;
            loanMap[_loanId].nextRepaymentDeadline = 0;
            return true;
        }
        loanMap[_loanId].nextRepaymentDeadline = _nextRepaymentDeadline;
        return false;
    }

    function recordLoanDefaultEvent(uint256 _loanId) external
    {
        loanMap[_loanId].loanStatus = LoanStructure.LoanStatus.LoanDefaulted;
        emit BorrowerDefaults(_loanId, loanMap[_loanId].borrower, block.timestamp);
        emit CollateralSentToLender(_loanId, loanMap[_loanId].lender, block.timestamp);
    }

    /**
     * @dev Check whether or not the borrower has defaulted
     */
    function checkBorrowerDefault(uint256 _loanId) external
    AuthenticateSender RequireLoanStatus(_loanId, LoanStructure.LoanStatus.LoanRepaying)
    returns(bool)
    {
        if(block.timestamp >= loanMap[_loanId].nextRepaymentDeadline + loanMap[_loanId].repaymentSchedule * 1 days) {
            return true;
        }
        return false;
    }

    /**
     * @dev Get loan details by loanId
     */
    function getLoanDetails(uint256 _loanId) external
    AuthenticateSender
    returns(LoanStructure.Loan memory)
    {
        return loanMap[_loanId];
    }

    /**
     * @dev Get all the initiated loans by a particular lender (which is the msg.sender)
     */
    function getLenderLoans(address _lender) external
    AuthenticateSender
    returns(LoanStructure.Loan[] memory)
    {
        LoanStructure.Loan[] memory result = new LoanStructure.Loan[](lenderMap[_lender].length);
        for (uint i = 0; i < lenderMap[_lender].length; i++) {
            LoanStructure.Loan memory initiatedLoan = loanMap[lenderMap[_lender][i]];
            result[i] = initiatedLoan;
        }
        return result;
    }

    // /**
    //  * @dev Get the length of all the initiated loans by a particular lender (which is the msg.sender)
    //  */
    // function getLenderLoansLength(address _lender) external
    // AuthenticateSender
    // returns(uint256)
    // {
    //     return lenderMap[_lender].length;
    // }

    /**
     * @dev Get all the initiated loans by a particular lender (which is the msg.sender)
     */
    function getBorrowerLoans(address _lender) external
    AuthenticateSender
    returns(LoanStructure.Loan[] memory)
    {
        LoanStructure.Loan[] memory result = new LoanStructure.Loan[](borrowerMap[_lender].length);
        for (uint i = 0; i < borrowerMap[_lender].length; i++) {
            LoanStructure.Loan memory initiatedLoan = loanMap[borrowerMap[_lender][i]];
            result[i] = initiatedLoan;
        }
        return result;
    }

    /**
     * @dev Get loan amount of a particular loan agreement
     */
    function getLoanAmount(uint256 _loanId) external
    AuthenticateSender
    returns(uint256)
    {
        return loanMap[_loanId].loanAmount;
    }

    /**
     * @dev Get collateral amount of a particular loan agreement
     */
    function getCollateralAmount(uint256 _loanId) external
    AuthenticateSender
    returns(uint256)
    {
        return loanMap[_loanId].collateralAmount;
    }

    /* For testing */
    function add1(uint a, uint b) external
    AuthenticateSender
    returns (uint256) {
        return a + b;
    }

}
