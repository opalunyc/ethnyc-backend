//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;


import './IERC20.sol';

// import { ISuperfluid }from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluid.sol"; //"@superfluid-finance/ethereum-monorepo/packages/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluid.sol";

// import { IConstantFlowAgreementV1 } from "@superfluid-finance/ethereum-contracts/contracts/interfaces/agreements/IConstantFlowAgreementV1.sol";

// import { IInstantDistributionAgreementV1 } from "@superfluid-finance/ethereum-contracts/contracts/interfaces/agreements/IInstantDistributionAgreementV1.sol";


contract Lossy {


    uint256 public rate;
    // The rate of increase
    uint256 public increaseRate;
    //The frequency of check-ins in seconds. How often a user needs to check in
    uint256 public frequency;
    //The date that the contract is initialized
    uint256 public startDate;
    // The last check in by the user 
    uint256 public lastCheckIn;
    //address getting the funds if wallet owner does not check in
    address payable public recipient;


    constructor(uint256 _frequency, address payable _recipient) {
        //everything is public for demo purposes

        frequency = _frequency;

        startDate = block.timestamp;

        lastCheckIn = block.timestamp;

        recipient = _recipient;

    }


    function setPlan(string memory planType) public {

        if (keccak256(abi.encodePacked((planType))) == keccak256(abi.encodePacked(("SHORT")))) {
            rate = 8;
            frequency = 2;
        } else if (keccak256(abi.encodePacked((planType))) == keccak256(abi.encodePacked(("MEDIUM")))) {
            rate = 4;
            frequency = 4;
        } else {
            rate = 2;
            frequency = 8;
        }

    }

    function setFrequency(uint _freq) public {
        frequency = _freq;
    }

    function setRecipient(address payable _recipient) public {
        recipient = _recipient;
    }


    function checkIn() public {
        lastCheckIn = block.timestamp;
    }

    // function will be run all the time 
    function userCheckedin() public returns (bool) {
        uint256 nextCheckIn = lastCheckIn + frequency;
    
        if (nextCheckIn > block.timestamp) {
            //case if checkin is not missed
            lastCheckIn = block.timestamp;
            return true;
        } else {
            //case if checkin is missed
            uint currentBalance = address(this).balance;
            uint256 amount = (currentBalance * rate)/100;
            recipient.transfer(amount);
            return false;
        }


 
    }
}
