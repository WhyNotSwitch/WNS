// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./WNS1155.sol";

error NoRevenue();
uint8 constant coinId = 0;
uint8 constant devIndex = 0;
uint8 constant ownIndex = 1;

contract WNS is WhyNotSwitch {
    // map TokenId -> Address (remember your dev)
    mapping(uint256 => address) private developers;

    // map TokenId -> [$Developer, $Owner]
    mapping(uint256 => uint256[2]) private revenues;

    event Revenue(
        address from,
        uint256 indexed amount,
        uint256 indexed tokenId,
        uint256 indexed timestamp
    );

    event Claim(
        address to,
        uint256 indexed amount,
        uint256 indexed tokenId,
        uint256 indexed timestamp
    );

    modifier notCoin(uint256 tokenId) {
        require(tokenId != coinId, "Can't be the zero token");
        _;
    }

    modifier requiresMonopoly(uint256 tokenId) {
        require(
            balanceOf(msg.sender, tokenId) == totalSupply(tokenId),
            "Don't yet own all tokens"
        );
        _;
    }

    modifier requiresDeveloper(uint256 tokenId) {
        require(developers[tokenId] == msg.sender, "Not yours to do");
        _;
    }

    function _setDeveloper(address to, uint256 tokenId) internal {
        require(to != address(0), "Can't be set to the zero address");
        developers[tokenId] = to;
    }

    function pay(uint256 tokenId, uint256 amount) external {
        require(
            balanceOf(msg.sender, coinId) >= amount,
            "ERC1155: insufficient balance for transfer"
        );
        unchecked {
            _burn(msg.sender, coinId, amount);
            revenues[tokenId][devIndex] += (amount * 15) / 100;
            revenues[tokenId][ownIndex] += (amount * 85) / 100;
        }

        emit Revenue({
            from: msg.sender,
            amount: amount,
            tokenId: tokenId,
            timestamp: block.timestamp
        });
    }

    function _claimTokens(uint256 tokenId, uint256 index) internal {
        uint256 _revenue = revenues[tokenId][index];
        if (_revenue <= 0) {
            revert NoRevenue();
        }
        revenues[tokenId][index] = 0;
        _mint(msg.sender, coinId, _revenue, bytes(""));
    }

    function claimFees(uint256 tokenId)
        external
        requiresDeveloper(tokenId)
        notCoin(tokenId)
    {
        _claimTokens(tokenId, devIndex);
    }

    function claimRevenue(uint256 tokenId)
        external
        requiresMonopoly(tokenId)
        notCoin(tokenId)
    {
        _claimTokens(tokenId, ownIndex);

        emit Claim({
            to: msg.sender,
            amount: amount,
            tokenId: tokenId,
            timestamp: block.timestamp
        });
    }

    function checkFees(uint256 tokenId)
        external
        view
        notCoin(tokenId)
        returns (uint256)
    {
        return revenues[tokenId][devIndex];
    }

    function checkRevenue(uint256 tokenId)
        external
        view
        notCoin(tokenId)
        returns (uint256)
    {
        return revenues[tokenId][ownIndex];
    }

    function developerOf(uint256 tokenId) public view returns (address) {
        address developer = developers[tokenId];
        require(developer != address(0), "ERC721: invalid token ID");
        return developer;
    }
}
