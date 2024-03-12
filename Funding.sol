// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract PeerFunding is Ownable {
    struct FundingRequest {
        uint8 status;
        address poster;
        uint256 target;
        uint256 endDate;
        uint256 totalFunds;
    }
    mapping(address => mapping(uint256 => uint256)) fundsByUser;
    FundingRequest[] public fundingRequests;

    constructor() Ownable(msg.sender) {}

    function createFundingRequest(
        uint256 _target,
        uint256 _endDate
    ) external returns (uint256) {
        require(_target > 0, "Target must be greater than zero");
        require(_endDate > block.timestamp, "End date must be in the future");

        FundingRequest memory newRequest;
        newRequest.status = 0;
        newRequest.poster = msg.sender;
        newRequest.target = _target;
        newRequest.endDate = _endDate;
        newRequest.totalFunds = 0;
        fundingRequests.push(newRequest);
        return fundingRequests.length - 1;
    }

    function contribute(uint256 _requestIndex) external payable {
        require(
            _requestIndex < fundingRequests.length,
            "Invalid request index"
        );
        require(msg.value > 0, "Contribution must be greater than zero");

        FundingRequest storage request = fundingRequests[_requestIndex];
        require(block.timestamp < request.endDate, "Funding period has ended");

        fundsByUser[msg.sender][_requestIndex] += msg.value;
        request.totalFunds += msg.value;
    }

    function withdrawFunds(uint256 _requestIndex) external {
        require(
            _requestIndex < fundingRequests.length,
            "Invalid request index"
        );

        FundingRequest storage request = fundingRequests[_requestIndex];
        if (msg.sender == request.poster) {
            require(
                block.timestamp >= request.endDate,
                "Funding period has not ended"
            );
            require(request.totalFunds >= request.target, "Target not reached");
            require(request.status == 4, "Campaign not approved by admin");
            payable(owner()).transfer((request.totalFunds * 1) / 100);
            request.totalFunds -= (request.totalFunds * 1) / 100;
            payable(request.poster).transfer(request.totalFunds);
            request.totalFunds = 0;
            request.status = 5;
        } else {
            require(request.status != 0, "Campaign not active");
            require(
                request.status == 1 || request.status == 2,
                "Campaign Ended"
            );
            uint256 userContribution = fundsByUser[msg.sender][_requestIndex];
            require(userContribution > 0, "No funds to withdraw");
            fundingRequests[_requestIndex].totalFunds -= userContribution;
            fundsByUser[msg.sender][_requestIndex] = 0;
            payable(msg.sender).transfer(userContribution);
        }
    }

    function approveFundingRequest(uint256 _requestIndex) external onlyOwner {
        require(
            _requestIndex < fundingRequests.length,
            "Invalid request index"
        );
        require(
            fundingRequests[_requestIndex].totalFunds >=
                fundingRequests[_requestIndex].target,
            "Target not reached"
        );
        require(
            fundingRequests[_requestIndex].endDate < block.timestamp,
            "Funding period has not ended"
        );
        require(
            fundingRequests[_requestIndex].status == 3,
            "Request not pending admin approval"
        );
        fundingRequests[_requestIndex].status = 4;
    }

    function requestAdminApproval(uint256 _requestIndex) external {
        require(
            _requestIndex < fundingRequests.length,
            "Invalid request index"
        );
        require(
            msg.sender == fundingRequests[_requestIndex].poster,
            "Only the poster can request admin approval"
        );
        require(
            fundingRequests[_requestIndex].totalFunds >=
                fundingRequests[_requestIndex].target,
            "Target not reached"
        );
        require(
            fundingRequests[_requestIndex].endDate < block.timestamp,
            "Funding period has not ended"
        );
        fundingRequests[_requestIndex].status = 3;
    }

    function extendFundingPeriod(
        uint256 _requestIndex,
        uint256 _newEndDate
    ) external {
        require(
            _requestIndex < fundingRequests.length,
            "Invalid request index"
        );
        require(
            msg.sender == fundingRequests[_requestIndex].poster,
            "Only the poster can extend the funding period"
        );
        require(
            _newEndDate > fundingRequests[_requestIndex].endDate,
            "New end date must be after the current end date"
        );
        fundingRequests[_requestIndex].endDate = _newEndDate;
    }

    function getFundingRequests()
        external
        view
        returns (FundingRequest[] memory)
    {
        return fundingRequests;
    }

    function getFundsByUser(
        address _user
    ) external view returns (uint256[] memory) {
        uint256[] memory userFunds = new uint256[](fundingRequests.length);
        for (uint256 i = 0; i < fundingRequests.length; i++) {
            userFunds[i] = fundsByUser[_user][i];
        }
        return userFunds;
    }

    function getFundsByRequest(
        uint256 _requestIndex
    ) external view returns (uint256) {
        require(
            _requestIndex < fundingRequests.length,
            "Invalid request index"
        );
        return fundingRequests[_requestIndex].totalFunds;
    }

    function getFundsByUserForRequest(
        address _user,
        uint256 _requestIndex
    ) external view returns (uint256) {
        return fundsByUser[_user][_requestIndex];
    }

    function getFundingRequest(
        uint256 _requestIndex
    ) external view returns (FundingRequest memory) {
        require(
            _requestIndex < fundingRequests.length,
            "Invalid request index"
        );
        return fundingRequests[_requestIndex];
    }

    function getFundingRequestsLength() external view returns (uint256) {
        return fundingRequests.length;
    }
}
