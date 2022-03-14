// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract AddressManagement {
    
    bytes32 constant ADMIN_SLOT = keccak256("leave.me.alone.slot");

    mapping (string => address) name2AddressMap;
    mapping (address => string) address2NameMap;
    
    event AddressManagementAdminChanged(address previousAdmin, address newAdmin);
    
    constructor(address admin_) {
        _setAddressManagementAdmin(admin_);
    }

    modifier isAdmin() {
        if (msg.sender == _addressManagementAdmin()) {
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
    
    function addressManagementAdmin() external view isAdmin virtual returns (address admin_) {
        admin_ = _addressManagementAdmin();
    }
    
    
    function changeAddressManagementAdmin(address newAdmin) external virtual isAdmin {
        require(newAdmin != address(0), "TransparentUpgradableProxy: new admin is address 0");
        emit AddressManagementAdminChanged(_addressManagementAdmin(), newAdmin);
        _setAddressManagementAdmin(newAdmin);
    }
    
    function _setAddressManagementAdmin(address newAdmin) private {
        bytes32 slot = ADMIN_SLOT;
        
        assembly {
            sstore(slot, newAdmin)
        }
    }
    
    function _addressManagementAdmin() internal view virtual returns(address admin_) {
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

    function getContractAddress(string memory contractName) public view isOfficialContract returns (address contractAddress) {
        return name2AddressMap[contractName];
    }
    
}