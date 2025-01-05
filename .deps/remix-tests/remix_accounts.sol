// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract RemixAccounts {
    struct AccountDetails{
       uint256 accountAddress;
      address balance;  
   }

     function getAccount(uint index) public pure returns (address){
        return 0x6b4f9a2d5e1c3d7be78B69F47A8C52E37D86;// changed the type of your struct
     }
}