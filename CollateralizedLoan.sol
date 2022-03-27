// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "./LoanStructure.sol";
import "./AddressManagement.sol";

/**
 * @title CollateralizedLoan
 * @dev Allow the lending of loan in fiat currency with cryptocurrency as collateral
 */
contract CollateralizedLoan is AddressManagement {

    constructor(address admin_) AddressManagement(admin_) { }
    
    /**
     * @dev Trigger the event when agreement of the collateralized loan is made
     */
    event LoanInitiated(uint256 indexed _loanId, address indexed _lender, uint256 _initiatedTime);

    /**
     * @dev Trigger the event when borrower raised a request for loan
     */
    event LoanRequested(uint256 indexed _loanId, address indexed _requester, uint256 _requestedTime);

    /**
     * @dev Trigger the event when the loan is cancelled
     */
    event LoanCancelled(uint256 indexed _loanId, address indexed _lender, uint256 _cancelTime);

    /**
     * @dev Trigger the event when loan is disbursed to borrower
     */
    event LoanDisbursed(uint256 indexed _loanId, address indexed _lender, uint256 _nextRepaymentDeadline, uint256 _disburseTime);

    /**
     * @dev Trigger the event when repayment is made by the borrower
     */
    event LoanRepaid(uint256 indexed _loanId, address indexed _borrower, uint256 _repaidTime);

    /**
     * @dev Trigger the event when borrower defaults on a particular loan
     */
    event LoanDefaulted(uint256 indexed _loanId, address indexed _borrower, uint256 _checkTime);

    /**
     * @dev Trigger the event when borrower defaults and collateralized ether is sent to the lender
     */
    event CollateralSentToLender(uint256 indexed _loanId, address indexed _lender, uint256 _sentTime);

    /**
     * @dev Trigger the event when borrower has fully repaid the loan
     */
    event LoanFullyRepaid(uint256 indexed _loanId, address indexed _borrower, uint256 _repaidTime);

    /**
     * @dev Trigger the event when collateral is paid back to the borrower
     */
    event CollateralPaidback(uint256 indexed _loanId, address indexed _borrower, uint256 _paidTime);

    /**
     * @dev loanId => Loan
     */
    mapping(uint256 => LoanStructure.Loan) loanMap;

    /**
     * @dev loanId => loanExistence
     */
    mapping(uint256 => bool) loanExistenceMap;

    /**
     * @dev lender address => loanId[]
     */
    mapping(address => uint256[]) lenderMap;

    /**
     * @dev borrower address => loanId[]
     */
    mapping(address => uint256[]) borrowerMap;

    /**
     * @dev nextPaymentDeadline => NextPaymentRecord[]
     */
    mapping(uint256 => LoanStructure.NextPaymentRecord[]) nextPaymentRecordMap;

    /**
     * @dev Count of latest loanId
     */
    uint256 loanCount;

    /**
     * @dev Require the loan to be initiated and processed to a particular stage
     */
    modifier RequireLoanStatus(uint256 _loanId, LoanStructure.LoanStatus _loanStatus) {
        require(loanExistenceMap[_loanId] && loanMap[_loanId].loanStatus == _loanStatus);
        _;
    }

    /**
     * @dev Require the loan to be initiated and processed to a particular stage
     */
    modifier RequireLoanStatusBefore(uint256 _loanId, LoanStructure.LoanStatus _loanStatus) {
        require(loanExistenceMap[_loanId] && loanMap[_loanId].loanStatus <= _loanStatus);
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
        require(msg.sender == super.getContractAddress("CollateralizedLoanGateway"));
        _;
    }

    /**
     * @dev Update lastUpdateTime of the loan
     */
    modifier UpdateLastUpdateTime(uint256 _loanId, uint256 _lastUpdateTime) {
        _;
        loanMap[_loanId].lastUpdateTime = _lastUpdateTime;
    }
    
    /**
     * @dev Initiate the loan offered from lender
     */
    function initiateLoan(address _lender, uint32 _loanAmount, uint256 _collateralAmount, uint16 _loanTerm, uint16 _apr, uint16 _repaymentSchedule, uint32 _monthlyRepaymentAmount, uint16 _remainingPaymentCount, uint8 _initialLTV, uint8 _marginLTV, uint8 _liquidationLTV) external
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
            , loanStatus: LoanStructure.LoanStatus.LoanInitiated
            , loanTerm: _loanTerm
            , apr: _apr
            , repaymentSchedule: _repaymentSchedule
            , monthlyRepaymentAmount: _monthlyRepaymentAmount
            , remainingRepaymentCount: _remainingPaymentCount
            , nextRepaymentDeadline: 0
            , initialLTV: _initialLTV
            , marginLTV: _marginLTV
            , liquidationLTV: _liquidationLTV
            , createTime: block.timestamp
            , lastUpdateTime: block.timestamp
        });
        lenderMap[_lender].push(loanCount);
        loanExistenceMap[loanCount] = true;
        emit LoanInitiated(loanCount, _lender, loanMap[loanCount].createTime);
        return loanMap[loanCount].loanId;
    }

    /**
     * @dev Borrower requests for the loan
     */
    function requestLoan(address _borrower, uint256 _loanId) external
    AuthenticateSender RequireLoanStatus(_loanId, LoanStructure.LoanStatus.LoanInitiated) UpdateLastUpdateTime(_loanId, block.timestamp)
    {
        loanMap[_loanId].loanStatus = LoanStructure.LoanStatus.LoanRequested;
        loanMap[_loanId].borrower = _borrower;
        borrowerMap[_borrower].push(_loanId);
        emit LoanRequested(_loanId, _borrower, block.timestamp);
    }

    /**
     * @dev Loan is cancelled by the lender
     */
    function cancelLoan(address _lender, uint256 _loanId) external
    AuthenticateSender AuthenticateLender(_lender, _loanId) RequireLoanStatusBefore(_loanId, LoanStructure.LoanStatus.LoanRequested) UpdateLastUpdateTime(_loanId, block.timestamp)
    {
        loanMap[_loanId].loanStatus = LoanStructure.LoanStatus.LoanCancelled;
        emit LoanCancelled(_loanId, _lender, block.timestamp);
    }

    /**
     * @dev Record the event of loan disbursement
     */
    function updateDisbursedLoanDetails(address _lender, uint256 _loanId, uint256 _nextRepaymentDeadline) external
    AuthenticateSender RequireLoanStatus(_loanId, LoanStructure.LoanStatus.LoanRequested) UpdateLastUpdateTime(_loanId, block.timestamp)
    {
        loanMap[_loanId].loanStatus = LoanStructure.LoanStatus.LoanRepaying;
        loanMap[_loanId].nextRepaymentDeadline = _nextRepaymentDeadline;
        nextPaymentRecordMap[_nextRepaymentDeadline].push(LoanStructure.NextPaymentRecord(_loanId, false));
        emit LoanDisbursed(_loanId, _lender, _nextRepaymentDeadline, block.timestamp);
    }

    /**
     * @dev Get a list of defaulted loanIds by nextRepaymentDeadline in NextPaymentRecord
     */
    function getDefaultedLoanIds(uint256 _nextRepaymentDeadline) external view
    AuthenticateSender
    returns(uint256[] memory)
    {
        uint256 defaultedLoanIdCount = 0;
        LoanStructure.NextPaymentRecord[] storage loanIds = nextPaymentRecordMap[_nextRepaymentDeadline];
        uint256[] memory candidates = new uint256[](loanIds.length);
        for(uint256 i = 0; i < loanIds.length; i++) {
            (uint256 _loanId_, bool _isPaid) = (loanIds[i].loanId, loanIds[i].isPaid);
            if(!_isPaid) {
                candidates[defaultedLoanIdCount] = _loanId_;
                defaultedLoanIdCount += 1;
            }
        }
        uint256[] memory defaultedLoanIds = new uint[](defaultedLoanIdCount);
        for (uint j = 0; j < defaultedLoanIds.length; j++) {
            defaultedLoanIds[j] = candidates[j];
        }
        return defaultedLoanIds;
    }

    /**
     * @dev Update the next payment status as paid in NextPaymentRecord
     */
    function updateNextPaymentAsPaid(uint256 _loanId) internal
    UpdateLastUpdateTime(_loanId, block.timestamp)
    {
        LoanStructure.NextPaymentRecord[] storage loanIds = nextPaymentRecordMap[loanMap[_loanId].nextRepaymentDeadline];
        for(uint256 i = 0; i < loanIds.length; i++) {
            (uint256 _loanId_, ) = (loanIds[i].loanId, loanIds[i].isPaid);
            if(_loanId_ == _loanId) {
                loanIds[i].isPaid = true;
                return;
            }
        }
    }

    /**
     * @dev Update the details of the next loan repayment
     */
    function updateNextLoanRepaymentDetails(uint256 _loanId, uint256 _nextRepaymentDeadline) external
    AuthenticateSender RequireLoanStatus(_loanId, LoanStructure.LoanStatus.LoanRepaying) UpdateLastUpdateTime(_loanId, block.timestamp)
    returns(bool isFullyRepaid)
    {
        updateNextPaymentAsPaid(_loanId);
        loanMap[_loanId].remainingRepaymentCount -= 1;
        if(loanMap[_loanId].remainingRepaymentCount == 0) {
            emit LoanFullyRepaid(_loanId, loanMap[_loanId].borrower, block.timestamp);
            loanMap[_loanId].loanStatus = LoanStructure.LoanStatus.LoanCompleted;
            loanMap[_loanId].nextRepaymentDeadline = 0;
            return true;
        }
        loanMap[_loanId].nextRepaymentDeadline = _nextRepaymentDeadline;
        nextPaymentRecordMap[_nextRepaymentDeadline].push(LoanStructure.NextPaymentRecord(_loanId, false));
        return false;
    }

    /**
     * @dev Record the event of loan default
     */
    function recordLoanDefaultEvent(uint256 _loanId) external
    AuthenticateSender RequireLoanStatus(_loanId, LoanStructure.LoanStatus.LoanRepaying) UpdateLastUpdateTime(_loanId, block.timestamp)
    {
        loanMap[_loanId].loanStatus = LoanStructure.LoanStatus.LoanDefaulted;
        loanMap[_loanId].remainingRepaymentCount = 0;
        loanMap[_loanId].nextRepaymentDeadline = 0;
        updateNextPaymentAsPaid(_loanId);
        emit LoanDefaulted(_loanId, loanMap[_loanId].borrower, block.timestamp);
    }

    /**
     * @dev Record the event of loan default
     */
    function recordLoanFullyRepaidEvent(uint256 _loanId) external
    AuthenticateSender RequireLoanStatus(_loanId, LoanStructure.LoanStatus.LoanRepaying) UpdateLastUpdateTime(_loanId, block.timestamp)
    {
        loanMap[_loanId].loanStatus = LoanStructure.LoanStatus.LoanCompleted;
        loanMap[_loanId].remainingRepaymentCount = 0;
        loanMap[_loanId].nextRepaymentDeadline = 0;
        updateNextPaymentAsPaid(_loanId);
        emit LoanFullyRepaid(_loanId, loanMap[_loanId].borrower, block.timestamp);
    }

    /**
     * @dev Get loan details by loanId
     */
    function getLoanDetails(uint256 _loanId) external view
    AuthenticateSender
    returns(LoanStructure.Loan memory)
    {
        return loanMap[_loanId];
    }

    /**
     * @dev Get all the initiated loans by a particular lender (which is the msg.sender)
     */
    function getLenderLoans(address _lender) external view
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

    /**
     * @dev Get all the initiated loans by a particular borrower (which is the msg.sender)
     */
    function getBorrowerLoans(address _borrower) external view
    AuthenticateSender
    returns(LoanStructure.Loan[] memory)
    {
        LoanStructure.Loan[] memory result = new LoanStructure.Loan[](borrowerMap[_borrower].length);
        for (uint i = 0; i < borrowerMap[_borrower].length; i++) {
            LoanStructure.Loan memory initiatedLoan = loanMap[borrowerMap[_borrower][i]];
            result[i] = initiatedLoan;
        }
        return result;
    }

    /**
     * @dev Get loan amount of a particular loan agreement
     */
    function getLoanAmount(uint256 _loanId) external view
    AuthenticateSender
    returns(uint256)
    {
        return loanMap[_loanId].loanAmount;
    }

    /**
     * @dev Get collateral amount of a particular loan agreement
     */
    function getCollateralAmount(uint256 _loanId) external view
    AuthenticateSender
    returns(uint256)
    {
        return loanMap[_loanId].collateralAmount;
    }

    /* For testing */
    function add1(uint8 a, uint8 b) external view
    AuthenticateSender
    returns (uint8) {
        return a + b;
    }

    function updateLoanRemainingRepaymentCount(uint256 _loanId, uint16 _remainingCount) external isAdmin {
        loanMap[_loanId].remainingRepaymentCount = _remainingCount;
    }

}
