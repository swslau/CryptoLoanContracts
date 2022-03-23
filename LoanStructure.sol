// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

library LoanStructure {
    struct Loan {
        uint256 loanId;
        uint32 loanAmount; // In USD, must not contain decimal places
        uint256 collateralAmount; // In wei
        address borrower;
        address lender;
        LoanStatus loanStatus;
        uint16 loanTerm; // Loan term in days
        uint16 apr; // apr (multipled by 10, in percentage)
        uint16 repaymentSchedule; // Repayment schedule in days
        uint32 monthlyRepaymentAmount; // Amount of each repayment, must not contain decimal places
        uint16 remainingRepaymentCount;
        uint256 nextRepaymentDeadline;
        uint8 initialLTV; // must not contain decimal places
        uint8 marginLTV; // must not contain decimal places
        uint8 liquidationLTV; // must not contain decimal places
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