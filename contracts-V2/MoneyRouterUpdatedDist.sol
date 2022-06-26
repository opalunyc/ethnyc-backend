//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.13;

import "hardhat/console.sol";

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import { ISuperfluid, ISuperToken, ISuperApp } from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluid.sol";

import { ISuperfluidToken } from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluidToken.sol";

import {IConstantFlowAgreementV1} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/agreements/IConstantFlowAgreementV1.sol";

import {CFAv1Library} from "@superfluid-finance/ethereum-contracts/contracts/apps/CFAv1Library.sol";

contract MoneyRouter {
    address public owner;

    uint256 planPredispersementMonths;
    uint256 planDistributionMonths;

    int96 public rate;
    //The date that the contract is initialized
    uint256 public startDate;
    // The last check in by the user 
    uint256 public lastCheckIn;
    //address getting the funds if wallet owner does not check in
    address payable public recipient;

    string public plan;


    using CFAv1Library for CFAv1Library.InitData;
    CFAv1Library.InitData public cfaV1; //initialize cfaV1 variable
    
    mapping (address => bool) public accountList;

    constructor(ISuperfluid host, address _owner) {
       

        startDate = block.timestamp;

        lastCheckIn = block.timestamp;


        assert(address(host) != address(0));
        console.log("Deploying a Money Router with owner:", owner);
        owner = _owner;

        //initialize InitData struct, and set equal to cfaV1        
        cfaV1 = CFAv1Library.InitData(
        host,
        //here, we are deriving the address of the CFA using the host contract
        IConstantFlowAgreementV1(
            address(host.getAgreementClass(
                    keccak256("org.superfluid-finance.agreements.ConstantFlowAgreement.v1")
                ))
            )
        );

    }

    function setPlan(string memory planType) public {
        if (keccak256(abi.encodePacked((planType))) == keccak256(abi.encodePacked(("SHORT")))) {
            plan = "SHORT";
            planPredispersementMonths = 6;
            planDistributionMonths = 54;
        } else if (keccak256(abi.encodePacked((planType))) == keccak256(abi.encodePacked(("MEDIUM")))) {
            plan = "MEDIUM";
            planPredispersementMonths = 12;
            planDistributionMonths = 108;
        } else if (keccak256(abi.encodePacked((planType))) == keccak256(abi.encodePacked(("LONG")))) {
            plan = "LONG";
            planPredispersementMonths = 24;
            planDistributionMonths = 216;
        }

    }

    function setRecipient(address payable _recipient) public {
        recipient = _recipient;
    }


    function checkIn() public {
        lastCheckIn = block.timestamp;
    }

    function updateFlowFromContract(ISuperfluidToken token, address receiver, int96 newFlowRate) public {
        require(msg.sender == owner || accountList[msg.sender] == true, "must be authorized");
        cfaV1.updateFlow(receiver, token, newFlowRate);
    }

    // update function called by gelato: checks current status and decides
    // whether to distribute funds and at what rate
    function userCheckedin() public returns (bool) {
        uint256 secondsSinceCheckIn = now - lastCheckIn;
        uint96 monthsSinceCheckIn = secondsSinceCheckIn / (1 year);
        if (monthsSinceCheckIn < planPredispersementMonths) {
            return false;
        }
        uint256 scalingFactor = (monthsSinceCheckIn**3 * 1000000) / (planDistributionMonths**3);
        uint256 dai = IERC20("0x5D8B4C2554aeB7e86F387B4d6c00Ac33499Ed01f").balanceOf(address(this));
        uint256 rate = (dai * scalingFactor) / 1000000;
        updateFlowFromContract(ISuperToken(address(0x5D8B4C2554aeB7e86F387B4d6c00Ac33499Ed01f)), recipient, rate);
    }

    function whitelistAccount(address _account) external {
        require(msg.sender == owner, "only owner can whitelist accounts");
        accountList[_account] = true;
    }

    function removeAccount(address _account) external {
        require(msg.sender == owner, "only owner can remove accounts");
        accountList[_account] = false;
    }

    function changeOwner(address _newOwner) external {
        require(msg.sender == owner, "only owner can change ownership");
        owner = _newOwner;
    }

    function sendLumpSumToContract(ISuperToken token, uint amount) external {
        require(msg.sender == owner || accountList[msg.sender] == true, "must be authorized");
        token.transferFrom(msg.sender, address(this), amount);
    }

    function createFlowIntoContract(ISuperfluidToken token, int96 flowRate) external {
        require(msg.sender == owner || accountList[msg.sender] == true, "must be authorized");

        cfaV1.createFlowByOperator(msg.sender, address(this), token, flowRate);
    }

    function updateFlowIntoContract(ISuperfluidToken token, int96 newFlowRate) external {
        require(msg.sender == owner || accountList[msg.sender] == true, "must be authorized");

        cfaV1.updateFlowByOperator(msg.sender, address(this), token, newFlowRate);
    }

    function deleteFlowIntoContract(ISuperfluidToken token) external {
        require(msg.sender == owner || accountList[msg.sender] == true, "must be authorized");

        cfaV1.deleteFlow(msg.sender, address(this), token);
    }

    function withdrawFunds(ISuperToken token, uint amount) external {
        require(msg.sender == owner || accountList[msg.sender] == true, "must be authorized");
        token.transfer(msg.sender, amount);
    }

    function createFlowFromContract(ISuperfluidToken token, address receiver, int96 flowRate) external {
        require(msg.sender == owner || accountList[msg.sender] == true, "must be authorized");
        cfaV1.createFlow(receiver, token, flowRate);
    }


    function deleteFlowFromContract(ISuperfluidToken token, address receiver) external {
        require(msg.sender == owner || accountList[msg.sender] == true, "must be authorized");
        cfaV1.deleteFlow(address(this), receiver, token);
    }
}
