pragma solidity ^0.8.15;


import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";


interface NOTEInterface {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}


interface Turnstile {
    function assign(uint256) external returns(uint256);
}

contract AlystCampaign is AccessControl ,ERC721URIStorage {

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    string public campaignName;
    string private campaignNFTURI;
    uint public campaignTargetAmount;
    uint public campaignFundedAmount;
    uint public campaignPeriod;
    uint public campaignTimeOpen;
    address public campaignCreator;

    address[] public pledgers;

    address public NOTEAddress = 0x07865c6E87B9F70255377e024ace6630C1Eaa37F;
    NOTEInterface NOTE = NOTEInterface(NOTEAddress);

    // address alystTreasury = 0xE7f6F39B0A2b5Adf22A4ebc8105AF443086547c9;
    Turnstile turnstile = Turnstile(0xEcf044C5B4b867CFda001101c617eCd347095B44);


    mapping(address => uint) public userToPledgeAmount;
    mapping(address => bool) public userHasPledged;
    mapping(address => bool) public userPledgeNOTE;



    constructor(string memory _campaignName, 
                string memory _campaignSymbol, 
                string memory _campaignURI,
                uint _campaignTargetAmount, 
                uint _campaignPeriod,
                uint256 _csrID
                ) ERC721(_campaignName, _campaignSymbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, campaignCreator);
        campaignNFTURI = _campaignURI;
        campaignName = _campaignName;
        campaignTargetAmount = _campaignTargetAmount;
        campaignPeriod = _campaignPeriod;
        campaignTimeOpen = block.timestamp;
        turnstile.assign(_csrID);
    }

    modifier onlyAdmin() {
    require(isAdmin(msg.sender), "Restricted to admins.");
    _;
  }

    function pledgeToCampaign(uint _amount) public payable {
        require(msg.value > 0 || _amount > 0);
        NOTE.transferFrom(msg.sender, address(this), _amount);

        if (!userHasPledged[msg.sender]) {
             pledgers.push(msg.sender);
        }
        userHasPledged[msg.sender] = true;
        //check if user pledge $CANTO
        if (msg.value > 0) {
            userToPledgeAmount[msg.sender] = msg.value;
            userPledgeNOTE[msg.sender] = false;
            campaignFundedAmount = campaignFundedAmount + msg.value;
        } else if (_amount > 0 && msg.value == 0) {  //check if user pledge $NOTE
            userToPledgeAmount[msg.sender] = _amount;
            userPledgeNOTE[msg.sender] = true;
            campaignFundedAmount = campaignFundedAmount + _amount;
        }

    }

    function mintProofOfPledge() public returns (uint) {
        require(block.timestamp > campaignTimeOpen + campaignPeriod);
        require(campaignFundedAmount == campaignTargetAmount || campaignFundedAmount > campaignTargetAmount);
        require(userHasPledged[msg.sender] == true);

        _tokenIds.increment();

         uint256 newItemId = _tokenIds.current();
        _mint(msg.sender, newItemId);
        _setTokenURI(newItemId, campaignNFTURI);

        return newItemId;

    }

    function refund() public {
        require(block.timestamp > campaignTimeOpen + campaignPeriod);
        require(campaignTargetAmount != campaignFundedAmount);
        require(userToPledgeAmount[msg.sender] > 0);
        
        // check amount invested 
        uint refundAmount = userToPledgeAmount[msg.sender];
        userToPledgeAmount[msg.sender] = 0;

        if(userPledgeNOTE[msg.sender] == true) {
             NOTE.transferFrom(address(this), msg.sender, refundAmount);
        } else {
             payable(msg.sender).transfer(refundAmount);
        }
        
    }

    function withdraw(address _campaignTreasury) public onlyAdmin {
       require(block.timestamp > campaignTimeOpen + campaignPeriod);
       require(campaignFundedAmount == campaignTargetAmount || campaignFundedAmount > campaignTargetAmount);

       // uint alystServiceCharge = address(this).balance * 3 / 200  ;
       // uint projectFund = address(this).balance - alystServiceCharge;

       uint noteContractBalance = NOTE.balanceOf(address(this));

       NOTE.transferFrom(address(this), _campaignTreasury, noteContractBalance);
       payable(_campaignTreasury).transfer(address(this).balance);
       //payable(alystTreasury).transfer(alystServiceCharge);

        // NOTE.transferFrom(address(this), _campaignTreasury, projectFund);
        // NOTE.transferFrom(address(this), alystTreasury, alystServiceCharge);

    }

    function setCampaignNFTURI(string memory _nftURI) public onlyAdmin {
        campaignNFTURI = _nftURI;

    }

    function isAdmin(address account) public virtual view returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, account);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, AccessControl) returns (bool) {
        return(
        ERC721.supportsInterface(interfaceId) || 
        AccessControl.supportsInterface(interfaceId) 
        );
    }

    

  


}
