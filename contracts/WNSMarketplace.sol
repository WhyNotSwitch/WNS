// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./iWNSMarketplace.sol";

contract Marketplace is
    iMarketplace,
    ERC1155Holder,
    AccessControl,
    ReentrancyGuard
{
    bytes32 private constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    uint256 public listingFee = 1 ether;
    address public _nftAddress;
    IERC1155 private nftContract;
    using Counters for Counters.Counter;
    Counters.Counter private _orderIds;

    mapping(uint256 => MarketOrder) public orderBook;
    mapping(address => uint256) private proceeds;

    modifier isSeller(uint256 orderId) {
        require(msg.sender == orderBook[orderId].seller, "Not your order");
        _;
    }

    modifier canSell(
        uint256 tokenId,
        uint256 amount,
        uint256 price
    ) {
        // run checks for tokenId, price validity, approval, and token balance

        require(tokenId > 0, "Invalid tokenId");
        require(amount > 0, "Amount must be greater than zero");
        require(price > 0, "Price must be greater than zero");

        bool approval = nftContract.isApprovedForAll(msg.sender, address(this));
        uint256 nftBalance = nftContract.balanceOf(msg.sender, tokenId);

        require(approval == true, "Missing marketplace approval");
        require(amount <= nftBalance, "Insuficent NFT balance");
        _;
    }

    constructor(address nftAddress) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MANAGER_ROLE, msg.sender);

        setNftContract(nftAddress);
    }

    function openOrder(
        uint256 tokenId,
        uint256 amount,
        uint256 price
    ) external canSell(tokenId, amount, price) nonReentrant {
        _orderIds.increment();
        orderBook[_orderIds.current()] = MarketOrder(
            tokenId,
            amount,
            price,
            payable(msg.sender)
        );
        emit ItemListed(msg.sender, tokenId, price, amount);
        // nftContract.safeTransferFrom(msg.sender, address(this), tokenId, amount, "");
    }

    function updateOrder(
        uint256 orderId,
        uint256 tokenId,
        uint256 amount,
        uint256 price
    ) external isSeller(orderId) canSell(tokenId, amount, price) nonReentrant {
        orderBook[orderId] = MarketOrder(
            tokenId,
            amount,
            price,
            payable(msg.sender)
        );
        emit ItemListed(msg.sender, tokenId, price, amount);
    }

    function cancelOrder(uint256 orderId) external isSeller(orderId) {
        emit ItemDelisted(
            msg.sender,
            orderBook[orderId].tokenId,
            orderBook[orderId].amount
        );
        delete (orderBook[orderId]);
    }

    function fillOrder(uint256 orderId, uint256 amount) external {
        MarketOrder memory order = orderBook[orderId];
        uint256 coinBalance = nftContract.balanceOf(msg.sender, 0);

        require(order.price > 0, "Invalid listing");
        require(coinBalance >= order.price, "Insuficient coin balance");
        require(amount <= order.amount, "Can't purchase more than is listed");

        orderBook[orderId].amount -= amount;
        proceeds[order.seller] += order.price - listingFee;
        proceeds[address(this)] += listingFee;

        nftContract.safeTransferFrom(
            msg.sender,
            address(this),
            0,
            order.price,
            ""
        );

        onERC1155Received(address(this), msg.sender, order.tokenId, amount, "");
        nftContract.safeTransferFrom(
            order.seller,
            msg.sender,
            order.tokenId,
            amount,
            ""
        );
    }

    function withdrawProceeds() external {
        _withdrawProceeds(msg.sender);
    }

    function adminWithdrawal() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _withdrawProceeds(address(this));
    }

    function getOrder(uint256 orderId)
        external
        view
        returns (MarketOrder memory)
    {
        require(orderBook[orderId].price > 0, "Invalid listing");
        return orderBook[orderId];
    }

    function getProceeds() external view returns (uint256) {
        return proceeds[msg.sender];
    }

    function setNftContract(address nftAddress) public onlyRole(MANAGER_ROLE) {
        require(nftAddress != address(0), "Can't be set to the zero address");
        _nftAddress = nftAddress;
        nftContract = IERC1155(_nftAddress);
    }

    function setListingFee(uint fee) public onlyRole(MANAGER_ROLE) {
        listingFee = fee;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155Receiver, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _withdrawProceeds(address account) private {
        uint256 coins = proceeds[account];
        require(coins > 0, "No proceeds available");
        proceeds[account] = 0;
        nftContract.safeTransferFrom(address(this), msg.sender, 0, coins, "");
    }
}
