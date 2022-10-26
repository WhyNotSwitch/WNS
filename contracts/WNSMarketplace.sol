// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/utils/ERC1155HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "./iWNSMarketplace.sol";

contract MarketLite is
    iMarketplace,
    Initializable,
    PausableUpgradeable,
    AccessControlUpgradeable,
    UUPSUpgradeable,
    ERC1155HolderUpgradeable,
    ReentrancyGuardUpgradeable
{
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    mapping(address => uint256) private proceeds;
    mapping(uint256 => mapping(address => MarketOrder)) orderBook;

    uint256 public listingFee;
    address public _nftAddress;
    IERC1155 private nftContract;

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

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address nftAddress) public initializer {
        __Pausable_init();
        __AccessControl_init();
        __UUPSUpgradeable_init();
        __ERC1155Holder_init();
        __ReentrancyGuard_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(MANAGER_ROLE, msg.sender);
        _grantRole(UPGRADER_ROLE, msg.sender);

        setNftContract(nftAddress);
        listingFee = 1;
    }

    function updateListing(
        uint256 tokenId,
        uint256 amount,
        uint256 price
    ) external canSell(tokenId, amount, price) nonReentrant {
        orderBook[tokenId][msg.sender] = MarketOrder(amount, price);
        emit ItemListed(msg.sender, tokenId, price, amount);
    }

    function cancelListing(uint256 tokenId) external {
        emit ItemDelisted(msg.sender, tokenId);
        delete (orderBook[tokenId][msg.sender]);
    }

    function buyFromListing(
        uint256 tokenId,
        address seller,
        uint256 amount
    ) external {
        MarketOrder memory order = orderBook[tokenId][seller];
        require(order.price > 0, "Invalid listing");
        require(order.amount > 0, "Invalid listing");
        require(amount > 0, "Can't purchase Nothing");
        require(amount <= order.amount, "Can't purchase more than is listed");

        uint256 cost = order.price * amount;
        uint256 fee = order.price * amount;
        uint256 coinBalance = nftContract.balanceOf(msg.sender, 0);
        require(coinBalance >= cost, "Insuficient coin balance");

        orderBook[tokenId][seller].amount -= amount;
        proceeds[seller] += cost - fee;
        proceeds[address(this)] += fee;

        nftContract.safeTransferFrom(msg.sender, address(this), 0, fee, "");

        onERC1155Received(address(this), msg.sender, tokenId, amount, "");
        nftContract.safeTransferFrom(seller, msg.sender, tokenId, amount, "");

        emit ItemBought(msg.sender, tokenId, order.price, amount);
    }

    function withdrawProceeds() external {
        _withdrawProceeds(msg.sender);
    }

    function adminWithdrawal() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _withdrawProceeds(address(this));
    }

    function getProceeds() external view returns (uint256) {
        return proceeds[msg.sender];
    }

    function getListing(uint256 tokenId, address seller)
        external
        view
        returns (MarketOrder memory)
    {
        MarketOrder memory order = orderBook[tokenId][seller];

        require(order.price > 0, "Invalid listing");
        require(order.amount > 0, "Invalid listing");
        return order;
    }

    function setListingFee(uint fee) external onlyRole(MANAGER_ROLE) {
        listingFee = fee;
    }

    function setNftContract(address nftAddress) public onlyRole(MANAGER_ROLE) {
        require(nftAddress != address(0), "Can't be set to the zero address");
        _nftAddress = nftAddress;
        nftContract = IERC1155(_nftAddress);
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155ReceiverUpgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _afterBuy(uint256 tokenId, address seller) internal {
        if (orderBook[tokenId][seller].amount == 0) {
            delete (orderBook[tokenId][seller]);
        }
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyRole(UPGRADER_ROLE)
    {}

    function _withdrawProceeds(address account) private {
        uint256 coins = proceeds[account];
        require(coins > 0, "No proceeds available");
        proceeds[account] = 0;
        nftContract.safeTransferFrom(address(this), msg.sender, 0, coins, "");
    }
}
