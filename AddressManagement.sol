// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract AddressManagement {
    
    bytes32 constant ADMIN_SLOT = keccak256("leave.me.alone.slot");

    mapping (string => address) name2AddressMap;
    mapping (address => string) address2NameMap;
    
    event AdminChanged(address previousAdmin, address newAdmin);
    
    constructor(address admin_) {
        _setAdmin(admin_);
    }

    modifier isAdmin() {
        if (msg.sender == _admin()) {
            _;
        } else {
            revert();
        }
    }

    modifier isOfficialContract() {
        if(bytes(address2NameMap[msg.sender]).length != 0) {
            _;
        } else {
            revert();
        }
    }
    
    function admin() external view isAdmin returns (address admin_) {
        admin_ = _admin();
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
    
    function _admin() internal view virtual returns(address admin_) {
        bytes32 slot = ADMIN_SLOT;
        
        assembly {
            admin_ := sload(slot)
        }
    }

    function updateContractAddress(string memory contractName, address contractAddress) external isAdmin {
        name2AddressMap[contractName] = contractAddress;
        address2NameMap[contractAddress] = contractName;
    }

    function getContractAddressByAdmin(string memory contractName) external view isAdmin returns (address contractAddress) {
        return name2AddressMap[contractName];
    }

    function getContractNameByAdmin(address contractAddress) external view isAdmin returns (string memory contractName) {
        return address2NameMap[contractAddress];
    }

    // For testing
    function getContractAddress(string memory contractName) external view isOfficialContract returns (address contractAddress) {
        return name2AddressMap[contractName];
    }
    
}