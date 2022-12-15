pragma solidity ^0.8.15;


// interface NOTEInterface {
//     function balanceOf(address account) external view returns (uint256);
//     function transfer(address to, uint256 amount) external returns (bool);
//     function allowance(address owner, address spender) external view returns (uint256);
//     function approve(address spender, uint256 amount) external returns (bool);
//     function transferFrom(address from, address to, uint256 amount) external returns (bool);
// }



contract AlystCampaign {

    string public campaignName;
    uint public campaignTargetAmount;
    uint public campaignFundedAmount;
    uint public campaignPeriod;
    uint public campaignTimeOpen;
    address public campaignCreator;

    bool public campaignStatus;

    address[] public pledgers;

    // address public NOTEAddress = 0x07865c6E87B9F70255377e024ace6630C1Eaa37F;
    // NOTEInterface NOTE = NOTEInterface(NOTEAddress);

    address alystTreasury = 0xE7f6F39B0A2b5Adf22A4ebc8105AF443086547c9;


    mapping(address => uint) public userToPledgeAmount;
    mapping(address => bool) public userHasPledged;



    constructor(string memory _campaignName, uint _campaignTargetAmount, uint _campaignPeriod) {
        campaignName = _campaignName;
        campaignTargetAmount = _campaignTargetAmount;
        campaignPeriod = _campaignPeriod;
        campaignCreator = msg.sender;
        campaignTimeOpen = block.timestamp;
        campaignStatus = true;
    }

    function pledgeToCampaign(uint _amount) public payable {
        require(msg.value > 0, "amount cannot be zero");
        // NOTE.allowance(msg.sender, address(this));

        // NOTE.transferFrom(msg.sender, address(this), _amount);

        if (!userHasPledged[msg.sender]) {
             pledgers.push(msg.sender);
        }
        userHasPledged[msg.sender] = true;
        userToPledgeAmount[msg.sender] = msg.value;
        campaignFundedAmount = campaignFundedAmount + msg.value;


    }

    function refund() public {
        require(block.timestamp > campaignTimeOpen + campaignPeriod);
        require(campaignTargetAmount !== campaignFundedAmount);
        
        // check amount invested 
        uint refundAmount = userToPledgeAmount[msg.sender];
        payable(msg.sender).transfer(refundAmount);
        // NOTE.transferFrom(address(this), msg.sender, refundAmount);

    }

    function withdraw(address _campaignTreasury) public {
       require(block.timestamp > campaignTimeOpen + campaignPeriod);
       require(campaignCreator == msg.sender);
       require(campaignFundedAmount == campaignTargetAmount || campaignFundedAmount > campaignTargetAmount);

       // uint alystServiceCharge = address(this).balance * 3 / 200  ;
       // uint projectFund = address(this).balance - alystServiceCharge;

       payable(_campaignTreasury).transfer(projectFund);
       payable(alystTreasury).transfer(alystServiceCharge);

        // NOTE.transferFrom(address(this), _campaignTreasury, projectFund);
        // NOTE.transferFrom(address(this), alystTreasury, alystServiceCharge);

    }

    function allowCampaignRefund() public {
        require(campaignCreator == msg.sender);

        campaignStatus = false;
    }
 


}
