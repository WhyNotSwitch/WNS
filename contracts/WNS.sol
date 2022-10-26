// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./iWNS.sol";
import "./WNS1155.sol";

error NoRevenue();
uint8 constant currency = 0;

contract WNS is WhyNotSwitch, iWNS {
    // map id -> metadata
    mapping(uint256 => Meta) private _meta;
    struct Meta {
        uint256 fee;
        uint256 revenue;
        address developer;
    }

    modifier notCurrency(uint256 id) {
        require(id != currency, "Can't be the zero token");
        _;
    }

    modifier requiresMonopoly(uint256 id) {
        require(
            balanceOf(msg.sender, id) == totalSupply(id),
            "Don't yet own all tokens"
        );
        _;
    }

    modifier requiresDeveloper(uint256 id) {
        require(_meta[id].developer == msg.sender, "Not yours to do");
        _;
    }

    function setDeveloper(address to, uint256 id)
        external
        onlyRole(MINTER_ROLE)
    {
        require(id != 0, "ERC1155: invalid token ID");
        require(to != address(0), "Can't be set to the zero address");
        _meta[id].developer = to;
    }

    function developerOf(uint256 id) external view returns (address) {
        address developer = _meta[id].developer;
        return developer;
    }

    function pay(uint256 id, uint256 amount) external {
        require(
            balanceOf(msg.sender, currency) >= amount,
            "ERC1155: insufficient balance for transfer"
        );
        unchecked {
            uint256 fee = (amount * 15) / 100;
            _burn(msg.sender, currency, amount);
            _meta[id].fee += fee;
            _meta[id].revenue += amount - fee;
        }

        emit Claim(msg.sender, amount, id, block.timestamp);
    }

    function feeOf(uint256 id) external view notCurrency(id) returns (uint256) {
        return _meta[id].fee;
    }

    function revenueOf(uint256 id)
        external
        view
        notCurrency(id)
        returns (uint256)
    {
        return _meta[id].revenue;
    }

    function claimFee(uint256 id)
        external
        requiresDeveloper(id)
        notCurrency(id)
    {
        uint256 fee = _meta[id].fee;
        _claimTokens(id, fee);
    }

    function claimRevenue(uint256 id)
        external
        requiresMonopoly(id)
        notCurrency(id)
    {
        uint256 revenue = _meta[id].revenue;
        _claimTokens(id, revenue);
    }

    function _claimTokens(uint256 id, uint256 revenue) private {
        if (revenue <= 0) {
            revert NoRevenue();
        }
        _meta[id].revenue = 0;
        _mint(msg.sender, currency, revenue, bytes(""));

        emit Claim(msg.sender, revenue, id, block.timestamp);
    }

}
