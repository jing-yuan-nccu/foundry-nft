// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract LearningQuest is Ownable {
    uint8 public constant STAGE_ERC20 = 1;
    uint8 public constant STAGE_ERC721 = 2;
    uint8 public constant STAGE_ONCHAIN_ERC721 = 3;
    uint8 public constant FINAL_STAGE = STAGE_ONCHAIN_ERC721;

    struct StageCompletion {
        bool completed;
        address contractAddress;
        uint64 completedAt;
    }

    mapping(address verifier => bool allowed) private s_verifiers;
    mapping(address student => mapping(uint8 stage => StageCompletion completion)) private s_completions;
    mapping(address student => uint8 stage) private s_highestCompletedStage;
    mapping(address submittedContract => address student) private s_contractSubmitter;

    error LearningQuest__InvalidVerifier();
    error LearningQuest__InvalidStage();
    error LearningQuest__InvalidStudent();
    error LearningQuest__InvalidContract();
    error LearningQuest__StageAlreadyCompleted();
    error LearningQuest__PreviousStageIncomplete();
    error LearningQuest__ContractAlreadyUsed();
    error LearningQuest__OnlyVerifier();

    event VerifierUpdated(address indexed verifier, bool allowed);
    event StageCompleted(address indexed student, uint8 indexed stage, address indexed contractAddress);

    constructor(address initialOwner, address initialVerifier) Ownable(initialOwner) {
        if (initialVerifier == address(0)) {
            revert LearningQuest__InvalidVerifier();
        }
        s_verifiers[initialVerifier] = true;
        emit VerifierUpdated(initialVerifier, true);
    }

    modifier onlyVerifier() {
        if (!s_verifiers[msg.sender]) {
            revert LearningQuest__OnlyVerifier();
        }
        _;
    }

    function setVerifier(address verifier, bool allowed) external onlyOwner {
        if (verifier == address(0)) {
            revert LearningQuest__InvalidVerifier();
        }
        s_verifiers[verifier] = allowed;
        emit VerifierUpdated(verifier, allowed);
    }

    function completeStage(address student, uint8 stage, address contractAddress) external onlyVerifier {
        if (student == address(0)) {
            revert LearningQuest__InvalidStudent();
        }
        if (contractAddress == address(0)) {
            revert LearningQuest__InvalidContract();
        }
        if (stage == 0 || stage > FINAL_STAGE) {
            revert LearningQuest__InvalidStage();
        }
        if (s_completions[student][stage].completed) {
            revert LearningQuest__StageAlreadyCompleted();
        }
        if (stage > STAGE_ERC20 && !s_completions[student][stage - 1].completed) {
            revert LearningQuest__PreviousStageIncomplete();
        }
        if (s_contractSubmitter[contractAddress] != address(0)) {
            revert LearningQuest__ContractAlreadyUsed();
        }

        s_completions[student][stage] =
            StageCompletion({completed: true, contractAddress: contractAddress, completedAt: uint64(block.timestamp)});
        s_contractSubmitter[contractAddress] = student;

        if (stage > s_highestCompletedStage[student]) {
            s_highestCompletedStage[student] = stage;
        }

        emit StageCompleted(student, stage, contractAddress);
    }

    function isVerifier(address verifier) external view returns (bool) {
        return s_verifiers[verifier];
    }

    function isContractUsed(address contractAddress) external view returns (bool) {
        return s_contractSubmitter[contractAddress] != address(0);
    }

    function getContractSubmitter(address contractAddress) external view returns (address) {
        return s_contractSubmitter[contractAddress];
    }

    function getHighestCompletedStage(address student) external view returns (uint8) {
        return s_highestCompletedStage[student];
    }

    function getStageCompletion(address student, uint8 stage)
        external
        view
        returns (bool completed, address contractAddress, uint256 completedAt)
    {
        StageCompletion memory completion = s_completions[student][stage];
        return (completion.completed, completion.contractAddress, completion.completedAt);
    }
}
