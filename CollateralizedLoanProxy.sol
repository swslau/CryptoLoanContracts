// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./UpgradableProxy.sol";

contract CollateralizedLoanProxy is UpgradableProxy {
    
    bytes32 constant ADMIN_SLOT = keccak256("leave.me.alone.slot");
    
    event AdminChanged(address previousAdmin, address newAdmin);
    
    constructor(address _logic, address admin_) UpgradableProxy(_logic) {
        _setAdmin(admin_);
    }

    modifier isAdmin() {
        if (msg.sender == _admin()) {
            _;
        } else {
            _fallback();
        }
    }
    
    function admin() external isAdmin returns (address admin_) {
        admin_ = _admin();
    }
    
    function implementation() external isAdmin returns(address implementation_) {
        implementation_ = _implementation();
    }    
    
    function upgradeTo(address newImplementation) external isAdmin {
        _upgradeTo(newImplementation);
    }
    
    function changeAdmin(address newAdmin) external virtual isAdmin {
        require(newAdmin != address(0), "TransparentUpgradableProxy: new admin is address 0");
        emit AdminChanged(_admin(), newAdmin);
        _setAdmin(newAdmin);
    }
    
    function _setAdmin(address newAdmin) private {
        bytes32 slot = ADMIN_SLOT;
        
        assembly {
            sstore(slot, newAdmin)
        }
    }
    
    function _admin() internal view virtual returns(address _admin_) {
        bytes32 slot = ADMIN_SLOT;
        
        assembly {
            _admin_ := sload(slot)
        }
    }
    
    function _beforeFallback() internal virtual override {
        require(msg.sender != _admin(), "Admin cannot fallback to proxy target");
        super._beforeFallback();
    }
}