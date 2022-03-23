// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "./AddressManagement.sol";

contract TransactionsProxy is TransparentUpgradeableProxy, AddressManagement {
    constructor(address _logic, address admin_, bytes memory _data) TransparentUpgradeableProxy(_logic, admin_, _data) AddressManagement(admin_) { }
        
    function _beforeFallback() internal virtual override {
        require(msg.sender != _admin(), "TransactionsProxy: Admin cannot fallback to proxy target");
        super._beforeFallback();
    }
}