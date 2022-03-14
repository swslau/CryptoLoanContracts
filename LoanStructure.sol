// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

library LoanStructure {
    struct Loan {
        uint256 loanId;
        uint256 loanAmount; // In USD, multipled by 10000 i.e. support 4 d.p.
        uint256 collateralAmount; // In wei
        address borrower;
        address lender;
        LoanStatus loanStatus;
        uint256 loanTerm; // Loan term in days
        uint256 apr; // apr (multipled by 10, in percentage)
        uint256 repaymentSchedule; // Repayment schedule in days
        uint256 monthlyRepaymentAmount; // Amount of each repayment
        uint256 remainingRepaymentCount;
        uint256 nextRepaymentDeadline;
        uint256 initialLTV; // must not contain decimal places
        uint256 marginLTV; // must not contain decimal places
        uint256 liquidationLTV; // must not contain decimal places
        uint256 createTime;
        uint256 lastUpdateTime;
    }

    enum LoanStatus {
        LoanInitiated
        , LoanRequested
        , LoanCancelled
        , LoanRepaying
        , LoanDefaulted
        , LoanCompleted
    }

    struct NextPaymentRecord {
        uint256 loanId;
        bool isPaid;
    }

}