// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

library LoanStructure {
    struct Loan {
        uint256 loanId;
        uint256 loanAmount; // In USD, multipled by 10000 i.e. support 4 d.p.
        uint256 collateralAmount; // In ETH, stored as gas
        address borrower;
        address lender;
        bool borrowerAck;
        bool lenderAck;
        LoanStatus loanStatus;
        uint256 loanTerm; // Loan term in days
        uint256 apr; // apr (multipled by 10, in percentage)
        uint256 repaymentSchedule; // Repayment schedule in days
        uint256 monthlyRepaymentAmount; // Amount of each repayment
        uint256 remainingRepaymentCount;
        uint256 nextRepaymentDeadline;
        uint256 createTime;
        uint256 lastUpdateTime;
    }

    enum LoanStatus {
        LoanInitiated
        , LoanRequested
        , LoanAgreed
        , LoanAcknowledged
        , LoanCancelled
        , LoanRepaying
        , LoanDefaulted
        , LoanCompleted
    }
}