// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./WNS721.sol";


error NoProceeds();


contract Solarize is WNS721 {

    mapping(uint256 => address) private managers;
    mapping(address => uint256) private s_proceeds;


    event Income(
        address from, 
        address indexed to, 
        uint256 indexed amount, 
        uint256 indexed tokenId,
        uint256 timestamp
        );


    constructor() WNS721("Why-Not-Switch", "WNS") {}


    function _baseURI() internal pure override returns (string memory) {
        return "https://721.whynotswitch.com/solar/";
    }


    function _setManager(address to, uint256 tokenId) internal {
        require(to != address(0), "ERC721: mint to the zero address");
        managers[tokenId] = to;
    }


    function creditAccount(uint256 tokenId) external payable{
        address manager = managerOf(tokenId);
        address owner = ownerOf(tokenId);

        s_proceeds[owner] += msg.value * 8/10;
        s_proceeds[manager] += msg.value * 2/10;

        emit Income({
            from: msg.sender, 
            to: owner, 
            amount:msg.value, 
            tokenId: tokenId,
            timestamp: block.timestamp
            });
    }


    function withdrawProceeds() external {
        uint256 proceeds = s_proceeds[msg.sender];
        if (proceeds <= 0) {
            revert NoProceeds();
        }
        s_proceeds[msg.sender] = 0;
        (bool success, ) = payable(msg.sender).call{value: proceeds}("");
        require(success, "Transfer failed");
    }


    function getProceeds(address caller) external view returns (uint256) {
        return s_proceeds[caller];
    }


    function safeMint(address to, uint256 tokenId, string memory uri)
        public override(WNS721) onlyRole(MINTER_ROLE)
    {
        super.safeMint(to, tokenId, uri);
        _setManager(to, tokenId);
    }


    function managerOf(uint256 tokenId) public view returns(address) {
        address manager = managers[tokenId];
        require(manager != address(0), "ERC721: invalid token ID");
        return manager;
    }

}