// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;


import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";



interface Turnstile {
    function assign(uint256) external returns(uint256);
}

contract AlystCampaign is AccessControl ,ERC721URIStorage, ReentrancyGuard {

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    IERC20 public NOTE;

    string public campaignName;
    string private campaignNFTURI;
    uint public campaignTargetAmount;
    uint public campaignFundedAmount;
    uint public campaignPeriod;
    uint public campaignTimeOpen;
    address public campaignCreator;

    address[] public pledgers;

    address public NOTEAddress = 0x07865c6E87B9F70255377e024ace6630C1Eaa37F;

    Turnstile turnstile = Turnstile(0xEcf044C5B4b867CFda001101c617eCd347095B44);


    mapping(address => uint) public userToPledgeAmount;
    mapping(address => uint) public userHasPledged; // 0 - False / 1 - True

    event Pledge(address indexed _from, uint amount);
    event MintPOP(address indexed _from, uint nftID);
    event Refund(address indexed _from, uint amount);

    error RestrictedToAdmin();

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
        NOTE = IERC20(NOTEAddress);
        turnstile.assign(_csrID);
    }

    modifier onlyAdmin() {
      if(!isAdmin(msg.sender)) 
         revert RestrictedToAdmin();
      
      _;
  }

    function pledgeToCampaign(uint _amount) public nonReentrant {
        require(_amount > 0);
        NOTE.transferFrom(msg.sender, address(this), _amount);

        if (userHasPledged[msg.sender] == 0) {
             pledgers.push(msg.sender);
        }
        userHasPledged[msg.sender] = 1;

        userToPledgeAmount[msg.sender] = _amount;
        campaignFundedAmount = campaignFundedAmount + _amount;

        emit Pledge(msg.sender, _amount);

    }

    function mintProofOfPledge() public nonReentrant returns (uint) {
        require(block.timestamp > campaignTimeOpen + campaignPeriod);
        require(campaignFundedAmount == campaignTargetAmount || campaignFundedAmount > campaignTargetAmount);
        require(userHasPledged[msg.sender] == 1);

        _tokenIds.increment();

         uint256 newItemId = _tokenIds.current();
        _mint(msg.sender, newItemId);
        _setTokenURI(newItemId, campaignNFTURI);

        emit MintPOP(msg.sender, newItemId);

        return newItemId;

    }

    
    function refund() public nonReentrant {   
        require(block.timestamp > campaignTimeOpen + campaignPeriod);
        require(campaignTargetAmount != campaignFundedAmount);
        require(userToPledgeAmount[msg.sender] > 0);
        
        // check amount invested 
        uint refundAmount = userToPledgeAmount[msg.sender];
        userToPledgeAmount[msg.sender] = 0;
        NOTE.transferFrom(address(this), msg.sender, refundAmount);

        emit Refund(msg.sender, refundAmount);

        
    }

    function withdraw(address _campaignTreasury) public onlyAdmin {
       require(block.timestamp > campaignTimeOpen + campaignPeriod);
       require(campaignFundedAmount == campaignTargetAmount || campaignFundedAmount > campaignTargetAmount);

       // uint alystServiceCharge = address(this).balance * 3 / 200  ;
       // uint projectFund = address(this).balance - alystServiceCharge;

       uint noteContractBalance = NOTE.balanceOf(address(this));

       NOTE.transfer(_campaignTreasury, noteContractBalance);

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
