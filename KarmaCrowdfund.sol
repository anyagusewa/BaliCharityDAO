// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "./KarmaToken.sol";

contract KarmaCrowdfund {
    struct Project {
        address creator;
        string title;
        string description;
        uint goal;
        uint deadline;
        uint raised;
        bool withdrawn;
    }

    Project[] public projects;

    mapping(uint => mapping(address => uint)) public contributions;
    mapping(uint => uint) public projectVotes; 
    mapping(address => bool) public hasVoted; 

    KarmaToken public karmaToken;

    event ProjectCreated(uint indexed id, address creator, string title, uint goal, uint deadline);
    event ContributionReceived(uint indexed id, address contributor, uint amount);
    event FundsWithdrawn(uint indexed id, uint amount);
    event RewardedWithKarma(address indexed user, uint amount);
    event RefundIssued(uint indexed projectId, address indexed contributor, uint amount);
    event Voted(uint indexed projectId, address indexed voter);
    event WinnerAnnounced(uint indexed projectId, uint votes);

    constructor(address _karmaTokenAddress) {
        karmaToken = KarmaToken(_karmaTokenAddress);
    }

    function createProject(string memory title, string memory description, uint goal, uint durationInDays) external {
        uint deadline = block.timestamp + durationInDays * 1 days;
        projects.push(Project(msg.sender, title, description, goal, deadline, 0, false));

        emit ProjectCreated(projects.length - 1, msg.sender, title, goal, deadline);
    }

    function contribute(uint projectId) external payable {
        require(projectId < projects.length, "Project does not exist");
        Project storage project = projects[projectId];
    
        require(block.timestamp <= project.deadline, "Deadline passed!");
        require(msg.value > 0, "Must contribute more than 0");
        project.raised += msg.value;
        contributions[projectId][msg.sender] += msg.value;

        uint karmaReward = msg.value / 1e14;
        karmaToken.mint(msg.sender, karmaReward * 10**karmaToken.decimals());
        emit RewardedWithKarma(msg.sender, karmaReward);

        emit ContributionReceived(projectId, msg.sender, msg.value);
    }

    function withdrawFunds(uint projectId) external {
        require(projectId < projects.length, "Project does not exist");
        Project storage project = projects[projectId];
        
        require(msg.sender == project.creator, "Not project creator");
        require(block.timestamp > project.deadline, "Too early");
        require(project.raised >= project.goal, "Goal not reached");
        require(!project.withdrawn, "Already withdrawn");

        project.withdrawn = true;
        payable(project.creator).transfer(project.raised);

        emit FundsWithdrawn(projectId, project.raised);
    }

    function refund(uint projectId) external {
        require(projectId < projects.length, "Project does not exist");
        Project storage project = projects[projectId];

        require(block.timestamp > project.deadline, "Project still active");
        require(project.raised < project.goal, "Goal was reached");

        uint amount = contributions[projectId][msg.sender];
        require(amount > 0, "No contributions to refund");

        contributions[projectId][msg.sender] = 0;
        payable(msg.sender).transfer(amount);

        emit RefundIssued(projectId, msg.sender, amount);
    }

    
    function vote(uint projectId) external {
        require(projectId < projects.length, "Project does not exist");
        require(!hasVoted[msg.sender], "Already voted");

        hasVoted[msg.sender] = true;
        projectVotes[projectId]++;
        emit Voted(projectId, msg.sender);
    }

    
    function getMostVotedProject() external view returns (uint projectId, uint votes) {
        uint highestVotes = 0;
        for (uint i = 0; i < projects.length; i++) {
            if (projectVotes[i] > highestVotes) {
                highestVotes = projectVotes[i];
                projectId = i;
            }
        }
        votes = highestVotes;
    }

    function getProjectsCount() external view returns (uint) {
        return projects.length;
    }

    function getProject(uint projectId) external view returns (address, string memory, string memory, uint, uint, uint, bool) {
        require(projectId < projects.length, "Project does not exist");
        Project memory p = projects[projectId];

        return (p.creator, p.title, p.description, p.goal, p.deadline, p.raised, p.withdrawn);
    }

    function getMyContribution(uint projectId, address contributor) external view returns (uint) {
        return contributions[projectId][contributor];
    }
}
