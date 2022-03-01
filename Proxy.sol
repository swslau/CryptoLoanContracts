// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

abstract contract Proxy {
    
    fallback() external payable virtual {
        _fallback();
    }

    receive() external payable {
    }
    
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    function _delegate(address implementation) internal virtual {
        assembly {
            
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }
    
    function _implementation() internal view virtual returns(address);

    function _beforeFallback() internal virtual {
    }
}