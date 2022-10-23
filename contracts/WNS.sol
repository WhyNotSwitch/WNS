// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./iWNS.sol";
import "./WNS1155.sol";

error NoRevenue();

// token 0 -> native currency
uint8 constant currency = 0;
uint8 constant devIndex = 0;
uint8 constant ownIndex = 1;


contract WNS is WhyNotSwitch, iWNS {
    // map TokenId -> Address (remember your dev)
    mapping(uint256 => address) private developers;

    // map TokenId -> [$Developer, $Owner]
    mapping(uint256 => uint256[2]) private revenues;

    modifier notCurrency(uint256 tokenId) {
        require(tokenId != currency, "Can't be the zero token");
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

    function _claimTokens(uint256 tokenId, uint256 index) internal {
        uint256 _revenue = revenues[tokenId][index];
        if (_revenue <= 0) {
            revert NoRevenue();
        }
        revenues[tokenId][index] = 0;
        _mint(msg.sender, currency, _revenue, bytes(""));

        emit Claim({
            to: msg.sender,
            amount: _revenue,
            tokenId: tokenId,
            timestamp: block.timestamp
        });
    }

    function claimFee(uint256 tokenId)
        external
        requiresDeveloper(tokenId)
        notCurrency(tokenId)
    {
        _claimTokens(tokenId, devIndex);
    }

    function claimRevenue(uint256 tokenId)
        external
        requiresMonopoly(tokenId)
        notCurrency(tokenId)
    {
        _claimTokens(tokenId, ownIndex);
    }

    function pay(uint256 tokenId, uint256 amount) external {
        require(
            balanceOf(msg.sender, currency) >= amount,
            "ERC1155: insufficient balance for transfer"
        );
        unchecked {
            _burn(msg.sender, currency, amount);
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

    function developerOf(uint256 tokenId) external view returns (address) {
        address developer = developers[tokenId];
        require(developer != address(0), "ERC721: invalid token ID");
        return developer;
    }

    function feeOf(uint256 tokenId)
        external
        view
        notCurrency(tokenId)
        returns (uint256)
    {
        return revenues[tokenId][devIndex];
    }

    function revenueOf(uint256 tokenId)
        external
        view
        notCurrency(tokenId)
        returns (uint256)
    {
        return revenues[tokenId][ownIndex];
    }
}
