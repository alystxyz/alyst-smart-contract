pragma solidity ^0.8.15;


import "./AlystCampaign.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface TurnstileR {
    function register(address) external returns(uint256);
}

contract CreateCampaign is Ownable {

    TurnstileR turnstile = TurnstileR(0xEcf044C5B4b867CFda001101c617eCd347095B44);

    using Counters for Counters.Counter;
    Counters.Counter private _campaignIds;

    uint256 internal csrID;

    struct CampaignIndex {
        string campaignName;
        address campaignAddress;
    }

    constructor() {

    }

    mapping(uint => CampaignIndex) public idToCampaignIndex;

    function createCampaign(string memory  _campaignName, 
                            string memory  _Symbol, 
                            string memory _uri, 
                            uint _campaignTargetAmount, 
                            uint _campaignPeriod, 
                            uint256 _csrId) public returns (uint CampaignId) {

        _campaignIds.increment();
         AlystCampaign campaign = new AlystCampaign(_campaignName, _Symbol, _uri, _campaignTargetAmount, _campaignPeriod, _csrId);
         uint256 newCampaignId = _campaignIds.current();
         idToCampaignIndex[newCampaignId] = CampaignIndex(_campaignName, address(campaign));
         return newCampaignId;
         
    }

    function getCampaignAddress(uint _index) public view returns (address) {
        return idToCampaignIndex[_index].campaignAddress;
    }

    function initCSR() public onlyOwner returns (uint) {
         uint256 _csrID = turnstile.register(msg.sender);
         csrID = _csrID;
         return csrID;
    }
}