pragma solidity ^0.8.15;


import "./AlystCampaign.sol";

contract CreateCampaign {


    address[] allAlystCampaign;

    function createCampaign(string memory  _campaignName, uint _campaignTargetAmount, uint _campaignPeriod) public returns (address newCampaign) {
         AlystCampaign campaign = new AlystCampaign(_campaignName, _campaignTargetAmount, _campaignPeriod);
         allAlystCampaign.push(address(campaign));
         return address(campaign);
    }
}